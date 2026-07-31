// lib/screens/7_yonetici/widgets/yonetici_drawer.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/borclu_uyeler_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici ana kabuğunun sol menüsü (hamburger drawer).
///
/// Alt bardaki 4 sekme + bara sığmayan Dersler/Program sekmeleri + bar dışı
/// sayfalar; en altta Yardım. Üye drawer'ıyla aynı mantık.
class YoneticiDrawer extends StatelessWidget {
  final String yoneticiAdi;

  /// Sekme değiştirir (YoneticiMainPage sıralaması).
  final ValueChanged<int> onTabSelected;

  const YoneticiDrawer({
    super.key,
    required this.yoneticiAdi,
    required this.onTabSelected,
  });

  void _sekme(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    Navigator.pop(context); // drawer'ı kapat
    onTabSelected(index);
  }

  void _git(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _borcluUyeler(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BorcluUyelerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.shield_rounded,
                        color: colorScheme.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          yoneticiAdi.isNotEmpty
                              ? yoneticiAdi
                              : 'Yönetici Menüsü',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Hızlı erişim',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Menü öğeleri
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    color: const Color(0xFF6366F1),
                    onTap: () => _sekme(context, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Raporlar',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => _sekme(context, 1),
                  ),
                  _DrawerItem(
                    icon: Icons.people_rounded,
                    title: 'Üyeler',
                    color: const Color(0xFF10B981),
                    onTap: () => _sekme(context, 2),
                  ),
                  _DrawerItem(
                    icon: Icons.sports_tennis_rounded,
                    title: 'Antrenörler',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _sekme(context, 3),
                  ),
                  _DrawerItem(
                    icon: Icons.event_rounded,
                    title: 'Dersler',
                    color: const Color(0xFFEC4899),
                    onTap: () => _sekme(context, 4),
                  ),
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Haftalık Program',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _sekme(context, 5),
                  ),
                  const Divider(height: 16, indent: 16, endIndent: 16),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Borçlu Üyeler',
                    color: const Color(0xFFEF4444),
                    onTap: () => _borcluUyeler(context),
                  ),
                  _DrawerItem(
                    icon: Icons.qr_code_rounded,
                    title: 'QR Oluştur',
                    color: const Color(0xFF6366F1),
                    onTap: () => _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
                  ),
                  _DrawerItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QR Doğrula',
                    color: const Color(0xFF14B8A6),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.qrKodDogrula]!),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_rounded,
                    title: 'Bildirimler',
                    color: const Color(0xFF3B82F6),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.bildirimler]!),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.help_outline_rounded,
              title: 'Yardım',
              color: const Color(0xFF64748B),
              onTap: () => _git(context, routeEnums[SayfaAdi.yardim]!),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}
