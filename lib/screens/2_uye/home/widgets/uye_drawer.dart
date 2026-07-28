import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Üye ana sayfasının sol menüsü (hamburger drawer).
///
/// Alt bardaki sayfaların tümü + ek sayfalar; en altta Yardım.
class UyeDrawer extends StatelessWidget {
  final String uyeAdi;
  final EventModel? aktifEvent;
  final int? userId;
  final VoidCallback? onEventReturn;

  const UyeDrawer({
    super.key,
    required this.uyeAdi,
    this.aktifEvent,
    this.userId,
    this.onEventReturn,
  });

  void _git(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    Navigator.pop(context); // drawer'ı kapat
    Navigator.pushNamed(context, route);
  }

  void _eventAc(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventQrPage(userId: userId!)),
    ).then((_) => onEventReturn?.call());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final eventGoster = aktifEvent != null &&
        aktifEvent!.eventDavetGosterilsinMi &&
        userId != null;

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
                          uyeAdi.isNotEmpty ? uyeAdi : 'Üyelik Menüsü',
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
                    onTap: () => _git(context, routeEnums[SayfaAdi.dersler]!),
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Geçmiş Dersler',
                    color: const Color(0xFF14B8A6),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.uyeGecmisDersler]!),
                  ),
                  _DrawerItem(
                    icon: Icons.qr_code_rounded,
                    title: 'QR Giriş',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
                  ),
                  _DrawerItem(
                    icon: Icons.card_membership_rounded,
                    title: 'Üyelik/Paket Bilgilerim',
                    color: const Color(0xFF6366F1),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.uyelikPaket]!),
                  ),
                  _DrawerItem(
                    icon: Icons.event_repeat_rounded,
                    title: 'Telafi Derslerim',
                    color: const Color(0xFF0EA5E9),
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.telafiHaklari]!),
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Hesabım (Profil)',
                    color: const Color(0xFF10B981),
                    onTap: () => _git(context, routeEnums[SayfaAdi.profil]!),
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Hesap Hareketleri',
                    color: const Color(0xFF059669),
                    onTap: () => _git(context, routeEnums[SayfaAdi.muhasebe]!),
                  ),
                  if (eventGoster)
                    _DrawerItem(
                      icon: Icons.celebration_rounded,
                      title: 'Event / Davet',
                      color: const Color(0xFF2E7D6B),
                      onTap: () => _eventAc(context),
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
