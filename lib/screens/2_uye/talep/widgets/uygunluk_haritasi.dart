// lib/screens/2_uye/talep/widgets/uygunluk_haritasi.dart
//
// Haftalık uygunluk haritası: solda saat, üstte 7 gün. Hücre durumu sunucudan
// gelir (uyeTalepHarita): uygun (dokunulur), dolu, benim (üyenin dersi/talebi),
// kapali (pencere dışı). Seçili hücre dolu renkle işaretlenir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

class UygunlukHaritasi extends StatelessWidget {
  final TalepHarita harita;
  final DateTime? secili;
  final ValueChanged<DateTime> onSec;

  const UygunlukHaritasi({
    super.key,
    required this.harita,
    required this.onSec,
    this.secili,
  });

  static const double _satir = 26;
  static const double _saatGenisligi = 44;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gunler = harita.gunler;
    if (gunler.isEmpty) return const SizedBox.shrink();
    final saatler = gunler.first.saatler.map((s) => s.saat).toList();
    // Rehber hedefi: en üst satırdaki ilk uygun kare (kaydırmadan görünür).
    HaritaSaat? ilkUygun;
    for (var r = 0; r < saatler.length && ilkUygun == null; r++) {
      for (final g in gunler) {
        if (r < g.saatler.length && g.saatler[r].uygun) {
          ilkUygun = g.saatler[r];
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Gün başlıkları
        Row(
          children: [
            const SizedBox(width: _saatGenisligi),
            for (final g in gunler)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE', 'tr_TR').format(g.tarih),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '${g.tarih.day}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: g.uygunSayisi > 0 ? cs.onSurface : cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: Bosluk.xs),
        for (var r = 0; r < saatler.length; r++)
          SizedBox(
            height: _satir,
            child: Row(
              children: [
                SizedBox(
                  width: _saatGenisligi,
                  child: saatler[r].endsWith(':00')
                      ? Text(
                          saatler[r],
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        )
                      : null,
                ),
                for (final g in gunler)
                  Expanded(
                    child: ogrenmeHedefiSar(
                      r < g.saatler.length && identical(g.saatler[r], ilkUygun)
                          ? Hedef.uyeTalepKare
                          : null,
                      _hucre(context, g,
                          r < g.saatler.length ? g.saatler[r] : null),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hucre(BuildContext context, HaritaGun gun, HaritaSaat? s) {
    final cs = context.cs;
    if (s == null) return const SizedBox.shrink();
    final parca = s.saat.split(':');
    final an = DateTime(
        gun.tarih.year,
        gun.tarih.month,
        gun.tarih.day,
        int.tryParse(parca[0]) ?? 0,
        int.tryParse(parca.length > 1 ? parca[1] : '0') ?? 0);
    final seciliMi = secili != null && secili == an;
    final Color zemin;
    switch (s.durum) {
      case 'uygun':
        zemin = seciliMi ? cs.primary : cs.primaryContainer;
      case 'benim':
        zemin = context.renkler.uyariZemin;
      case 'dolu':
        zemin = cs.surfaceContainerHighest;
      default:
        zemin = Colors.transparent;
    }
    final hucre = Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(4),
        border: s.durum == 'kapali'
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.4))
            : null,
      ),
      child: seciliMi
          ? Icon(Icons.check_rounded, size: 14, color: cs.onPrimary)
          : null,
    );
    if (!s.uygun) {
      return Semantics(label: '${s.saat} ${_durumAdi(s.durum)}', child: hucre);
    }
    return Semantics(
      button: true,
      selected: seciliMi,
      label:
          '${DateFormat('d MMMM EEEE', 'tr_TR').format(gun.tarih)} ${s.saat} uygun',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onSec(an),
        child: hucre,
      ),
    );
  }

  static String _durumAdi(String d) => switch (d) {
        'dolu' => 'dolu',
        'benim' => 'senin dersin ya da talebin var',
        _ => 'seçilemez',
      };
}

/// Haritanın altındaki renk açıklaması.
class HaritaLejanti extends StatelessWidget {
  const HaritaLejanti({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    Widget kutu(Color renk, String ad) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                  color: renk, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: Bosluk.xs),
            Text(ad,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        );
    return Wrap(
      spacing: Bosluk.m,
      runSpacing: Bosluk.xs,
      children: [
        kutu(cs.primaryContainer, 'Uygun'),
        kutu(cs.surfaceContainerHighest, 'Dolu'),
        kutu(context.renkler.uyariZemin, 'Senin dersin / talebin'),
      ],
    );
  }
}
