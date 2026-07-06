// lib/screens/2_uye/home/widgets/uye_menu_grid.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menü item modeli
class UyeMenuItem {
  final String route;
  final IconData icon;
  final String text;
  final Color color;
  final bool isEventButton;

  const UyeMenuItem({
    required this.route,
    required this.icon,
    required this.text,
    required this.color,
    this.isEventButton = false,
  });
}

/// Hızlı erişim menü grid'i
class UyeMenuGrid extends StatelessWidget {
  final EventModel? aktifEvent;
  final int? userId;
  final VoidCallback? onEventReturn;

  const UyeMenuGrid({
    super.key,
    this.aktifEvent,
    this.userId,
    this.onEventReturn,
  });

  /// Temel menü öğeleri
  static final List<UyeMenuItem> _baseMenuItems = [
    UyeMenuItem(
      route: routeEnums[SayfaAdi.profil]!,
      icon: Icons.person_outline_rounded,
      text: 'Bilgilerim',
      color: Color(0xFF6366F1),
    ),
    UyeMenuItem(
      route: routeEnums[SayfaAdi.muhasebe]!,
      icon: Icons.account_balance_wallet_outlined,
      text: 'Hesabım',
      color: Color(0xFF10B981),
    ),
    UyeMenuItem(
      route: routeEnums[SayfaAdi.dersler]!,
      icon: Icons.calendar_month_outlined,
      text: 'Takvim',
      color: Color(0xFFF59E0B),
    ),
    UyeMenuItem(
      route: routeEnums[SayfaAdi.uyeGecmisDersler]!,
      icon: Icons.history_rounded,
      text: 'Geçmiş Dersler',
      color: Color(0xFF14B8A6),
    ),
    UyeMenuItem(
      route: routeEnums[SayfaAdi.qrKodKayit]!,
      icon: Icons.qr_code_rounded,
      text: 'QR Giriş',
      color: Color(0xFF8B5CF6),
    ),
    UyeMenuItem(
      route: routeEnums[SayfaAdi.yardim]!,
      icon: Icons.help_outline_rounded,
      text: 'Yardım',
      color: Color(0xFF64748B),
    ),
  ];

  /// Aktif event'e göre filtrelenmiş menü öğeleri
  List<UyeMenuItem> get _menuItems {
    final items = <UyeMenuItem>[];

    for (final item in _baseMenuItems) {
      // QR Giriş gizlenmesi gerekiyorsa atla
      if (aktifEvent != null &&
          !aktifEvent!.qrGirisGosterilsinMi &&
          item.route == '/qr-kod-kayit') {
        continue;
      }
      items.add(item);
    }

    // Event/Davet butonu ekle
    if (aktifEvent != null && aktifEvent!.eventDavetGosterilsinMi) {
      items.insert(
        3,
        const UyeMenuItem(
          route: '',
          icon: Icons.celebration_outlined,
          text: 'Event/Davet',
          color: Color(0xFF2E7D6B),
          isEventButton: true,
        ),
      );
    }

    return items;
  }

  void _onItemTap(BuildContext context, UyeMenuItem item) {
    HapticFeedback.lightImpact();

    if (item.isEventButton && userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventQrPage(userId: userId!),
        ),
      ).then((_) => onEventReturn?.call());
    } else {
      Navigator.pushNamed(context, item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = _menuItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
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

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _MenuCard(
              item: item,
              onTap: () => _onItemTap(context, item),
            );
          },
        ),
      ],
    );
  }
}

/// Tek menü kartı
class _MenuCard extends StatelessWidget {
  final UyeMenuItem item;
  final VoidCallback onTap;

  const _MenuCard({
    required this.item,
    required this.onTap,
  });

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
              // İkon container
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
              // Metin
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
