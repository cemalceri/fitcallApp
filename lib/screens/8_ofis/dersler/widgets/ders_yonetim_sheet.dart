// lib/screens/8_ofis/dersler/widgets/ders_yonetim_sheet.dart
//
// Bir dersin işlemleri (web Ders Yönetimi'ndeki satırın mobil karşılığı):
//   • geçmiş derste yönetici onayı (Yapıldı / Yapılmadı / kararı kaldır),
//     antrenör ve yardımcı hakedişi, katılımcının paket düşümü;
//   • gelecek derste katılımcı adına "katılacak" ve katılım hatırlatması;
//   • karar bekleyen plan dışı / misafir kişiler için kısa yol.
// Kurallar sunucuda (ders_yonetimi_service); burada yalnız çağrı ve görünüm.
// Görünüm [DersYonetimGovdesi]'nde, veriyle beslenir (taşma testi).

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/takvim/iptal_taramasi.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Sayfayı açar. Her işlemden sonra arkadaki liste zaten tazelenir.
Future<void> dersYonetimSayfasiAc(
  BuildContext context, {
  required YonetimDersi ders,
  required List<YapilmadiNedeni> nedenler,
  required Future<YonetimDersi?> Function() yenile,
  required VoidCallback onPlanDisi,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Sayfanın kendi Scaffold'u köşeleri doldurmasın.
    clipBehavior: Clip.antiAlias,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, kaydirma) => DersYonetimSheet(
        ders: ders,
        nedenler: nedenler,
        yenile: yenile,
        onPlanDisi: onPlanDisi,
        kaydirma: kaydirma,
      ),
    ),
  );
}

class DersYonetimSheet extends StatefulWidget {
  final YonetimDersi ders;
  final List<YapilmadiNedeni> nedenler;
  final Future<YonetimDersi?> Function() yenile;
  final VoidCallback onPlanDisi;
  final ScrollController? kaydirma;

  const DersYonetimSheet({
    super.key,
    required this.ders,
    required this.nedenler,
    required this.yenile,
    required this.onPlanDisi,
    this.kaydirma,
  });

  @override
  State<DersYonetimSheet> createState() => _DersYonetimSheetState();
}

class _DersYonetimSheetState extends State<DersYonetimSheet> {
  late YonetimDersi _ders = widget.ders;
  bool _mesgul = false;

  /// Sayfanın kendi mesaj alanı: alttaki sayfanın Scaffold'una düşen
  /// SnackBar bu sayfanın altında kalıyor, sunucu hatası görünmüyordu.
  final _mesajlar = GlobalKey<ScaffoldMessengerState>();

  void _mesaj(String metin, ScaffoldMessengerState kok) {
    // Sayfa kapandıysa mesaj alttaki sayfada gösterilir.
    final hedef = mounted ? _mesajlar.currentState : null;
    (hedef ?? kok).showSnackBar(SnackBar(content: Text(metin)));
  }

  /// İşlemi yürütür, sunucu mesajını gösterir, dersi tazeler.
  Future<void> _islem(Future<String> Function() cagri) async {
    if (_mesgul) return;
    HapticFeedback.lightImpact();
    setState(() => _mesgul = true);
    // Bu context yerel ScaffoldMessenger'ın üstünde: kök mesaj alanı.
    final kok = ScaffoldMessenger.of(context);
    try {
      final mesaj = await cagri();
      final yeni = await widget.yenile();
      if (mounted && yeni != null) setState(() => _ders = yeni);
      _mesaj(
        yeni == null
            ? '$mesaj Liste tazelenemedi; sayfayı kapatıp yeniden açın.'
            : mesaj,
        kok,
      );
    } on ApiException catch (e) {
      _mesaj(e.message, kok);
    } finally {
      if (mounted) setState(() => _mesgul = false);
    }
  }

