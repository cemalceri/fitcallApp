// lib/screens/7_yonetici/antrenorler/widgets/antrenor_istatistik_kartlar.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';

class AntrenorIstatistikKartlar extends StatelessWidget {
  final AntrenorIstatistik data;

  const AntrenorIstatistikKartlar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Toplam',
            value: data.toplamAntrenor.toString(),
            ton: ListeTonu.bilgi,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Aktif',
            value: data.aktifAntrenor.toString(),
            ton: ListeTonu.basari,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Bugün Ders',
            value: data.bugunToplamDers.toString(),
            ton: ListeTonu.vurgu,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Ort. Puan',
            value: data.ortalamaPuan?.toStringAsFixed(1) ?? '-',
            // Antrenör satırındaki puan hücresiyle aynı ton ve yıldız.
            ton: ListeTonu.uyari,
            icon: Icons.star_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;

  /// Sayının tonu — sabit renk değil: eski mavi/yeşil/turuncu/amber açık
  /// zeminde eşiğin altında kalıyordu ve takım temasını izlemiyordu.
  final ListeTonu ton;
  final IconData? icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.ton,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = ton.on(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
