// lib/screens/7_yonetici/program/widgets/program_ders_blok.dart
//
// Izgaradaki tek ders bloğu. Yükseklik kısa dersler için çok küçülebildiğinden
// içerik kademeli gösterilir (taşma yerine bilgi azaltılır).

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

import 'program_constants.dart';

class ProgramDersBlok extends StatelessWidget {
  final ProgramDersi ders;
  final double yukseklik;
  final VoidCallback onTap;

  const ProgramDersBlok({
    super.key,
    required this.ders,
    required this.yukseklik,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iptal = ders.iptalMi;
    final serit = iptal ? ProgramRenkleri.iptal : ders.antrenorRenk;
    final zemin = iptal
        ? ProgramRenkleri.iptal.withValues(alpha: 0.10)
        : ders.antrenorRenk.withValues(alpha: 0.14);

    // Alan daraldıkça satır sayısını azalt: taşma yerine bilgi kırpılır.
    final detayGoster = yukseklik >= ProgramOlculeri.blokDetayEsigi;
    final katilimciGoster = yukseklik >= ProgramOlculeri.blokDetayEsigi + 16;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: zemin,
            borderRadius:
                BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi),
            border: Border(
              left: BorderSide(
                color: serit,
                width: ProgramOlculeri.blokSolSeritGenisligi,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(6, 3, 4, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ders.saat} · ${ders.katilimciSayisi} kişi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: iptal ? ProgramRenkleri.iptal : const Color(0xFF0F172A),
                  decoration: iptal ? TextDecoration.lineThrough : null,
                ),
              ),
              if (detayGoster)
                Text(
                  ders.antrenorAdi.isEmpty ? '—' : ders.antrenorAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: Color(0xFF475569),
                  ),
                ),
              if (katilimciGoster && ders.katilimcilar.isNotEmpty)
                Flexible(
                  child: Text(
                    ders.katilimcilar.map((k) => k.adSoyad).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