  Future<void> _yapilmadi() async {
    final neden = await yapilmadiNedeniSor(context, widget.nedenler);
    if (neden == null) return;
    await _islem(() => OfisDersYonetimiService.onayVer(
        _ders.id, DersKarari.yapilmadi,
        neden: neden));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _mesajlar,
      child: Scaffold(
        backgroundColor: context.cs.surface,
        body: DersYonetimGovdesi(
          ders: _ders,
          mesgul: _mesgul,
          kaydirma: widget.kaydirma,
          onYapildi: () => _islem(() =>
              OfisDersYonetimiService.onayVer(_ders.id, DersKarari.yapildi)),
          onYapilmadi: _yapilmadi,
          onKarariKaldir: () => _islem(() =>
              OfisDersYonetimiService.onayVer(_ders.id, DersKarari.temizle)),
          onHakedis: (yardimci, deger) => _islem(() =>
              OfisDersYonetimiService.hakedis(_ders.id, deger,
                  yardimci: yardimci)),
          onKatilacak: (k) => _islem(
              () => OfisDersYonetimiService.manuelTeyit(_ders.id, k.uyeId)),
          onHatirlat: (k) => _islem(
              () => OfisDersYonetimiService.teyitHatirlat(_ders.id, k.uyeId)),
          // İstenen durum gönderilir: arka arkaya dokunuş ya da web'de aynı
          // anda yapılan değişiklik düşümü ters çeviremez.
          onPaketDusum: (k) => _islem(() => OfisDersYonetimiService.paketDusum(
              _ders.id, k.uyeId,
              dus: k.paketDusumu == PaketDusumu.dus)),
          onPlanDisi: () {
            Navigator.pop(context);
            widget.onPlanDisi();
          },
        ),
      ),
    );
  }
}

/// "Yapılmadı" nedeni: hızlı seçenekler + isteğe bağlı not. Vazgeçilirse
/// null; neden seçilmezse boş metin (web'de de neden zorunlu değil).
Future<String?> yapilmadiNedeniSor(
    BuildContext context, List<YapilmadiNedeni> nedenler) {
  return showDialog<String>(
    context: context,
    builder: (c) => _YapilmadiDiyalogu(nedenler: nedenler),
  );
}

class _YapilmadiDiyalogu extends StatefulWidget {
  final List<YapilmadiNedeni> nedenler;
  const _YapilmadiDiyalogu({required this.nedenler});

  @override
  State<_YapilmadiDiyalogu> createState() => _YapilmadiDiyaloguState();
}

class _YapilmadiDiyaloguState extends State<_YapilmadiDiyalogu> {
  String? _kod;
  final _not = TextEditingController();

  @override
  void dispose() {
    _not.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ders yapılmadı'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu dersteki plan dışı / misafir kararları da geri alınır.',
              style: context.metin.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Neden (isteğe bağlı)', style: context.metin.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in widget.nedenler)
                  ChoiceChip(
                    label: Text(n.etiket),
                    selected: _kod == n.kod,
                    onSelected: (s) => setState(() => _kod = s ? n.kod : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _not,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Not (ör. öğrenci haber vermeden gelmedi)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          // Not yazıldıysa o gider (web'deki serbest metin); yoksa seçilen
          // kodun etiketi sunucuda çözülür.
          onPressed: () => Navigator.pop(context,
              _not.text.trim().isNotEmpty ? _not.text.trim() : (_kod ?? '')),
          child: const Text('Yapılmadı'),
        ),
      ],
    );
  }
}

/* ============================== Görünüm ============================== */

class DersYonetimGovdesi extends StatelessWidget {
  final YonetimDersi ders;
  final bool mesgul;
  final ScrollController? kaydirma;
  final VoidCallback onYapildi;
  final VoidCallback onYapilmadi;
  final VoidCallback onKarariKaldir;

  /// (yardımcı mı, yeni değer)
  final void Function(bool yardimci, bool? deger) onHakedis;
  final ValueChanged<YonetimKatilimci> onKatilacak;
  final ValueChanged<YonetimKatilimci> onHatirlat;
  final ValueChanged<YonetimKatilimci> onPaketDusum;
  final VoidCallback onPlanDisi;

