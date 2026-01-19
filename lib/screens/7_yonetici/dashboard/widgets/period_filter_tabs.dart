// lib/screens/9_yonetici/dashboard/widgets/period_filter_tabs.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
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

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DonemFiltresi.values.map((donem) {
          final isSelected = donem == seciliDonem;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDonemChanged(donem);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                donem.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
