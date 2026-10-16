// lib/screens/1_common/program/program_ders_blok.dart
//
// Izgaradaki tek ders bloğu. Yükseklik kısa dersler için çok küçülebildiğinden
// içerik kademeli gösterilir (taşma yerine bilgi azaltılır).
//
// [vurgulu]: antrenörün tüm programında kendi dersleri. Ayrım yalnız renge
// dayanmasın diye tam kenarlık + koyu zemin + kişi ikonu birlikte kullanılır.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/takvim/iptal_taramasi.dart';
import 'package:flutter/material.dart';

import 'program_constants.dart';

class ProgramDersBlok extends StatelessWidget {
  final ProgramDersi ders;
  final double yukseklik;
  final VoidCallback onTap;
  final bool vurgulu;

  const ProgramDersBlok({
    super.key,
    required this.ders,
    required this.yukseklik,
    required this.onTap,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    final iptal = ders.iptalMi;
    final serit = iptal ? ProgramRenkleri.iptal : ders.antrenorRenk;
    final zemin = iptal
        ? ProgramRenkleri.iptal.withValues(alpha: 0.10)
        : ders.antrenorRenk.withValues(alpha: vurgulu ? 0.26 : 0.14);

    // Alan daraldıkça satır sayısını azalt: taşma yerine bilgi kırpılır.
    final detayGoster = yukseklik >= ProgramOlculeri.blokDetayEsigi;
    final katilimciGoster = yukseklik >= ProgramOlculeri.blokDetayEsigi + 16;

    return Semantics(
      button: true,
      label: '${ders.saat}-${ders.bitisSaat}, ${ders.kortAdi}, '
          '${ders.antrenorAdi}, ${ders.katilimciSayisi} kişi'
          '${iptal ? ', iptal' : ''}${vurgulu ? ', senin dersin' : ''}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi),
          child: IptalTaramasi(
              aktif: iptal,
              yaricap: BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi),
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: zemin,
                  borderRadius:
                      BorderRadius.circular(ProgramOlculeri.blokKoseYaricapi),
                  border: vurgulu
                      ? Border(
                          left: BorderSide(
                            color: serit,
                            width: ProgramOlculeri.blokSolSeritGenisligi,
                          ),
                          top: BorderSide(color: serit, width: 1.5),
                          right: BorderSide(color: serit, width: 1.5),
                          bottom: BorderSide(color: serit, width: 1.5),
                        )
                      : Border(
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
                    Row(
                      children: [
                        if (vurgulu) ...[
                          Icon(Icons.person_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 2),
                        ],
                        Flexible(
                          child: Text(
                            '${ders.saat} · ${ders.katilimciSayisi} kişi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: iptal
                                  ? ProgramRenkleri.iptal
                                  : Theme.of(context).colorScheme.onSurface,
                              decoration:
                                  iptal ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (detayGoster)
                      Text(
                        ders.antrenorAdi.isEmpty ? '—' : ders.antrenorAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (katilimciGoster && ders.katilimcilar.isNotEmpty)
                      Flexible(
                        child: Text(
                          ders.katilimcilar.map((k) => k.adSoyad).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            height: 1.15,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
