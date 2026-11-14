// lib/screens/7_yonetici/raporlar/widgets/rapor_ozetleri.dart
//
// Raporlar'ın özet kartları (2026-11 yeniden tasarım): rakam + kıyas + grafik.
// Ayrıntılı gün gün tablolar bu kartların altında durur.
//
//   RaporDonemOzeti    ders bedeli (günlük çubuklar), ürün kırılımı, tahsil edilen
//   RaporDolulukKarti  dönemin doluluğu ve önceki döneme göre puan farkı
//   SakinSaatlerNotu   ısı haritasından: haftanın en sakin saatleri ve günü
//
// Tahsil edilen kıyaslanmaz (ödemeler gecikmeli giriliyor); yerine son giriş.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class RaporDonemOzeti extends StatelessWidget {
  final RaporCiroOzeti ciro;
  final RaporTahsilatOzeti? tahsilat;
  final List<CiroRaporuItem> gunler;
  final List<UrunKirilimi> urunler;

  const RaporDonemOzeti({
    super.key,
    required this.ciro,
    required this.gunler,
    this.tahsilat,
    this.urunler = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DersBedeliKarti(ciro: ciro, gunler: gunler),
        if (urunler.isNotEmpty) ...[
          const SizedBox(height: Bosluk.m),
          _UrunKirilimKarti(urunler: urunler),
        ],
        if (tahsilat != null) ...[
          const SizedBox(height: Bosluk.m),
          _KasaKarti(tahsilat: tahsilat!),
        ],
      ],
    );
  }
}

class _DersBedeliKarti extends StatelessWidget {
  final RaporCiroOzeti ciro;
  final List<CiroRaporuItem> gunler;

  const _DersBedeliKarti({required this.ciro, required this.gunler});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return PanoKarti(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PanoEtiketi('Ders bedeli'),
                    const SizedBox(height: 2),
                    TutarYazisi(tutarYaz(ciro.toplam), birim: 'TL'),
                  ],
                ),
              ),
              const SizedBox(width: Bosluk.s),
              TrendRozeti(ciro.degisimYuzdesi),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${ciro.dersSayisi} dersin bedeli · önceki dönem '
            '${tlYaz(ciro.oncekiToplam)}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (gunler.length > 1) ...[
            const SizedBox(height: Bosluk.m),
            _GunlukCubuklar(gunler: gunler),
          ],
        ],
      ),
    );
  }
}

/// Gün gün ders bedeli. 7 güne kadar her çubuğun altında gün adı; daha
/// uzunsa yalnız ilk ve son tarih yazılır.
class _GunlukCubuklar extends StatelessWidget {
  final List<CiroRaporuItem> gunler;
  const _GunlukCubuklar({required this.gunler});

  static const double _boy = 72;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final enBuyuk = gunler.fold<double>(0, (m, g) => g.ciro > m ? g.ciro : m);
    final kisa = gunler.length <= 7;
    final gunAdi = DateFormat('E', 'tr_TR');
    final gunAy = DateFormat('d MMM', 'tr_TR');
    final etiket = TextStyle(fontSize: 10, color: cs.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _boy,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final g in gunler)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: kisa ? 4 : 1),
                    child: Container(
                      height: enBuyuk <= 0
                          ? 3
                          : (3 + (_boy - 3) * (g.ciro / enBuyuk)),
                      decoration: BoxDecoration(
                        color: g.ciro == enBuyuk && enBuyuk > 0
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(kisa ? 6 : 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (kisa)
          Row(
            children: [
              for (final g in gunler)
                Expanded(
                  child: Text(
                    gunAdi.format(g.tarih),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: etiket,
                  ),
                ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gunAy.format(gunler.first.tarih), style: etiket),
              Text(gunAy.format(gunler.last.tarih), style: etiket),
            ],
          ),
      ],
    );
  }
}

class _UrunKirilimKarti extends StatelessWidget {
  final List<UrunKirilimi> urunler;
  const _UrunKirilimKarti({required this.urunler});

