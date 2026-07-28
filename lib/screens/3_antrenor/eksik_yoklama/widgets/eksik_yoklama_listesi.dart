import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yoklaması eksik derslerin listesi (güne göre gruplu, modern kartlar).
///
/// API çağrısı içermez; veri dışarıdan verilir → taşma testinde pump edilebilir.
class EksikYoklamaListesi extends StatelessWidget {
  final List<EtkinlikModel> dersler;
  final void Function(EtkinlikModel) onDersTap;

  const EksikYoklamaListesi({
    super.key,
    required this.dersler,
    required this.onDersTap,
  });

  @override
  Widget build(BuildContext context) {
    final gunFmt = DateFormat('d MMMM EEEE', 'tr');
    final gruplar = <String, List<EtkinlikModel>>{};
    for (final d in dersler) {
      final k = gunFmt.format(d.baslangicTarihSaat);
      gruplar.putIfAbsent(k, () => []).add(d);
    }

    final widgets = <Widget>[];
    gruplar.forEach((gun, list) {
      widgets.add(_GunBasligi(gun: gun, adet: list.length));
      for (final d in list) {
        widgets.add(_DersKarti(ders: d, onTap: () => onDersTap(d)));
      }
    });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: widgets,
    );
  }
}

class _GunBasligi extends StatelessWidget {
  final String gun;
  final int adet;
  const _GunBasligi({required this.gun, required this.adet});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              gun[0].toUpperCase() + gun.substring(1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$adet ders',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DersKarti extends StatelessWidget {
  final EtkinlikModel ders;
  final VoidCallback onTap;
  const _DersKarti({required this.ders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const renk = Color(0xFFF59E0B); // beklemede/uyarı rengi
    final saatFmt = DateFormat('HH:mm');
    final katilimci = ders.uyeList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: renk.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fact_check_outlined,
                      color: renk, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${saatFmt.format(ders.baslangicTarihSaat)}'
                              ' - ${saatFmt.format(ders.bitisTarihSaat)}'
                              '${ders.kortAdi.isNotEmpty ? ' · ${ders.kortAdi}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$katilimci katılımcı · Yoklama bekliyor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: renk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
