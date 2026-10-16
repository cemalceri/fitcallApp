// lib/screens/1_common/program/program_talep_blok.dart
//
// Izgarada karar bekleyen ders kayıt talebi. Ders bloğundan üç yolla ayrılır:
// dolgu yok (yüzey rengi), kenar kesik çizgili ve "bekliyor" renginde, üstte
// kum saati + "Talep". İptal taraması (çapraz çizgi) hiç kullanılmaz; o iptale
// ayrılmış. Sol şerit talebi açan antrenörün rengi.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

import 'program_constants.dart';

class ProgramTalepBlok extends StatelessWidget {
  final DersKayitTalebi talep;
  final double yukseklik;
  final VoidCallback? onTap;

  const ProgramTalepBlok({
    super.key,
    required this.talep,
    required this.yukseklik,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bekliyor = context.renkler.dersBekliyor;
    final yaricap = BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi);
    final detayGoster = yukseklik >= ProgramOlculeri.blokDetayEsigi;

    return Semantics(
      button: onTap != null,
      label:
          'Onay bekleyen ders kayıt talebi, ${talep.saat}-${talep.bitisSaat}, '
          '${talep.kortAdi}, ${talep.talepEdenAdi}',
      excludeSemantics: true,
      child: Material(
        color: context.cs.surface,
        borderRadius: yaricap,
        child: InkWell(
          onTap: onTap,
          borderRadius: yaricap,
          child: CustomPaint(
            painter: _KesikKenar(renk: bekliyor, yaricap: yaricap),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: yaricap,
                border: Border(
                  left: BorderSide(
                    color: talep.antrenorRenk,
                    width: ProgramOlculeri.blokSolSeritGenisligi,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(6, 3, 4, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          size: 11, color: bekliyor),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'Talep · ${talep.saat}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: context.cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (detayGoster)
                    Text(
                      talep.talepEdenAdi.isEmpty ? '—' : talep.talepEdenAdi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış dikdörtgen kenarını kesik çizgiyle çizer.
class _KesikKenar extends CustomPainter {
  final Color renk;
  final BorderRadius yaricap;

  _KesikKenar({required this.renk, required this.yaricap});

  static const double _cizgi = 4;
  static const double _bosluk = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final yol = Path()
      ..addRRect(yaricap.toRRect(Offset.zero & size).deflate(0.75));
    for (final parca in yol.computeMetrics()) {
      var d = 0.0;
      while (d < parca.length) {
        canvas.drawPath(parca.extractPath(d, d + _cizgi), boya);
        d += _cizgi + _bosluk;
      }
    }
  }

  @override
  bool shouldRepaint(_KesikKenar eski) =>
      eski.renk != renk || eski.yaricap != yaricap;
}
