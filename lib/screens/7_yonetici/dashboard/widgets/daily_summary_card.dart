// lib/screens/9_yonetici/dashboard/widgets/daily_summary_card.dart

import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';

class DailySummaryCard extends StatelessWidget {
  final GununOzeti data;

  const DailySummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.summarize_outlined,
                  size: 20,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bugünün Özeti',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  value: data.yeniKayit.toString(),
                  label: 'Yeni Kayıt',
                  color: Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  value: data.telafiDers.toString(),
                  label: 'Telafi Ders',
                  color: Colors.orange,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  value: '%${data.dolulukYuzdesi.toStringAsFixed(0)}',
                  label: 'Doluluk',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
