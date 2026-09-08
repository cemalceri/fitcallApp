// lib/screens/8_ofis/widgets/ofis_drawer.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/yan_menu.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ofis ana kabuğunun sol menüsü.
///
/// Alt bardaki dört sekme burada da listeleniyor — hangisinde olunduğu aktif
/// satırla belli olur; drawer ofisin tüm ekranlarına açılan tek dizin.
/// Ciro, bakiye, hakediş ve raporlar bilinçli olarak yok: onlar yönetici
/// kabuğunda (bkz. lib/screens/7_yonetici/).
class OfisDrawer extends StatelessWidget {
  final String ofisAdi;

  /// Sekme değiştirir (OfisMainPage sıralaması).
  final ValueChanged<int> onTabSelected;

  /// Aktif sekme — menüde işaretlenir.
  final int aktifSekme;

  const OfisDrawer({
    super.key,
    required this.ofisAdi,
    required this.onTabSelected,
    this.aktifSekme = 0,
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            YanMenuBasligi(
              ad: ofisAdi.isNotEmpty ? ofisAdi : 'Ofis Menüsü',
              altBaslik: 'Ön büro menüsü',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const YanMenuBolumu('Ders yönetimi'),
                  YanMenuOgesi(
                    ikon: Icons.grid_view_rounded,
                    baslik: 'Haftalık Program',
                    aktif: aktifSekme == 0,
                    onTap: () => _sekme(context, 0),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.event_rounded,
                    baslik: 'Dersler',
                    aktif: aktifSekme == 1,
                    onTap: () => _sekme(context, 1),
                  ),
                  const YanMenuBolumu('Üyeler'),
                  YanMenuOgesi(
                    ikon: Icons.people_rounded,
                    baslik: 'Üye Listesi',
                    aktif: aktifSekme == 2,
                    onTap: () => _sekme(context, 2),
                  ),
                  const YanMenuBolumu('İşlemler'),
                  YanMenuOgesi(
                    ikon: Icons.qr_code_scanner_rounded,
                    baslik: 'QR Doğrula',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.qrKodDogrula]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.qr_code_rounded,
                    baslik: 'QR Oluştur',
                    onTap: () => _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService.unreadCount,
                    builder: (context, adet, _) => YanMenuOgesi(
                      ikon: Icons.notifications_rounded,
                      baslik: 'Bildirimler',
                      rozet: adet,
                      aktif: aktifSekme == 3,
                      onTap: () => _sekme(context, 3),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            YanMenuOgesi(
              ikon: Icons.help_outline_rounded,
              baslik: 'Yardım',
              onTap: () => _git(context, routeEnums[SayfaAdi.ofisYardim]!),
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
