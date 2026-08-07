// lib/screens/1_common/hakedis/widgets/hakedis_antrenor_listesi.dart
//
// Antrenör seçim ekranının GÖRSEL gövdesi — veriyle beslenen, durumsuz parça
// (sayfa initState'te API çağırdığı için test edilebilirlik adına ayrıldı).
//
// Her satır: baş harfler + ad + son 12 ayın hakediş saati; karar bekleyen dersi
// olan antrenörde turuncu rozet.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

import 'hakedis_stil.dart';

class HakedisAntrenorListesiGorunumu extends StatelessWidget {
  final List<HakedisAntrenorOzeti> antrenorler;
  final ValueChanged<HakedisAntrenorOzeti> onAntrenorTap;
  final Future<void> Function()? onYenile;

  const HakedisAntrenorListesiGorunumu({
    super.key,
    required this.antrenorler,
    required this.onAntrenorTap,
    this.onYenile,
  });

  @override
  Widget build(BuildContext context) {
    final liste = ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: antrenorler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _AntrenorSatiri(
        antrenor: antrenorler[i],
        onTap: () => onAntrenorTap(antrenorler[i]),
      ),
    );

    if (onYenile == null) return liste;
    return RefreshIndicator(onRefresh: onYenile!, child: liste);
  }
}

class _AntrenorSatiri extends StatelessWidget {
  final HakedisAntrenorOzeti antrenor;
  final VoidCallback onTap;

  const _AntrenorSatiri({required this.antrenor, required this.onTap});

  /// "Ahmet Yılmaz" → "AY"; tek kelimeyse ilk iki harf.
  String get _basHarfler {
    final parcalar =
        antrenor.adSoyad.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parcalar.isEmpty) return '?';
    if (parcalar.length == 1) {
      final tek = parcalar.first;
      return (tek.length > 1 ? tek.substring(0, 2) : tek).toUpperCase();
    }
    return '${parcalar.first[0]}${parcalar.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final bekleyenVar = antrenor.bekleyenDersSayisi > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: renk.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: renk.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: renk.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _basHarfler,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: renk.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      antrenor.adSoyad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: renk.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${saatMetni(antrenor.hakedisDakika)} · '
                      '${antrenor.hakedisDersSayisi} ders'
                      '${bekleyenVar ? ' · ${antrenor.bekleyenDersSayisi} bekliyor' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: renk.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Rozet yalnız sayı taşır; "bekliyor" kelimesi alt satırdaki
              // özete konuldu, aksi halde dar ekran + büyük yazıda satır taşıyor.
              if (bekleyenVar) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: hakedisRengi(context, HakedisDurumu.bekliyor)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: hakedisRengi(context, HakedisDurumu.bekliyor),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${antrenor.bekleyenDersSayisi}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: hakedisRengi(context, HakedisDurumu.bekliyor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: renk.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