  const DersYonetimGovdesi({
    super.key,
    required this.ders,
    required this.mesgul,
    this.kaydirma,
    required this.onYapildi,
    required this.onYapilmadi,
    required this.onKarariKaldir,
    required this.onHakedis,
    required this.onKatilacak,
    required this.onHatirlat,
    required this.onPaketDusum,
    required this.onPlanDisi,
  });

  static final _saat = DateFormat('HH:mm');
  static final _gun = DateFormat('d MMMM EEEE', 'tr_TR');

  /// Onay ve hakediş ancak ders bitince verilir (sunucu da reddeder).
  bool get _bitti => !ders.bitis.isAfter(simdiKulup());

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final egitmen = [
      if (ders.antrenor != null) ders.antrenor!,
      if (ders.yardimciAntrenor != null) '${ders.yardimciAntrenor} (yardımcı)',
    ].join(', ');

    return ListView(
      controller: kaydirma,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          '${_saat.format(ders.baslangic)}–${_saat.format(ders.bitis)} · ${ders.kortAdi}',
          style: context.metin.titleLarge,
        ),
        const SizedBox(height: 2),
        Text(
          [
            _gun.format(ders.baslangic),
            if (egitmen.isNotEmpty) egitmen,
            if (ders.urunAdi != null) ders.urunAdi!,
          ].join(' · '),
          style: context.metin.bodySmall,
        ),
        if (mesgul) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
        const SizedBox(height: 16),
        if (ders.iptalMi)
          _IptalBilgisi(ders: ders)
        else if (ders.gecmisMi && _bitti) ...[
          _Bolum(baslik: 'Ders durumu'),
          _AntrenorBildirimi(ders: ders),
          const SizedBox(height: 10),
          _OnaySecimi(
            karar: ders.yoneticiKarari,
            mesgul: mesgul,
            onYapildi: onYapildi,
            onYapilmadi: onYapilmadi,
          ),
          if (ders.yoneticiKarari == false && ders.yoneticiNeden != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Neden: ${ders.yoneticiNeden}',
                  style: context.metin.bodySmall),
            ),
          if (ders.yoneticiKarari != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: mesgul ? null : onKarariKaldir,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Kararı kaldır'),
              ),
            ),
          const SizedBox(height: 12),
          _Bolum(baslik: 'Hakediş'),
          _HakedisSatiri(
            etiket: ders.antrenor ?? 'Antrenör',
            deger: ders.hakedis,
            mesgul: mesgul,
            onSec: (d) => onHakedis(false, d),
          ),
          if (ders.yardimciAntrenor != null)
            _HakedisSatiri(
              etiket: '${ders.yardimciAntrenor} (yardımcı)',
              deger: ders.yardimciHakedis,
              mesgul: mesgul,
              onSec: (d) => onHakedis(true, d),
            ),
        ],
        if (ders.planDisiBekleyen > 0) ...[
          const SizedBox(height: 12),
          _PlanDisiUyarisi(sayi: ders.planDisiBekleyen, onKararVer: onPlanDisi),
        ],
        const SizedBox(height: 16),
        _Bolum(baslik: 'Katılımcılar · ${ders.katilimcilar.length}'),
        if (ders.katilimcilar.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Bu derste katılımcı yok.',
                style: context.metin.bodySmall),
          )
        else
          for (final (i, k) in ders.katilimcilar.indexed) ...[
            if (i > 0) Divider(height: 1, color: cs.outlineVariant),
            _KatilimciSatiri(
              katilimci: k,
              ders: ders,
              mesgul: mesgul,
              onKatilacak: () => onKatilacak(k),
              onHatirlat: () => onHatirlat(k),
              onPaketDusum: () => onPaketDusum(k),
            ),
          ],
      ],
    );
  }
}

