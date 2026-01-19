// lib/screens/7_yonetici/dashboard/widgets/quick_access_section.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickAccessSection extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onRaporlarTap;
  final VoidCallback? onAntrenorTap;
  final VoidCallback? onDerslerTap;

  const QuickAccessSection({
    super.key,
    required this.data,
    this.onRaporlarTap,
    this.onAntrenorTap,
    this.onDerslerTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'HIZLI ERİŞİM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _QuickAccessItem(
          title: 'Detaylı Raporlar',
          subtitle: 'Ciro, doluluk, performans',
          icon: Icons.bar_chart_rounded,
          iconColor: Colors.indigo,
          onTap: onRaporlarTap,
        ),
        const SizedBox(height: 10),
        _QuickAccessItem(
          title: 'Antrenör Performans',
          subtitle:
              'Günlük: ${data.hizliErisimAntrenor.gunlukTamamlananDers} ders tamamlandı',
          icon: Icons.sports_tennis,
          iconColor: Colors.teal,
          onTap: onAntrenorTap,
        ),
        const SizedBox(height: 10),
        _QuickAccessItem(
          title: 'Bugünün Dersleri',
          subtitle:
              '${data.hizliErisimDersler.toplamDers} ders • ${data.hizliErisimDersler.onayBekleyen} onay bekliyor',
          icon: Icons.event_note,
          iconColor: Colors.orange,
          onTap: onDerslerTap,
          badge: data.hizliErisimDersler.onayBekleyen > 0
              ? data.hizliErisimDersler.onayBekleyen
              : null,
        ),
      ],
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final int? badge;

  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
