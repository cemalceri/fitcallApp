import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:fitcall/screens/1_common/widgets/yan_menu.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Üye kabuğunun sol menüsü.
///
/// Alt bardaki sekmeler burada tekrarlanmaz (Ana Sayfa · Takvim · QR ·
/// Hareketler · Hesabım): drawer yalnız bara sığmayan sayfaları taşır.
/// Aynı satırı iki yerde göstermek menüyü uzatıp hangi yolun "asıl" olduğunu
/// belirsizleştiriyordu.
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
    final eventGoster = aktifEvent != null &&
        aktifEvent!.eventDavetGosterilsinMi &&
        userId != null;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            YanMenuBasligi(
              ad: uyeAdi.isNotEmpty ? uyeAdi : 'Üyelik Menüsü',
              altBaslik: 'Menü',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const YanMenuBolumu('Üyeliğim'),
                  YanMenuOgesi(
                    ikon: Icons.card_membership_rounded,
                    baslik: 'Üyelik & Paket Bilgilerim',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.uyelikPaket]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.event_repeat_rounded,
                    baslik: 'Telafi Derslerim',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.telafiHaklari]!),
                  ),
                  YanMenuOgesi(
                    ikon: Icons.history_rounded,
                    baslik: 'Geçmiş Dersler',
                    onTap: () =>
                        _git(context, routeEnums[SayfaAdi.uyeGecmisDersler]!),
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
                  if (eventGoster)
                    YanMenuOgesi(
                      ikon: Icons.celebration_rounded,
                      baslik: 'Event / Davet',
                      onTap: () => _eventAc(context),
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
