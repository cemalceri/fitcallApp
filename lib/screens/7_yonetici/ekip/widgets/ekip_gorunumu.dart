// lib/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart
//
// Ekip ekranlarının veriyle beslenen görünümleri (API yok; sayfa ve taşma
// testi aynı widget'ları çizer).
//
//   EkipGorunumu       ekip özeti + çalışan kartları
//   EkipDetayGorunumu  bir çalışanın günü: giriş saatleri, işlem dağılımı, akış
//
// Turnike yalnız girişi okutur: "içeride", çıkış ve süre gösterilmez.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// İşlem koduna göre ikon (akış ve çipler).
IconData ekipIslemIkonu(String kod) => switch (kod) {
      'ders_kaydi' => Icons.event_available_rounded,
      'ders_onayi' => Icons.task_alt_rounded,
      'ders_iptali' => Icons.event_busy_rounded,
      'ders_silme' => Icons.delete_outline_rounded,
      'tahsilat' => Icons.payments_outlined,
      'tahsilat_duzeltme' => Icons.edit_outlined,
      'tahsilat_silme' => Icons.money_off_rounded,
      'dekont' => Icons.receipt_long_rounded,
      'paket_degisikligi' => Icons.inventory_2_outlined,
      'uye_kaydi' => Icons.person_add_alt_1_rounded,
      'uye_guncelleme' => Icons.manage_accounts_outlined,
      'duyuru' => Icons.campaign_outlined,
      _ => Icons.bolt_rounded,
    };

/// Silme ve iptaller hata, para işlemleri uyarı tonunda; gerisi nötr.
ListeTonu ekipIslemTonu(String kod, bool kritik) {
  if (!kritik) return ListeTonu.notr;
  return switch (kod) {
    'ders_silme' || 'ders_iptali' || 'tahsilat_silme' => ListeTonu.hata,
    'tahsilat' || 'dekont' => ListeTonu.basari,
    _ => ListeTonu.uyari,
  };
}

/* ================================ Liste ================================ */

class EkipGorunumu extends StatelessWidget {
  final EkipData data;
  final ValueChanged<EkipKisi> onKisi;

  const EkipGorunumu({super.key, required this.data, required this.onKisi});

  @override
  Widget build(BuildContext context) {
    if (data.kisiler.isEmpty) {
      return const BosDurum(
        ikon: Icons.badge_outlined,
        baslik: 'Ofis çalışanı yok',
        aciklama: 'Ofis rolünde tanımlı kullanıcı bulunmuyor.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EkipOzeti(data: data),
        const SizedBox(height: Bosluk.l),
        for (final kisi in data.kisiler) ...[
          _KisiKarti(kisi: kisi, gruplar: data.gruplar, onTap: () => onKisi(kisi)),
          const SizedBox(height: Bosluk.m),
        ],
      ],
    );
  }
}

class _EkipOzeti extends StatelessWidget {
  final EkipData data;
  const _EkipOzeti({required this.data});