class _Bolum extends StatelessWidget {
  final String baslik;
  const _Bolum({required this.baslik});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(baslik,
            style: context.metin.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _IptalBilgisi extends StatelessWidget {
  final YonetimDersi ders;
  const _IptalBilgisi({required this.ders});

  @override
  Widget build(BuildContext context) {
    final satirlar = [
      if (ders.iptalSebebi != null) 'Neden: ${ders.iptalSebebi}',
      if (ders.iptalAciklamasi != null) ders.iptalAciklamasi!,
      if (ders.iptalEden != null) 'İptal eden: ${ders.iptalEden}',
    ];
    return IptalTaramasi(
      yaricap: BorderRadius.circular(Yaricap.m),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 18, color: context.renkler.hata),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Ders iptal edildi',
                      style: context.metin.titleSmall
                          ?.copyWith(color: context.renkler.hata)),
                ),
              ],
            ),
            for (final s in satirlar)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s, style: context.metin.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _AntrenorBildirimi extends StatelessWidget {
  final YonetimDersi ders;
  const _AntrenorBildirimi({required this.ders});

  @override
  Widget build(BuildContext context) {
    final (metin, ton, ikon) = switch (ders.antrenorKarari) {
      true => ('Antrenör: yapıldı dedi', ListeTonu.basari, Icons.check_circle),
      false => (
          'Antrenör: yapılmadı dedi'
              '${ders.antrenorNeden != null ? ' (${ders.antrenorNeden})' : ''}',
          ListeTonu.hata,
          Icons.cancel
        ),
      null => (
          'Antrenör henüz bildirmedi',
          ListeTonu.notr,
          Icons.hourglass_empty_rounded
        ),
    };
    return Row(
      children: [
        Icon(ikon, size: 18, color: ton.on(context)),
        const SizedBox(width: 6),
        Expanded(child: Text(metin, style: context.metin.bodyMedium)),
      ],
    );
  }
}

/// Yönetici onayı: iki büyük seçim düğmesi. Seçili olan dolu ve onaylı tonda.
class _OnaySecimi extends StatelessWidget {
  final bool? karar;
  final bool mesgul;
  final VoidCallback onYapildi;
  final VoidCallback onYapilmadi;

  const _OnaySecimi({
    required this.karar,
    required this.mesgul,
    required this.onYapildi,
    required this.onYapilmadi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecimDugmesi(
            etiket: 'Yapıldı',
            ikon: Icons.check_rounded,
            secili: karar == true,
            ton: ListeTonu.basari,
            onTap: mesgul || karar == true ? null : onYapildi,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SecimDugmesi(
            etiket: 'Yapılmadı',
            ikon: Icons.close_rounded,
            secili: karar == false,
            ton: ListeTonu.hata,
            onTap: mesgul || karar == false ? null : onYapilmadi,
          ),
        ),
      ],
    );
  }
}

class _SecimDugmesi extends StatelessWidget {
  final String etiket;
  final IconData ikon;
  final bool secili;
  final ListeTonu ton;
  final VoidCallback? onTap;

  const _SecimDugmesi({
    required this.etiket,
    required this.ikon,
    required this.secili,
    required this.ton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renk = secili ? ton.on(context) : cs.onSurface;
    return Semantics(
      button: true,
      selected: secili,
      child: Material(
        color: secili ? ton.zemin(context) : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          side: BorderSide(
            color: secili ? ton.on(context) : cs.outlineVariant,
            width: secili ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Yaricap.m),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ikon, size: 20, color: renk),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    etiket,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.metin.labelLarge?.copyWith(
                      color: renk,
                      fontWeight: secili ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HakedisSatiri extends StatelessWidget {
  final String etiket;
  final bool? deger;
  final bool mesgul;
  final ValueChanged<bool?> onSec;

  const _HakedisSatiri({
    required this.etiket,
    required this.deger,
    required this.mesgul,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(etiket,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.metin.bodyMedium),
          ),
          const SizedBox(width: 8),
          // Seçili olana yeniden dokunmak kararı kaldırır (—).
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Alır')),
              ButtonSegment(value: false, label: Text('Almaz')),
            ],
            selected: {if (deger != null) deger!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged:
                mesgul ? null : (s) => onSec(s.isEmpty ? null : s.first),
          ),
        ],
      ),
    );
  }
}

class _PlanDisiUyarisi extends StatelessWidget {
  final int sayi;
  final VoidCallback onKararVer;
  const _PlanDisiUyarisi({required this.sayi, required this.onKararVer});

