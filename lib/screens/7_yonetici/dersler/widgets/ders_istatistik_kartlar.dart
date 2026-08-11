// lib/screens/7_yonetici/dersler/widgets/ders_istatistik_kartlar.dart

import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';

class DersIstatistikKartlar extends StatelessWidget {
  final DersIstatistik data;

  const DersIstatistikKartlar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Toplam',
            value: data.bugunDers.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCard(
            label: 'Tamamlandı',
            value: data.tamamlanan.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCard(
            label: 'Devam',
            value: data.devamEden.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCard(
            label: 'Bekliyor',
            value: data.bekleyen.toString(),
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCard(
            label: 'İptal',
            value: data.iptal.toString(),
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