  /// Dilim renkleri temadan; durum renkleri (hata, başarı) kullanılmaz.
  static List<Color> _renkler(BuildContext context) {
    final cs = context.cs;
    return [
      cs.primary,
      cs.tertiary,
      cs.secondary,
      context.renkler.bilgi,
      cs.outline,
      cs.onSurfaceVariant,
      cs.outlineVariant,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renkler = _renkler(context);
    final toplam = urunler.fold<double>(0, (t, u) => t + u.tutar);

    return PanoKarti(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanoBasligi('Ürüne göre ders bedeli'),
          const SizedBox(height: Bosluk.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (var i = 0; i < urunler.length; i++)
                    Expanded(
                      flex: toplam <= 0
                          ? 1
                          : (urunler[i].tutar / toplam * 1000).round().clamp(1, 1000),
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        color: renkler[i % renkler.length],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < urunler.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: renkler[i % renkler.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: Bosluk.s),
                  Expanded(
                    child: Text(
                      urunler[i].ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: Bosluk.s),
                  // Dar ekranda büyük yazıyla tutar ada yer bırakır: küçülür,
                  // satır taşmaz.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        tlYaz(urunler[i].tutar),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      toplam <= 0
                          ? ''
                          : '%${(urunler[i].tutar / toplam * 100).round()}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
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

class _KasaKarti extends StatelessWidget {
  final RaporTahsilatOzeti tahsilat;
  const _KasaKarti({required this.tahsilat});

  @override
  Widget build(BuildContext context) {
    final son = tahsilat.sonGiris;
    return PanoKarti(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanoEtiketi('Tahsil edilen · dönem toplamı'),
                const SizedBox(height: 2),
                TutarYazisi(tutarYaz(tahsilat.toplam), birim: 'TL'),
                const SizedBox(height: 2),
                Text(
                  son == null
                      ? '${tahsilat.islemSayisi} ödeme'
                      : '${tahsilat.islemSayisi} ödeme · son giriş '
                          '${sonGirisYaz(son)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Bosluk.m),
          const TonKarosu(
            ikon: Icons.account_balance_wallet_outlined,
            ton: ListeTonu.basari,
          ),
        ],
      ),
    );
  }
}

class RaporDolulukKarti extends StatelessWidget {
  final RaporDolulukOzeti ozet;
  const RaporDolulukKarti({super.key, required this.ozet});

  @override
  Widget build(BuildContext context) {
    return PanoKarti(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanoEtiketi('Doluluk'),
                const SizedBox(height: 2),
                TutarYazisi('%${ozet.yuzde.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TrendRozeti(ozet.yuzde - ozet.oncekiYuzde, puan: true),
                    Text(
                      'önceki dönem %${ozet.oncekiYuzde.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Bosluk.m),
          HalkaGosterge(ozet.yuzde / 100, boyut: 64, kalinlik: 7),
        ],
      ),
    );
  }
}

/// Isı haritasının sözle özeti: "En sakin saatler 14:00, 15:00 ve 11:00;
/// en sakin gün Salı." Tek tek hücre yerine saat ve gün TOPLAMLARI kıyaslanır:
/// boş hücre çok olduğunda "en boş hücre" rastgele kalırdı.
class SakinSaatlerNotu extends StatelessWidget {
  final DolulukHaritasi harita;
  const SakinSaatlerNotu({super.key, required this.harita});

  /// Kıyaslanan saat aralığı: sabah erken ve gece geç saatler zaten boş.
  static const int ilkSaat = 9;
  static const int sonSaat = 21;

  static const _gunAdlari = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
  ];

  /// Hafta boyunca en az ders başlayan [adet] saat (azdan çoğa).
  static List<int> sakinSaatler(DolulukHaritasi harita, {int adet = 3}) {
    final satirlar = harita.hucreler
        .where((s) => s.saat >= ilkSaat && s.saat <= sonSaat)
        .toList()
      ..sort((a, b) {
        final fark = _toplam(a).compareTo(_toplam(b));
        return fark != 0 ? fark : a.saat.compareTo(b.saat);
      });
    return satirlar.take(adet).map((s) => s.saat).toList();
  }

  /// Haftanın en az dersli günü (0 = Pazartesi); veri yoksa null.
  static int? sakinGun(DolulukHaritasi harita) {
    final toplamlar = List<int>.filled(7, 0);
    for (final satir in harita.hucreler) {
      for (var g = 0; g < satir.degerler.length && g < 7; g++) {
        toplamlar[g] += satir.degerler[g];
      }
    }
    if (harita.hucreler.isEmpty) return null;
    var enAz = 0;
    for (var g = 1; g < 7; g++) {
      if (toplamlar[g] < toplamlar[enAz]) enAz = g;
    }
    return enAz;
  }

  static int _toplam(DolulukHaritasiSatir satir) =>
      satir.degerler.fold(0, (t, d) => t + d);

  static String _saatListesi(List<int> saatler) {
    final yazi = [for (final s in saatler) '${s.toString().padLeft(2, '0')}:00'];
    if (yazi.length < 2) return yazi.join();
    return '${yazi.sublist(0, yazi.length - 1).join(', ')} ve ${yazi.last}';
  }

  @override
  Widget build(BuildContext context) {
    final saatler = sakinSaatler(harita);
    final gun = sakinGun(harita);
    if (saatler.isEmpty || gun == null || harita.toplamDers == 0) {
      return const SizedBox.shrink();
    }
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: cs.primary),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'En sakin saatler ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${_saatListesi(saatler)}; '),
                  const TextSpan(
                    text: 'en sakin gün ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${_gunAdlari[gun]}.'),
                ],
              ),
              style: TextStyle(fontSize: 12.5, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
