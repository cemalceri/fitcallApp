// lib/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart
//
// Puan gösteriminin ortak parçaları: rozet (★ 4.6) ve yıldız sırası (★★★★☆).
// Antrenör listesindeki ortalama ile değerlendirme ekranları aynı rozeti
// kullanır.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Puan rozeti.
///
/// Puan yokken tire koymak bir durum değil, boşluk işareti — okuyan "veri mi
/// yok, sıfır mı?" diye takılıyor. Rozet aynı biçimde kalır, yalnız içeriği ve
/// tonu değişir: dolu yıldız + puan, ya da içi boş yıldız + "Puan yok".
///
/// Yalnız bilgi gösterir, dokunulmaz. Antrenörler listesindeki dokunulur
/// puan hücresi ayrı: bkz. antrenor_liste_item.dart (PuanHucresi).
class PuanRozeti extends StatelessWidget {
  final double? puan;

  /// Tek bir değerlendirmenin puanı (tam sayı, "5"); false ise ortalama
  /// ("4.6").
  final bool tamSayi;

  /// Ortalamanın dayandığı değerlendirme sayısı: "4.8 (23)". 0 ise puan
  /// yok sayılır.
  final int? sayi;

  const PuanRozeti({
    super.key,
    required this.puan,
    this.tamSayi = false,
    this.sayi,
  });

  /// "23", "1B+" — rozet dar; binlerde kesin sayı yerine büyüklük yeter.
  static String sayiMetni(int n) => n < 1000 ? '$n' : '${n ~/ 1000}B+';

  @override
  Widget build(BuildContext context) {
    final renkler = context.renkler;
    final puanVar = puan != null && sayi != 0;

    final zemin = puanVar ? renkler.uyariZemin : context.cs.surfaceContainer;
    final on = puanVar ? renkler.uyari : context.cs.onSurfaceVariant;
    final metin = !puanVar
        ? 'Puan yok'
        : tamSayi
            ? puan!.round().toString()
            : puan!.toStringAsFixed(1);
    final stil = context.metin.labelLarge?.copyWith(color: on);

    final rozet = Container(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 3),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            puanVar ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: on,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: metin,
                style: stil?.copyWith(
                    fontWeight: puanVar ? FontWeight.w600 : null),
                children: [
                  if (puanVar && sayi != null)
                    TextSpan(
                      text: ' (${sayiMetni(sayi!)})',
                      style: stil?.copyWith(fontWeight: FontWeight.w400),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!puanVar || sayi == null) return rozet;
    return Semantics(
      label: 'Ortalama puan $metin, $sayi değerlendirme',
      child: ExcludeSemantics(child: rozet),
    );
  }
}

/// Beş yıldızlık sıra: dolu yıldızlar puan kadar.
class YildizSirasi extends StatelessWidget {
  final int puan;
  final double boyut;

  const YildizSirasi({super.key, required this.puan, this.boyut = 18});

  @override
  Widget build(BuildContext context) {
    final dolu = context.renkler.uyari;
    final bos = context.cs.outlineVariant;
    return Semantics(
      label: '5 üzerinden $puan puan',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= puan ? Icons.star_rounded : Icons.star_outline_rounded,
                size: boyut,
                color: i <= puan ? dolu : bos,
              ),
          ],
        ),
      ),
    );
  }
}
