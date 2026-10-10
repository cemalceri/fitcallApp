// lib/screens/1_common/widgets/kimlik_yuzeyi.dart
//
// Renk temasının ekrandaki tek "kimlik yüzeyi" ve onu tamamlayan küçük
// parçalar.
//
// Kural: bir ekranda en fazla bir kimlik yüzeyi olur (üye/antrenörde sonraki
// ders, Hareketler'de bakiye, yöneticide bugünün özeti, detay sayfalarında
// başlık). Yüzeyin gradyanı ve yazı rengi temadan gelir (`context.gecis`);
// yazı her temada tam opak ve kontrast testinden geçmiş durumdadır. İkincil
// bilgi şeffaflıkla soluklaştırılmaz — boyut ve kalınlıkla ayrılır.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Gradyanlı kimlik yüzeyi. Alt kenarında ikinci takım renginin şeridi var.
///
/// İçindeki `Text` ve `Icon`'lar renk vermezse otomatik olarak
/// [TemaGecisleri.onKimlik] alır. `context.metin` stilleri kendi rengini
/// taşıdığı için burada `kimlikYazi(...)` ile kullanılmalı.
class KimlikYuzeyi extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double yaricap;
  final VoidCallback? onTap;

  const KimlikYuzeyi({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 17),
    this.yaricap = Yaricap.l + 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gecis = context.gecis;
    final koyu = context.koyuTema;
    final kenar = BorderRadius.circular(yaricap);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(gradient: gecis.kimlik, borderRadius: kenar),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: padding,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: gecis.onKimlik),
                  child: IconTheme.merge(
                    data: IconThemeData(color: gecis.onKimlik),
                    child: child,
                  ),
                ),
              ),
              // Koyu modda yüzey zeminden az ayrışıyor; üstte ince bir ışık.
              if (koyu)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: ColoredBox(
                    color: gecis.onKimlik.withValues(alpha: 0.10),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gecis.serit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kimlik yüzeyinin üstündeki yazı stili: verilen stilin rengini
/// [TemaGecisleri.onKimlik] ile değiştirir.
TextStyle? kimlikYazi(BuildContext context, TextStyle? stil) =>
    stil?.copyWith(color: context.gecis.onKimlik);

/// Kimlik yüzeyi üstünde küçük bilgi kapsülü (geri sayım, tarih, etiket).
/// Zemini yüzeyi koyulaştırır; beyaz yazının kontrastı her noktada artar.
class KimlikKapsulu extends StatelessWidget {
  final String metin;
  final IconData? ikon;

  const KimlikKapsulu(this.metin, {super.key, this.ikon});

  @override
  Widget build(BuildContext context) {
    final renk = context.gecis.onKimlik;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TemaGecisleri.kapsulZemini,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 13, color: renk),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              metin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: renk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detay sayfalarının başlığı: avatar, ad, alt bilgi ve kapsüller.
/// Sayfanın tek kimlik yüzeyi budur.
class KimlikBaslik extends StatelessWidget {
  final String baslik;
  final String? altBaslik;
  final String basHarfler;
  final List<String> kapsuller;
  final Widget? sag;

  /// Profil fotoğrafı varsa onu gösteren widget; yoksa baş harfler.
  final Widget? avatar;

  const KimlikBaslik({
    super.key,
    required this.baslik,
    required this.basHarfler,
    this.altBaslik,
    this.kapsuller = const [],
    this.sag,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final renk = context.gecis.onKimlik;
    return KimlikYuzeyi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: TemaGecisleri.kapsulZemini,
                  shape: BoxShape.circle,
                  border: Border.all(color: renk.withValues(alpha: 0.5)),
                ),
                child: avatar ??
                    Text(
                      basHarfler,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: renk,
                      ),
                    ),
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: renk,
                      ),
                    ),
                    if (altBaslik != null && altBaslik!.isNotEmpty)
                      Text(
                        altBaslik!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: renk,
                        ),
                      ),
                  ],
                ),
              ),
              if (sag != null) sag!,
            ],
          ),
          if (kapsuller.isNotEmpty) ...[
            const SizedBox(height: Bosluk.m),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final k in kapsuller) KimlikKapsulu(k)],
            ),
          ],
        ],
      ),
    );
  }
}

/// Adın baş harfleri ("Deniz Yılmaz" → "DY"). Boşsa "?".
String basHarfleri(String ad) {
  final parcalar =
      ad.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parcalar.isEmpty) return '?';
  final ilk = parcalar.first.characters.first;
  final son = parcalar.length > 1 ? parcalar.last.characters.first : '';
  return (ilk + son).toUpperCase();
}

/// İlerleme çubuğunun dolgusu: ikinci takım renginin şeridi; şerit nötr
/// zeminde görünmüyorsa (hiçbir tonu raya karşı 3:1 vermiyorsa) kimlik
/// gradyanı.
///
/// Neden: Ay-Yıldız, Siyah-Beyaz, Binay ve açık Sarı-Lacivert'te şerit, koyu
/// kimlik yüzeyinin içinde görünsün diye açık renk (beyaz, krem, sarı). Açık
/// gri rayın üstünde ise neredeyse kayboluyordu.
LinearGradient ilerlemeGradyani(ColorScheme cs, TemaGecisleri gecis) {
  final ray = cs.surfaceContainerHighest;
  final enIyi = gecis.serit.colors
      .map((c) => kontrastOrani(c, ray))
      .reduce((a, b) => a > b ? a : b);
  if (enIyi >= 3) return gecis.serit;
  return LinearGradient(colors: gecis.kimlik.colors, stops: gecis.kimlik.stops);
}

/// İlerleme çubuğu; dolgu ikinci takım renginin şeridiyle (ödül sayacı gibi
/// motivasyon öğeleri için, bkz. [ilerlemeGradyani]). Veri ve durum çubukları
/// için kullanılmaz — onlar düz ana renk.
class GecisCubugu extends StatelessWidget {
  /// 0–1 arası doluluk.
  final double deger;
  final double yukseklik;

  const GecisCubugu({super.key, required this.deger, this.yukseklik = 6});

  @override
  Widget build(BuildContext context) {
    final oran = deger.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: yukseklik,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: context.cs.surfaceContainerHighest),
            ),
            FractionallySizedBox(
              widthFactor: oran,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ilerlemeGradyani(context.cs, context.gecis),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
