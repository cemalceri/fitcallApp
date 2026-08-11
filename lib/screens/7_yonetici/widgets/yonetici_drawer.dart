// lib/screens/7_yonetici/widgets/yonetici_drawer.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/yan_menu.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/borclu_uyeler_page.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici ana kabuğunun sol menüsü.
///
/// Dersler ve Haftalık Program alt bara sığmadığı için burada, kendi
/// "Ders yönetimi" bölümünde en üstte duruyor. Alt bardaki sekmeler de
/// listede — hangisinde olunduğu aktif satırla belli olur; drawer yöneticinin
/// tüm ekranlarına açılan tek dizin.
class YoneticiDrawer extends StatelessWidget {
  final String yoneticiAdi;

  /// Sekme değiştirir (YoneticiMainPage sıralaması).
  final ValueChanged<int> onTabSelected;

  /// Aktif sekme — menüde işaretlenir.
  final int aktifSekme;

  const YoneticiDrawer({
    super.key,
    required this.yoneticiAdi,
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

  void _borcluUyeler(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BorcluUyelerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            YanMenuBasligi(
              ad: yoneticiAdi.isNotEmpty ? yoneticiAdi : 'Yönetici Menüsü',
              altBaslik: 'Yönetim menüsü',
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
                    aktif: aktifSekme == 5,
                    onTap: () => _sekme(context, 5),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.event_rounded,
                    baslik: 'Dersler',
                    aktif: aktifSekme == 4,
                    onTap: () => _sekme(context, 4),
                  ),
                  const YanMenuBolumu('Panolar'),
                  YanMenuOgesi(
                    ikon: Icons.dashboard_rounded,
                    baslik: 'Dashboard',
                    aktif: aktifSekme == 0,
                    onTap: () => _sekme(context, 0),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.bar_chart_rounded,
                    baslik: 'Raporlar',
                    aktif: aktifSekme == 1,
                    onTap: () => _sekme(context, 1),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.people_rounded,
                    baslik: 'Üyeler',
                    aktif: aktifSekme == 2,
                    onTap: () => _sekme(context, 2),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.sports_tennis_rounded,
                    baslik: 'Antrenörler',
                    aktif: aktifSekme == 3,
                    onTap: () => _sekme(context, 3),
                  ),
                  const YanMenuBolumu('İşlemler'),
                  YanMenuOgesi(
                    ikon: Icons.schedule_rounded,
                    baslik: 'Hakediş Saatleri',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.yoneticiHakedis]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.account_balance_wallet_rounded,
                    baslik: 'Borçlu Üyeler',
                    onTap: () => _borcluUyeler(context),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.qr_code_rounded,
                    baslik: 'QR Oluştur',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.qr_code_scanner_rounded,
                    baslik: 'QR Doğrula',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.qrKodDogrula]!),
                  ),
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
              onTap: () => _git(context, routeEnums[SayfaAdi.yardim]!),
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
