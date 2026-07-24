// lib/screens/7_yonetici/program/widgets/program_gorunumu.dart
//
// Program sayfasının GÖRSEL gövdesi — durumsuz ve veriyle beslenen tek parça.
//
// Sayfa (YoneticiProgramPage) yalnızca veri çekme/işlem yürütme işini yapar,
// yerleşimi buraya devreder. Ayrılmasının sebebi: sayfa initState'te API
// çağırdığı için widget testinde render edilemiyordu; bu yüzden başlık ve gün
// şeridi hiçbir testin kapsamına girmemiş ve gün şeridindeki 1 piksellik taşma
// ancak cihazda ortaya çıkmıştı. Bu widget testte doğrudan render edilebilir.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'program_gun_seridi.dart';
import 'program_izgara.dart';

class ProgramGorunumu extends StatelessWidget {
  final HaftalikProgram program;
  final DateTime secilenGun;

  /// Üstte ince ilerleme çubuğu gösterilsin mi
  final bool islemDevamEdiyor;

  final VoidCallback? onOncekiHafta;
  final VoidCallback? onSonrakiHafta;
  final VoidCallback? onBugun;
  final ValueChanged<DateTime> onGunSec;
  final ValueChanged<ProgramDersi> onDersTap;
  final void Function(SecenekKort kort, DateTime baslangic)? onBosSlotTap;

  const ProgramGorunumu({
    super.key,
    required this.program,
    required this.secilenGun,
    required this.onGunSec,
    required this.onDersTap,
    this.islemDevamEdiyor = false,
    this.onOncekiHafta,
    this.onSonrakiHafta,
    this.onBugun,
    this.onBosSlotTap,
  });

  String _gunAnahtari(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final gunBasi =
        DateTime(secilenGun.year, secilenGun.month, secilenGun.day);

    return Column(
      children: [
        ProgramBaslik(
          haftaBaslangic: program.haftaBaslangic,
          haftaBitis: program.haftaBitis,
          onOnceki: onOncekiHafta,
          onSonraki: onSonrakiHafta,
          onBugun: onBugun,
        ),
        ProgramGunSeridi(
          gunler: program.gunler,
          seciliTarih: _gunAnahtari(gunBasi),
          bugunTarih: _gunAnahtari(program.bugun),
          onGunSec: onGunSec,
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              ProgramIzgara(
                kortlar: program.kortlar,
                dersler: program.gununDersleri(gunBasi),
                secilenGun: gunBasi,
                onDersTap: onDersTap,
                onBosSlotTap: onBosSlotTap,
              ),
              if (islemDevamEdiyor)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hafta gezinme başlığı. Dar ekran + büyük yazı ölçeğinde taşmaması için
/// başlık metinleri tek satır + ellipsis, "Bugün" düğmesi daraltılabilir.
class ProgramBaslik extends StatelessWidget {
  final DateTime haftaBaslangic;
  final DateTime haftaBitis;
  final VoidCallback? onOnceki;
  final VoidCallback? onSonraki;
  final VoidCallback? onBugun;

  const ProgramBaslik({
    super.key,
    required this.haftaBaslangic,
    required this.haftaBitis,
    this.onOnceki,
    this.onSonraki,
    this.onBugun,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final bicim = DateFormat('d MMM', 'tr_TR');

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onOnceki,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Önceki hafta',
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ders Programı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: renk.onSurface,
                  ),
                ),
                Text(
                  '${bicim.format(haftaBaslangic)} - ${bicim.format(haftaBitis)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    color: renk.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSonraki,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Sonraki hafta',
            visualDensity: VisualDensity.compact,
          ),
          TextButton(
            onPressed: onBugun,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Bugün', maxLines: 1),
          ),
        ],
      ),
    );
  }
}
