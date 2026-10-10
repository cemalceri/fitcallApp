// lib/screens/1_common/takvim/iptal_taramasi.dart
//
// İptal edilen dersin zeminine çapraz tarama.
//
// Neden: iptal durumu yalnız renkle anlatılırsa kırmızı takım temalarında
// (Sarı-Kırmızı, Ay-Yıldız) ve renk körlüğünde kaybolur. Takvimlerde iptal
// bloğu üç ipucu birden taşır: üstü çizili başlık, iptal ikonu ve bu tarama.
// Üye, antrenör ve ofis takvimleri aynı bileşeni kullanır.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class IptalTaramasi extends StatelessWidget {
  final Widget child;

  /// false ise [child] olduğu gibi döner (koşullu sarmalamayı kolaylaştırır).
  final bool aktif;

  /// Bloğun köşe yarıçapı; tarama köşelerden taşmasın.
  final BorderRadius yaricap;

  const IptalTaramasi({
    super.key,
    required this.child,
    this.aktif = true,
    this.yaricap = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (!aktif) return child;
    return ClipRRect(
      borderRadius: yaricap,
      child: CustomPaint(
        painter: IptalTaramaBoyaci(
          renk: context.renkler.hata.withValues(alpha: 0.16),
        ),
        child: child,
      ),
    );
  }
}

/// 45°'lik paralel çizgiler. Renk dışarıdan verilir (durum rengi, her temada
/// aynı).
class IptalTaramaBoyaci extends CustomPainter {
  final Color renk;
  final double aralik;
  final double kalinlik;

  const IptalTaramaBoyaci({
    required this.renk,
    this.aralik = 9,
    this.kalinlik = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final kalem = Paint()
      ..color = renk
      ..strokeWidth = kalinlik
      ..style = PaintingStyle.stroke;
    // Sol alttan sağ üste çizgiler; tüm alanı örtecek kadar başlangıç noktası.
    for (double x = -size.height; x < size.width; x += aralik) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        kalem,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IptalTaramaBoyaci eski) =>
      eski.renk != renk || eski.aralik != aralik || eski.kalinlik != kalinlik;
}