  @override
  Widget build(BuildContext context) {
    final r = context.renkler;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: r.uyariZemin,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, size: 18, color: r.uyari),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$sayi plan dışı / misafir kişi için karar bekleniyor.',
              style: context.metin.bodyMedium
                  ?.copyWith(color: context.cs.onSurface),
            ),
          ),
          TextButton(onPressed: onKararVer, child: const Text('Karar ver')),
        ],
      ),
    );
  }
}

class _KatilimciSatiri extends StatelessWidget {
  final YonetimKatilimci katilimci;
  final YonetimDersi ders;
  final bool mesgul;
  final VoidCallback onKatilacak;
  final VoidCallback onHatirlat;
  final VoidCallback onPaketDusum;

  const _KatilimciSatiri({
    required this.katilimci,
    required this.ders,
    required this.mesgul,
    required this.onKatilacak,
    required this.onHatirlat,
    required this.onPaketDusum,
  });

  (String, ListeTonu) _durum() {
    final k = katilimci;
    if (ders.gelecekMi && !k.planDisiMi) {
      return switch (k.teyit) {
        TeyitDurumu.katilacak => ('Katılacak', ListeTonu.basari),
        TeyitDurumu.katilmayacak => (
            'Katılmayacak${k.teyitAciklama != null ? ' · ${k.teyitAciklama}' : ''}',
            ListeTonu.hata
          ),
        TeyitDurumu.bekliyor => ('Cevap bekleniyor', ListeTonu.uyari),
        TeyitDurumu.bildirimYok => ('Bildirim gönderilmedi', ListeTonu.notr),
        TeyitDurumu.yok => ('—', ListeTonu.notr),
      };
    }
    return switch (k.katildi) {
      true => ('Katıldı', ListeTonu.basari),
      false => ('Katılmadı', ListeTonu.hata),
      null => ('Yoklama girilmedi', ListeTonu.notr),
    };
  }

  @override
  Widget build(BuildContext context) {
    final k = katilimci;
    final (durum, ton) = _durum();
    final eylemler = <Widget>[
      if (ders.gelecekMi && !k.planDisiMi && k.teyit != TeyitDurumu.katilacak)
        _KucukEylem(etiket: 'Katılacak', onTap: mesgul ? null : onKatilacak),
      if (ders.gelecekMi &&
          !k.planDisiMi &&
          (k.teyit == TeyitDurumu.bekliyor ||
              k.teyit == TeyitDurumu.bildirimYok))
        _KucukEylem(etiket: 'Hatırlat', onTap: mesgul ? null : onHatirlat),
      if (!ders.gelecekMi && k.paketDusumu == PaketDusumu.dus)
        _KucukEylem(
            etiket: 'Paketten düş', onTap: mesgul ? null : onPaketDusum),
      if (!ders.gelecekMi && k.paketDusumu == PaketDusumu.geriAl)
        _KucukEylem(
            etiket: 'Düşümü geri al', onTap: mesgul ? null : onPaketDusum),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ListeAvatari(
                basHarfler: ListeAvatari.harfler(k.adSoyad),
                ton: ton,
                cap: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.adSoyad + (k.planDisiMi ? ' · plan dışı' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.titleSmall,
                    ),
                    Text(
                      durum,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.bodySmall
                          ?.copyWith(color: ton.on(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (eylemler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 4),
              child: Wrap(spacing: 8, runSpacing: 4, children: eylemler),
            ),
        ],
      ),
    );
  }
}

class _KucukEylem extends StatelessWidget {
  final String etiket;
  final VoidCallback? onTap;
  const _KucukEylem({required this.etiket, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(etiket),
      );
}
