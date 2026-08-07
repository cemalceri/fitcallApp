// lib/screens/3_antrenor/home/widgets/antrenor_drawer.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/3_antrenor/calisma_saatleri/calisma_saatleri_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Antrenör ana sayfasının sol menüsü (hamburger drawer).
///
/// Alt bardaki sayfaların tümü + bara sığmayan sayfalar; en altta Yardım.
/// Üye/yönetici drawer'ıyla aynı mantık.
class AntrenorDrawer extends StatelessWidget {
  final String antrenorAdi;

  const AntrenorDrawer({super.key, required this.antrenorAdi});

  void _git(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    Navigator.pop(context); // drawer'ı kapat
    Navigator.pushNamed(context, route);
  }

  /// Çalışma saatleri named route'a bağlı değil; profil sayfasındaki gibi
  /// doğrudan açılır.
  void _calismaSaatleri(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalismaSaatleriPage()),
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
                    child: Icon(Icons.sports_tennis_rounded,
                        color: colorScheme.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          antrenorAdi.isNotEmpty
                              ? antrenorAdi
                              : 'Antrenör Menüsü',
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
                    icon: Icons.calendar_month_rounded,
                    title: 'Takvim (Derslerim)',
                    color: const Color(0xFFF59E0B),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.antrenorDersler]!),
                  ),
                  _DrawerItem(
                    icon: Icons.groups_rounded,
                    title: 'Öğrencilerim',
                    color: const Color(0xFF10B981),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.antrenorOgrenciler]!),
                  ),
                  _DrawerItem(
                    icon: Icons.qr_code_rounded,
                    title: 'QR Giriş',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_rounded,
                    title: 'Eksik Yoklamalar',
                    color: const Color(0xFF14B8A6),
                    onTap: () => _git(
                        context, routeEnums[SayfaAdi.antrenorEksikYoklama]!),
                  ),
                  _DrawerItem(
                    icon: Icons.schedule_rounded,
                    title: 'Çalışma Saatlerim',
                    color: const Color(0xFF0EA5E9),
                    onTap: () => _calismaSaatleri(context),
                  ),
                  _DrawerItem(
                    icon: Icons.access_time_filled_rounded,
                    title: 'Hakediş Saatlerim',
                    color: const Color(0xFF0D9488),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.antrenorHakedis]!),
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Bilgilerim (Profil)',
                    color: const Color(0xFF6366F1),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.antrenorProfil]!),
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
