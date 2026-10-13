// lib/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart
//
// Ofis "Dersler" ekranının sunum gövdesi: başlık bandında tarih gezinmesi ve
// süzgeçler, altında günün dersleri. Web /etkinlik/ders-yonetimi sayfasının
// mobil karşılığı — işlemler satıra dokununca açılan sayfada
// (ders_yonetim_sheet.dart). API çağrısı içermez; taşma testinde doğrudan
// çizilir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gün listesinin süzgeci.
enum DersSuzgeci { tumu, onayBekleyen, cevapsiz, iptal }

extension DersSuzgeciEtiketi on DersSuzgeci {
  String get etiket => switch (this) {
        DersSuzgeci.tumu => 'Tümü',
        DersSuzgeci.onayBekleyen => 'Onay bekleyen',
        DersSuzgeci.cevapsiz => 'Cevap bekleyen',
        DersSuzgeci.iptal => 'İptal',
      };

  bool uyar(YonetimDersi d) => switch (this) {
        DersSuzgeci.tumu => true,
        DersSuzgeci.onayBekleyen => d.onayBekliyor,
        DersSuzgeci.cevapsiz => d.cevapsiz > 0,
        DersSuzgeci.iptal => d.iptalMi,
      };
}

/// Dersin listedeki durum etiketi ve tonu.
(String, ListeTonu) dersDurumu(YonetimDersi d) {
  if (d.iptalMi) return ('İptal', ListeTonu.hata);
  if (d.yoneticiKarari == true) return ('Yapıldı', ListeTonu.basari);
  if (d.yoneticiKarari == false) return ('Yapılmadı', ListeTonu.hata);
  if (d.onayBekliyor) return ('Onay bekliyor', ListeTonu.uyari);
  if (d.cevapsiz > 0) return ('${d.cevapsiz} cevap bekliyor', ListeTonu.uyari);
  if (d.gecmisMi) return ('Devam ediyor', ListeTonu.bilgi);
  return ('Planlı', ListeTonu.bilgi);
}

class OfisDerslerGorunumu extends StatelessWidget {
  final DateTime tarih;
  final DersYonetimiGun? gun;
  final bool yukleniyor;
  final String? hata;
  final DersSuzgeci suzgec;

  /// Toplu onay sürüyor (buton içi ilerleme).
  final bool topluOnayDevam;

  /// Sayfa başka bir ekrandan açıldıysa geri oku.
  final bool geriVar;

  final VoidCallback onOnceki;
  final VoidCallback onSonraki;
  final VoidCallback onTarihSec;
  final VoidCallback onBugun;
  final ValueChanged<DersSuzgeci> onSuzgec;
  final ValueChanged<YonetimDersi> onDersSec;
  final VoidCallback onTopluOnay;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;

  const OfisDerslerGorunumu({
    super.key,
    required this.tarih,
    required this.gun,
    required this.yukleniyor,
    required this.hata,
    required this.suzgec,
    this.topluOnayDevam = false,
    this.geriVar = false,
    required this.onOnceki,
    required this.onSonraki,
    required this.onTarihSec,
    required this.onBugun,
    required this.onSuzgec,
    required this.onDersSec,
    required this.onTopluOnay,
    required this.onYenile,
    required this.onYenidenDene,
  });