  @override
  Widget build(BuildContext context) {
    Widget hucre(String deger, String etiket) => Expanded(
          child: Column(
            children: [
              TutarYazisi(deger, boyut: 20),
              const SizedBox(height: 2),
              Text(
                etiket,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
    return PanoKarti(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hucre('${data.gelenSayisi}/${data.kisiSayisi}', 'Bugün giriş yapan'),
          hucre('${data.toplamIslem}', 'İşlem'),
          hucre('${data.kritikIslem}', 'Para ve silme işlemi'),
        ],
      ),
    );
  }
}

class _KisiKarti extends StatelessWidget {
  final EkipKisi kisi;
  final List<EkipGrubu> gruplar;
  final VoidCallback onTap;

  const _KisiKarti({
    required this.kisi,
    required this.gruplar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final giris = kisi.bugunGiris;
    final kritikler = kisi.islemler.where((i) => i.kritik).toList();

    return PanoKarti(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ListeAvatari(
                basHarfler: basHarfleri(kisi.adSoyad),
                ton: ListeTonu.vurgu,
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kisi.adSoyad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    DurumHapi(
                      giris == null
                          ? 'Bugün giriş yok'
                          : 'Giriş ${saatYaz(giris)}',
                      ton: giris == null ? ListeTonu.notr : ListeTonu.basari,
                      ikon: giris == null
                          ? Icons.remove_circle_outline_rounded
                          : Icons.login_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Bosluk.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TutarYazisi('${kisi.toplamIslem}', boyut: 20),
                  Text(
                    'işlem',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ],
          ),
          if (kisi.toplamIslem == 0) ...[
            const SizedBox(height: Bosluk.m),
            Text(
              'Bu dönemde işlem yok.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ] else ...[
            const SizedBox(height: Bosluk.m),
            // Grup toplamları: çeşit çok olduğu için önce dört grup.
            Row(
              children: [
                for (final g in gruplar)
                  Expanded(
                    child: _GrupSayisi(
                      etiket: g.etiket,
                      sayi: kisi.grupToplami(g.kod),
                    ),
                  ),
              ],
            ),
            if (kritikler.isNotEmpty) ...[
              const SizedBox(height: Bosluk.m),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final i in kritikler)
                    DurumHapi(
                      '${i.sayi} ${i.etiket.toLowerCase()}',
                      ton: ekipIslemTonu(i.kod, true),
                      ikon: ekipIslemIkonu(i.kod),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GrupSayisi extends StatelessWidget {
  final String etiket;
  final int sayi;
  const _GrupSayisi({required this.etiket, required this.sayi});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$sayi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: sayi == 0 ? cs.onSurfaceVariant : cs.onSurface,
          ),
        ),
        Text(
          etiket,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/* ================================ Detay ================================ */

class EkipDetayGorunumu extends StatefulWidget {
  final EkipDetayData data;

  /// Kulüp saatine göre bugün ("Bugün" / tarih yazısı için).
  final DateTime bugun;

  const EkipDetayGorunumu({super.key, required this.data, required this.bugun});

  @override
  State<EkipDetayGorunumu> createState() => _EkipDetayGorunumuState();
}

class _EkipDetayGorunumuState extends State<EkipDetayGorunumu> {
  /// null = tümü; 'kritik' = yalnız para ve silme işlemleri; yoksa grup kodu.
  String? _suzgec;

  static const _kritik = 'kritik';

  @override
  void didUpdateWidget(EkipDetayGorunumu eski) {
    super.didUpdateWidget(eski);
    // Gün değişince süzgeç sıfırlanır: yeni günde o grup boş olabilir.
    if (!DateUtils.isSameDay(eski.data.gun, widget.data.gun)) _suzgec = null;
  }

  List<EkipAkisSatiri> get _akis => switch (_suzgec) {
        null => widget.data.akis,
        _kritik => widget.data.akis.where((a) => a.kritik).toList(),
        final g => widget.data.akis.where((a) => a.grup == g).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final akis = _akis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GirisKarti(data: data, bugun: widget.bugun),
        const SizedBox(height: Bosluk.m),
        _DagilimKarti(data: data),
        const SizedBox(height: Bosluk.l),
        PanoBasligi(
          'İşlem akışı',
          sag: Text(
            '${akis.length} satır',
            style: TextStyle(fontSize: 12, color: context.cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: Bosluk.s),
        if (data.akis.isNotEmpty) _suzgecler(context, data),
        const SizedBox(height: Bosluk.s),
        if (akis.isEmpty)
          PanoKarti(
            child: Text(
              data.akis.isEmpty
                  ? 'Bu gün için kayıtlı işlem yok.'
                  : 'Bu süzgece uyan işlem yok.',
              style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
            ),
          )
        else
          PanoKarti(
            padding: const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < akis.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: context.cs.outlineVariant),
                  _AkisSatiri(satir: akis[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _suzgecler(BuildContext context, EkipDetayData data) {
    Widget cip(String etiket, String? deger) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(etiket),
            selected: _suzgec == deger,
            onSelected: (_) => setState(() => _suzgec = deger),
            visualDensity: VisualDensity.compact,
          ),
        );
    final dolu = {for (final a in data.akis) a.grup};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          cip('Tümü', null),
          if (data.akis.any((a) => a.kritik)) cip('Para ve silme', _kritik),
          for (final g in data.gruplar)
            if (dolu.contains(g.kod)) cip(g.etiket, g.kod),
        ],
      ),
    );
  }
}

class _GirisKarti extends StatelessWidget {
  final EkipDetayData data;
  final DateTime bugun;

  const _GirisKarti({required this.data, required this.bugun});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final giris = data.giris;
    final bugunMu = DateUtils.isSameDay(data.gun, bugun);
    final gunAdi = DateFormat('E', 'tr_TR');

    return PanoKarti(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TonKarosu(
                ikon: Icons.login_rounded,
                ton: giris == null ? ListeTonu.notr : ListeTonu.basari,
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PanoEtiketi(bugunMu ? 'Bugünkü giriş' : 'O günkü giriş'),
                    Text(
                      giris == null ? 'Turnike girişi yok' : saatYaz(giris),
                      style: TextStyle(
                        fontSize: giris == null ? 15 : 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.girisler.isNotEmpty) ...[
            const SizedBox(height: Bosluk.m),
            Row(
              children: [
                for (final g in data.girisler)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          gunAdi.format(g.gun),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            g.ilkGiris == null ? '–' : saatYaz(g.ilkGiris!),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: g.ilkGiris == null
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Son 7 günün ilk giriş saatleri. Çıkış turnikeden okunmaz.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _DagilimKarti extends StatelessWidget {
  final EkipDetayData data;
  const _DagilimKarti({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final enCok = data.islemler.fold<int>(0, (m, i) => i.sayi > m ? i.sayi : m);
    return PanoKarti(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanoBasligi(
            'Ne yaptı?',
            sag: DurumHapi('${data.toplamIslem} işlem', ton: ListeTonu.vurgu),
          ),
          const SizedBox(height: Bosluk.s),
          if (data.islemler.isEmpty)
            Text(
              'Bu gün için kayıtlı işlem yok.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          for (final i in data.islemler)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(ekipIslemIkonu(i.kod),
                      size: 18, color: ekipIslemTonu(i.kod, i.kritik).on(context)),
                  const SizedBox(width: Bosluk.s),
                  Expanded(
                    flex: 5,
                    child: Text(
                      i.etiket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: IlerlemeCizgisi(
                      enCok == 0 ? 0 : i.sayi / enCok,
                      kalinlik: 6,
                      renk: i.kritik
                          ? ekipIslemTonu(i.kod, true).on(context)
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${i.sayi}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AkisSatiri extends StatelessWidget {
  final EkipAkisSatiri satir;
  const _AkisSatiri({required this.satir});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final ton = ekipIslemTonu(satir.kod, satir.kritik);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                satir.saat,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          TonKarosu(ikon: ekipIslemIkonu(satir.kod), ton: ton, boyut: 34),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  satir.metin,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: satir.kritik ? ton.on(context) : cs.onSurface,
                  ),
                ),
                if ((satir.ayrinti ?? '').isNotEmpty)
                  Text(
                    satir.ayrinti!,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================ İşlem geçmişi ============================ */

/// Bir kaydın geçmişi: kim, ne zaman, ne yaptı (ders ayrıntısında).
class IslemGecmisiListesi extends StatelessWidget {
  final List<IslemGecmisiSatiri> satirlar;
  const IslemGecmisiListesi({super.key, required this.satirlar});

  static (IconData, ListeTonu) _gorunum(String ton) => switch (ton) {
        'ekleme' => (Icons.add_rounded, ListeTonu.vurgu),
        'onay' => (Icons.task_alt_rounded, ListeTonu.basari),
        'iptal' => (Icons.event_busy_rounded, ListeTonu.hata),
        'silme' => (Icons.delete_outline_rounded, ListeTonu.hata),
        _ => (Icons.edit_outlined, ListeTonu.uyari),
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final zamanYazi = DateFormat('d MMM y, HH:mm', 'tr_TR');
    if (satirlar.isEmpty) {
      return Text(
        'Bu ders için kayıtlı işlem bulunamadı.',
        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < satirlar.length; i++) ...[
          if (i > 0) Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TonKarosu(
                  ikon: _gorunum(satirlar[i].ton).$1,
                  ton: _gorunum(satirlar[i].ton).$2,
                  boyut: 34,
                ),
                const SizedBox(width: Bosluk.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        satirlar[i].metin,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        [
                          satirlar[i].kim,
                          if (satirlar[i].zaman != null)
                            zamanYazi.format(satirlar[i].zaman!),
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
