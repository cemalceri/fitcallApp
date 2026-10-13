// lib/screens/9_yonetici/dashboard/widgets/period_filter_tabs.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PeriodFilterTabs extends StatelessWidget {
  final DonemFiltresi seciliDonem;
  final ValueChanged<DonemFiltresi> onDonemChanged;

  const PeriodFilterTabs({
    super.key,
    required this.seciliDonem,
    required this.onDonemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Dashboard ve Raporlar'da renkli başlık bandının içinde durur: seçili
    // dönem başlık yazı renginde dolgu, diğerleri tam opak başlık yazısı.
    final baslikta = baslikUstundeMi(context);
    final g = context.gecis;
    // Başlıkta ray yalnız kenarlık: %16 beyaz dolgu üstünde beyaz yazı Binay
    // açıkta 3.65:1 kalıyordu; yazı doğrudan başlık rengi üstünde 4.5'i geçer.
    final rayRengi = baslikta
        ? Colors.transparent
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final seciliZemin = baslikta ? g.onBaslik : colorScheme.primary;
    final seciliYazi = baslikta ? g.baslik : colorScheme.onPrimary;
    final digerYazi = baslikta ? g.onBaslik : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: rayRengi,
        borderRadius: BorderRadius.circular(12),
        border: baslikta
            ? Border.all(color: g.onBaslik.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DonemFiltresi.values.map((donem) {
          final isSelected = donem == seciliDonem;
          return Semantics(
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDonemChanged(donem);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? seciliZemin : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donem.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? seciliYazi : digerYazi,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
