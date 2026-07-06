import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/pages/bildirim_detay_sheet.dart';
import 'package:fitcall/screens/1_common/1_notification/pages/ders_teyit_bildirim_page.dart';
import 'package:fitcall/screens/1_common/1_notification/pages/ders_devir_bildirim_page.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:flutter/material.dart';

class NotificationRouter {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationRouter({required this.navigatorKey});

  Future<void> routeFromFCMData(
      BuildContext? context, Map<String, dynamic> data) async {
    final notification = NotificationModel.fromFCMData(data);
    await _open(notification);
  }

  Future<void> route(
      BuildContext? context, NotificationModel notification) async {
    await _open(notification);
  }

  Future<void> _open(NotificationModel notification) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      NotificationFCMService.instance.notifyDismissed();
      return;
    }

    final ctx = nav.context;

    // 1) Ders devir teklifi
    final talepId = _talepIdOf(notification);
    if (_isDevirTeklifi(notification) && talepId != null) {
      final token = notification.actionToken;
      await _openFullscreen(
        ctx,
        DersDevirBildirimPage(
          actionToken: (token != null && token.isNotEmpty) ? token : null,
          talepId: (token == null || token.isEmpty) ? talepId : null,
        ),
      );
      NotificationFCMService.instance.notifyDismissed();
      return;
    }

    // 2) Ders teyidi
    if (_isDersTeyit(notification)) {
      await _openFullscreen(
        ctx,
        DersTeyitBildirimPage(notification: notification),
      );
      NotificationFCMService.instance.notifyDismissed();
      return;
    }

    // 3) Yoklama hatırlatma (antrenöre): takvimde ilgili günü aç, dialogu göster
    if (_isYoklamaHatirlatma(notification)) {
      final params = notification.actionParams;
      nav.pushNamed(
        routeEnums[SayfaAdi.antrenorDersler]!,
        arguments: {
          if (params?['tarih'] != null) 'tarih': params!['tarih'],
          if (params?['ders_id'] != null) 'ders_id': params!['ders_id'],
        },
      );
      NotificationFCMService.instance.notifyDismissed();
      return;
    }

    // 4) Default: bildirim detay sheet
    await BildirimDetaySheetWidget.goster(
        context: ctx, notification: notification);
    NotificationFCMService.instance.notifyDismissed();
  }

  /* -------------------------------- HELPERS ------------------------------- */

  Future<void> _openFullscreen(BuildContext context, Widget child) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Dialog.fullscreen(child: child),
    );
  }

  /// Devir teklifi mi?
  /// `notification_type` terminated state'te eksik gelebildiği için
  /// `actionScreen` da fallback olarak kontrol ediliyor.
  bool _isDevirTeklifi(NotificationModel n) {
    return n.notificationType == NotificationType.antrenorDevirTeklifi ||
        n.actionScreen == 'ders_devir_teklifi';
  }

  /// Ders teyidi mi?
  bool _isDersTeyit(NotificationModel n) {
    return n.notificationType == NotificationType.dersTeyidi ||
        n.actionScreen == 'ders_teyit';
  }

  /// Antrenöre yoklama hatırlatması mı?
  bool _isYoklamaHatirlatma(NotificationModel n) {
    return n.notificationType == NotificationType.yoklamaHatirlatma ||
        n.actionScreen == 'antrenor_yoklama';
  }

  int? _talepIdOf(NotificationModel n) {
    final v = n.displayData?['devir_talebi_id'];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
