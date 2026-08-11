// lib/screens/3_antrenor/home/widgets/antrenor_drawer.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/yan_menu.dart';
import 'package:fitcall/screens/3_antrenor/calisma_saatleri/calisma_saatleri_page.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Antrenör kabuğunun sol menüsü.
///
/// Alt bardaki sekmeler (Ana Sayfa · Takvim · QR · Öğrenciler · Bilgilerim)
/// burada tekrarlanmaz; drawer bara sığmayan sayfaları taşır.
class AntrenorDrawer extends StatelessWidget {
  final String antrenorAdi;

  const AntrenorDrawer({super.key, required this.antrenorAdi});

  void _git(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    Navigator.pop(context); // drawer'ı kapat
    Navigator.pushNamed(context, route);
  }

  /// Çalışma saatleri named route'a bağlı değil; doğrudan açılır.
  void _calismaSaatleri(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalismaSaatleriPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            YanMenuBasligi(
              ad: antrenorAdi.isNotEmpty ? antrenorAdi : 'Antrenör Menüsü',
              altBaslik: 'Menü',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const YanMenuBolumu('Derslerim'),
                  YanMenuOgesi(
                    ikon: Icons.fact_check_rounded,
                    baslik: 'Eksik Yoklamalar',
                    onTap: () => _git(
                        context, routeEnums[SayfaAdi.antrenorEksikYoklama]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.schedule_rounded,
                    baslik: 'Çalışma Saatlerim',
                    onTap: () => _calismaSaatleri(context),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.access_time_filled_rounded,
                    baslik: 'Hakediş Saatlerim',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.antrenorHakedis]!),
                  ),
                  const YanMenuBolumu('Genel'),
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService.unreadCount,
                    builder: (context, adet, _) => YanMenuOgesi(
                      ikon: Icons.notifications_rounded,
                      baslik: 'Bildirimler',
                      rozet: adet,
                      onTap: () =>
                          _git(context, routeEnums[SayfaAdi.bildirimler]!),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            YanMenuOgesi(
              ikon: Icons.help_outline_rounded,
              baslik: 'Yardım',
              onTap: () => _git(context, routeEnums[SayfaAdi.antrenorYardim]!),
            ),
            YanMenuOgesi(
              ikon: Icons.settings_outlined,
              baslik: 'Ayarlar',
              onTap: () => _git(context, routeEnums[SayfaAdi.ayarlar]!),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
