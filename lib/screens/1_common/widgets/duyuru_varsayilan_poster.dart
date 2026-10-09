// lib/screens/1_common/widgets/duyuru_varsayilan_poster.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Görseli olmayan duyurular için kodla çizilmiş poster: turuncu zemin,
/// dekoratif halkalar, megafon ve "DUYURU" etiketi. Açılış popup'ı ve duyuru
/// detay sayfası aynı posteri kullanır; zemin her iki temada marka turuncusu.
class DuyuruVarsayilanPoster extends StatelessWidget {
  const DuyuruVarsayilanPoster({super.key});

  @override
  Widget build(BuildContext context) {
    Widget daire(double cap, double opaklik) => Container(
          width: cap,
          height: cap,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opaklik),
          ),
        );

    return ClipRect(
      child: ColoredBox(
        color: Marka.turuncu,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(top: -70, right: -50, child: daire(240, 0.12)),
            Positioned(bottom: -90, left: -60, child: daire(260, 0.10)),
            Positioned(bottom: 40, right: 30, child: daire(56, 0.14)),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: Bosluk.m),
                    Text(
                      'DUYURU',
                      style: context.metin.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
