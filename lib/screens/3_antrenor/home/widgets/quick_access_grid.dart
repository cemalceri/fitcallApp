// lib/screens/3_antrenor/home/widgets/quick_access_grid.dart

import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  static final List<_QuickAccessItem> _items = [
    _QuickAccessItem(
      route: routeEnums[SayfaAdi.antrenorProfil]!,
      icon: Icons.person_outline_rounded,
      text: 'Bilgilerim',
      color: const Color(0xFF6366F1),
    ),
    _QuickAccessItem(
      route: routeEnums[SayfaAdi.antrenorOgrenciler]!,
      icon: Icons.groups_outlined,
      text: 'Öğrencilerim',
      color: const Color(0xFF10B981),
    ),
    _QuickAccessItem(
      route: routeEnums[SayfaAdi.antrenorDersler]!,
      icon: Icons.sports_tennis_rounded,
      text: 'Derslerim',
      color: const Color(0xFFF59E0B),
    ),
    _QuickAccessItem(
      route: routeEnums[SayfaAdi.qrKodKayit]!,
      icon: Icons.qr_code_rounded,
      text: 'QR Giriş',
      color: const Color(0xFF8B5CF6),
    ),
    _QuickAccessItem(
      route: routeEnums[SayfaAdi.yardim]!,
      icon: Icons.help_outline_rounded,
      text: 'Yardım',
      color: const Color(0xFF64748B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _QuickAccessCard(
              item: item,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, item.route);
              },
            );
          },
        ),
      ],
    );
  }
}

class _QuickAccessItem {
  final String route;
  final IconData icon;
  final String text;
  final Color color;

  const _QuickAccessItem({
    required this.route,
    required this.icon,
    required this.text,
    required this.color,
  });
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickAccessItem item;
  final VoidCallback onTap;

  const _QuickAccessCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