  // Kısa biçim: oklar ve "Bugün" arasında uzun gün adı kesiliyordu.
  static final _tarihBicimi = DateFormat('d MMM y, EEE', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _baslik(context),
        Expanded(child: _govde(context)),
      ],
    );
  }

  Widget _baslik(BuildContext context) {
    final g = context.gecis;
    final kontrolZemini = g.onBaslik.withValues(alpha: 0.16);
    final kontrolStili = IconButton.styleFrom(
      backgroundColor: kontrolZemini,
      foregroundColor: g.onBaslik,
    );
    return BaslikBandi(
      padding: EdgeInsets.fromLTRB(geriVar ? 4 : 16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (geriVar)
                IconButton(
                  tooltip: 'Geri',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              const Expanded(
                child: Text(
                  'Dersler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                tooltip: 'Önceki gün',
                onPressed: onOnceki,
                icon: const Icon(Icons.chevron_left),
                style: kontrolStili,
              ),
              const SizedBox(width: 4),
              Expanded(
                // Yalnız kenarlık: dolgu üstünde beyaz yazı Binay açıkta
                // eşiğin altında kalıyordu.
                child: Material(
                  color: g.baslik,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: g.onBaslik.withValues(alpha: 0.6)),
                  ),
                  child: InkWell(
                    onTap: onTarihSec,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: g.onBaslik),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _tarihBicimi.format(tarih),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: g.onBaslik,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Sonraki gün',
                onPressed: onSonraki,
                icon: const Icon(Icons.chevron_right),
                style: kontrolStili,
              ),
              TextButton(onPressed: onBugun, child: const Text('Bugün')),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in DersSuzgeci.values) ...[
                  BaslikCipi(
                    etiket: _cipEtiketi(s),
                    secili: suzgec == s,
                    onSec: () => onSuzgec(s),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sayaçlı çip etiketi: "Onay bekleyen · 4".
  String _cipEtiketi(DersSuzgeci s) {
    final v = gun;
    if (v == null || s == DersSuzgeci.tumu) return s.etiket;
    final n = switch (s) {
      DersSuzgeci.onayBekleyen => v.onayBekleyen,
      DersSuzgeci.cevapsiz => v.cevapsiz,
      DersSuzgeci.iptal => v.iptal,
      DersSuzgeci.tumu => v.dersler.length,
    };
    return n > 0 ? '${s.etiket} · $n' : s.etiket;
  }

  Widget _govde(BuildContext context) {
    if (yukleniyor) return const IskeletListe();
    if (hata != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Dersler alınamadı',
        aciklama: hata!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: onYenidenDene,
      );
    }
    final v = gun;
    final dersler =
        (v?.dersler ?? const <YonetimDersi>[]).where(suzgec.uyar).toList();
    final toplu = v?.topluOnaylanabilir ?? 0;

    return RefreshIndicator(
      onRefresh: onYenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (toplu > 0)
            TopluOnayKarti(
              sayi: toplu,
              devam: topluOnayDevam,
              onOnayla: onTopluOnay,
            ),
          if (dersler.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: BosDurum(
                ikon: Icons.event_available_rounded,
                baslik: switch (suzgec) {
                  DersSuzgeci.tumu => 'Bu gün ders yok',
                  DersSuzgeci.onayBekleyen => 'Onay bekleyen ders yok',
                  DersSuzgeci.cevapsiz => 'Katılım cevabı bekleyen yok',
                  DersSuzgeci.iptal => 'İptal edilen ders yok',
                },
                aciklama: suzgec == DersSuzgeci.tumu
                    ? 'Başka bir gün seçin.'
                    : 'Süzgeci "Tümü" yaparak günün bütün derslerini görün.',
              ),
            )
          else
            for (final (i, d) in dersler.indexed) ...[
              if (i > 0) const ListeAyraci(),
              DersYonetimSatiri(ders: d, onTap: () => onDersSec(d)),
            ],
        ],
      ),
    );
  }
}

/// "Antrenörün yapıldı dediği N ders onay bekliyor — Hepsini onayla".
class TopluOnayKarti extends StatelessWidget {
  final int sayi;
  final bool devam;
  final VoidCallback onOnayla;

  const TopluOnayKarti({
    super.key,
    required this.sayi,
    required this.devam,
    required this.onOnayla,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.renkler;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: r.basariZemin,
        borderRadius: BorderRadius.circular(Yaricap.l),
      ),
      // İki satır: dar ekran + büyük yazıda düğme metnin yanına sığmıyordu.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.task_alt_rounded, color: r.basari),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Antrenörün "yapıldı" dediği $sayi ders onay bekliyor.',
                  style: context.metin.bodyMedium?.copyWith(
                      color: context.cs.onSurface, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: devam ? null : onOnayla,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: devam
                ? const SizedBox(
                    width: 18, height: 18, child: ButonYukleniyorGostergesi())
                : const Text('Hepsini onayla',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Günün ders satırı: solda saat bloğu, ortada kort · antrenör, altta ürün
/// ve kişi sayısı, sağda durum rozeti.
class DersYonetimSatiri extends StatelessWidget {
  final YonetimDersi ders;
  final VoidCallback onTap;

  const DersYonetimSatiri({super.key, required this.ders, required this.onTap});

  static final _saat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final (etiket, ton) = dersDurumu(ders);
    final kisi = ders.katilimcilar.length;
    final alt = <String>[
      if (ders.urunAdi != null) ders.urunAdi!,
      '$kisi kişi',
      if (ders.onayBekliyor && ders.antrenorKarari == true)
        'antrenör: yapıldı'
      else if (ders.onayBekliyor && ders.antrenorKarari == false)
        'antrenör: yapılmadı',
      if (ders.planDisiBekleyen > 0) '${ders.planDisiBekleyen} karar bekliyor',
    ];
    return ListeSatiri(
      onGorsel: _SaatBloku(saat: _saat.format(ders.baslangic), ton: ton),
      baslik:
          [ders.kortAdi, if (ders.antrenor != null) ders.antrenor!].join(' · '),
      altBaslik: alt.join(' · '),
      rozet: _Rozet(etiket: etiket, ton: ton),
      okGoster: true,
      onTap: onTap,
    );
  }
}

class _SaatBloku extends StatelessWidget {
  final String saat;
  final ListeTonu ton;

  const _SaatBloku({required this.saat, required this.ton});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Text(
        saat,
        maxLines: 1,
        style: context.metin.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: ton.on(context),
        ),
      ),
    );
  }
}

class _Rozet extends StatelessWidget {
  final String etiket;
  final ListeTonu ton;

  const _Rozet({required this.etiket, required this.ton});

  @override
  Widget build(BuildContext context) {
    // Genişlik sınırı: rozet başlığın yanında esnemeyen bir parça; büyük
    // yazıda "Onay bekliyor" başlığı itip satırı taşırıyordu.
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        etiket,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.metin.labelSmall?.copyWith(color: ton.on(context)),
      ),
    );
  }
}
