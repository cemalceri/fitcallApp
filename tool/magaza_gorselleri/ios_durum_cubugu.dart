// iOS durum çubuğu: saat solda; hücresel, Wi-Fi ve pil sağda.
//
// Gerçek cihaz ekran görüntüsünde durum çubuğu görünür, Dynamic Island /
// çentik ve ana ekran çubuğu görünmez. Saat Apple'ın kendi tanıtım
// görsellerindeki gibi sabit (09:41), pil dolu, çekim tam.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'cihazlar.dart';

class IosDurumCubugu extends StatelessWidget {
  final MagazaCihazi cihaz;

  /// Çubuğun altındaki zemin koyuysa beyaz, açıksa siyah çizilir.
  final Color renk;
  final DateTime tarih;

  const IosDurumCubugu({
    super.key,
    required this.cihaz,
    required this.renk,
    required this.tarih,
  });

  @override
  Widget build(BuildContext context) {
    final genislik = cihaz.mantiksal.width;
    final ipad = cihaz.tablet;
    final yukseklik = cihaz.guvenliAlan.top;

    // Öğelerin dikey merkezi: Dynamic Island'ın ortası, çentikte çubuğun
    // ortası, iPad'de 24 pt'lik çubuğun ortası.
    final merkezY = switch (cihaz.cubuk) {
      DurumCubuguTipi.dinamikAda => 30.0,
      DurumCubuguTipi.centik => 24.0,
      DurumCubuguTipi.ipad => 12.0,
    };
    // Saat ve ikon grubunun yatay merkezleri (iPhone'da kulakların ortası).
    final kulak = switch (cihaz.cubuk) {
      // Dynamic Island 126 pt; saat sol kulağın ortasında.
      DurumCubuguTipi.dinamikAda => (genislik - 126) / 4 + 2,
      DurumCubuguTipi.centik => 54.0,
      DurumCubuguTipi.ipad => 0.0,
    };

    final saatStili = TextStyle(
      fontFamily: 'CupertinoSystemText',
      fontSize: ipad ? 15 : 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: renk,
      height: 1.0,
    );
    final saat = Text('09:41', style: saatStili, textScaler: TextScaler.noScaling);
    final ikonlar = CustomPaint(
      size: Size(ipad ? 44.5 : 70, ipad ? 11.5 : 12.5),
      painter: _IkonBoyayici(renk, olcek: ipad ? 0.92 : 1.0, hucresel: !ipad),
    );

    return SizedBox(
      width: genislik,
      height: yukseklik,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (ipad)
            Positioned(
              left: 20,
              top: merkezY - 8,
              child: Row(children: [
                saat,
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM EEE', 'tr').format(tarih),
                  style: saatStili,
                  textScaler: TextScaler.noScaling,
                ),
              ]),
            )
          else
            Positioned(
              left: kulak - 40,
              width: 80,
              top: merkezY - 9,
              child: Center(child: saat),
            ),
          Positioned(
            right: ipad ? 20 : null,
            left: ipad ? null : genislik - kulak - 35,
            top: merkezY - (ipad ? 5.75 : 6.25),
            child: ikonlar,
          ),
        ],
      ),
    );
  }
}

class _IkonBoyayici extends CustomPainter {
  final Color renk;
  final double olcek;
  final bool hucresel;

  _IkonBoyayici(this.renk, {required this.olcek, required this.hucresel});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(olcek);
    final dolu = Paint()..color = renk;
    final soluk = Paint()
      ..color = renk.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const h = 12.0;
    var x = 0.0;

    // Hücresel: dört çubuk, alttan hizalı.
    if (hucresel) {
      const boylar = [4.2, 6.4, 8.8, 11.2];
      for (final b in boylar) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, h - b, 3.0, b), const Radius.circular(0.9)),
          dolu,
        );
        x += 4.6;
      }
      x += 3.6;
    }

    // Wi-Fi: alt noktada birleşen üç yay.
    final merkez = Offset(x + 7.8, h - 0.6);
    final yay = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    const aci = 0.78; // ~45° her yöne
    for (final r in [6.4, 10.0]) {
      canvas.drawArc(Rect.fromCircle(center: merkez, radius: r),
          -1.5708 - aci, aci * 2, false, yay);
    }
    final kama = Path()
      ..moveTo(merkez.dx, merkez.dy)
      ..arcTo(Rect.fromCircle(center: merkez, radius: 3.6), -1.5708 - aci,
          aci * 2, false)
      ..close();
    canvas.drawPath(kama, dolu);
    x += 15.6 + 5.2;

    // Pil: çerçeve, dolu gövde, sağda uç.
    const pilG = 24.6, pilY = 11.6;
    final ust = h - pilY - 0.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 0.5, ust + 0.5, pilG - 1, pilY - 1),
          const Radius.circular(3.6)),
      soluk,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 2, ust + 2, pilG - 4, pilY - 4),
          const Radius.circular(2.2)),
      dolu,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x + pilG + 1.0, ust + pilY / 2 - 2.1, 1.5, 4.2),
        topRight: const Radius.circular(1),
        bottomRight: const Radius.circular(1),
      ),
      Paint()..color = renk.withValues(alpha: 0.4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IkonBoyayici eski) =>
      eski.renk != renk || eski.olcek != olcek || eski.hucresel != hucresel;
}
