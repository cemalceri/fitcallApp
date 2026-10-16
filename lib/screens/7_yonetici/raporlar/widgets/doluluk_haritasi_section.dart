// lib/screens/7_yonetici/raporlar/widgets/doluluk_haritasi_section.dart

import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/common/tema.dart';

/// Saat x haftanın günü ders yoğunluğu ısı haritası.
class DolulukHaritasiSection extends StatelessWidget {
  final DolulukHaritasi data;

  const DolulukHaritasiSection({super.key, required this.data});

  // Isı haritası tek renk: temanın ana renginin açıklık basamakları.
  Color _hucreRenk(int deger, ColorScheme colorScheme) {
    final base = colorScheme.primary;
    if (deger <= 0) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    }
    final t = data.maxSayi > 0 ? deger / data.maxSayi : 0.0;
    return Color.lerp(
      base.withValues(alpha: 0.18),
      base,
      t.clamp(0.0, 1.0),
    )!;
  }

  // Yazı, hücrenin kart zemini üstündeki gerçek renginden seçilir: sabit bir
  // eşik koyu modda orta hücrelerde açık yazıyı açık zemine düşürüyordu.
  Color _yaziRenk(int deger, ColorScheme colorScheme) {
    if (deger <= 0) return Colors.transparent;
    return uzerineYazi(
      Color.alphaBlend(_hucreRenk(deger, colorScheme), colorScheme.surface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.grid_on, size: 18, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Doluluk Isı Haritası',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${data.toplamDers} ders',
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.maxSayi == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Bu dönemde ders yok',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            )
          else ...[
            // Gün başlıkları
            Row(
              children: [
                const SizedBox(width: 38),
                ...data.gunler.map((g) => Expanded(
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 6),
            // Satırlar (saat)
            ...data.hucreler.map((satir) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${satir.saat.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ...satir.degerler.map((v) => Expanded(
                            child: Container(
                              height: 24,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _hucreRenk(v, colorScheme),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  v > 0 ? '$v' : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _yaziRenk(v, colorScheme),
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            _lejant(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _lejant(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Az',
            style:
                TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          final t = (i + 1) / 5;
          return Container(
            width: 16,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: Color.lerp(colorScheme.primary.withValues(alpha: 0.18),
                  colorScheme.primary, t),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 6),
        Text('Çok',
            style:
                TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
