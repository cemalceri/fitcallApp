// lib/screens/1_common/hakedis/widgets/hakedis_ay_seridi.dart
//
// Son 12 ayın yatay seçici şeridi — program ekranındaki gün şeridiyle aynı dil.
//
// İçerik iki satır (ay kısaltması / toplam saat) ve hücre yüksekliği sabit
// olduğundan, yazı ölçeği büyüdüğünde taşmak yerine FittedBox ile küçülür
// (bkz. program_gun_seridi.dart'taki aynı gerekçe).

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

class HakedisAySeridi extends StatelessWidget {
  final List<HakedisAy> aylar;

  /// Seçili ayın listedeki sırası
  final int seciliIndex;

  final ValueChanged<int> onAySec;

  const HakedisAySeridi({
    super.key,
    required this.aylar,
    required this.seciliIndex,
    required this.onAySec,
  });

  static const double yukseklik = 66.0;
  static const double _hucreGenisligi = 58.0;

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    return SizedBox(
      height: yukseklik,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: aylar.length,
        itemBuilder: (context, i) {
          final ay = aylar[i];
          final aktif = i == seciliIndex;
          // Karar bekleyen dersi olan ay, seçili olmasa da işaretlenir.
          final bekleyenVar = ay.bekleyenDersSayisi > 0;

          return GestureDetector(
            onTap: () => onAySec(i),
            child: Container(
              width: _hucreGenisligi,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              decoration: BoxDecoration(
                color: aktif
                    ? renk.primary
                    : renk.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: bekleyenVar && !aktif
                    ? Border.all(color: const Color(0xFFF59E0B), width: 1.4)
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ay.kisaEtiket,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: aktif ? renk.onPrimary : renk.onSurface,
                      ),
                    ),
                    Text(
                      saatMetni(ay.dakika),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.15,
                        color: aktif
                            ? renk.onPrimary.withValues(alpha: 0.85)
                            : renk.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
