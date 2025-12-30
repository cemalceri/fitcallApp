import 'package:flutter/material.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/standalone_notification_page.dart';

class NotificationRouter {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationRouter({required this.navigatorKey});

  Future<void> routeFromFCMData(
      BuildContext? context, Map<String, dynamic> data) async {
    final notification = NotificationModel.fromFCMData(data);
    _openStandalonePage(notification);
  }

  Future<void> route(
      BuildContext? context, NotificationModel notification) async {
    _openStandalonePage(notification);
  }

  void _openStandalonePage(NotificationModel notification) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.push(MaterialPageRoute(
      builder: (_) => StandaloneNotificationPage(notification: notification),
    ));
  }
}
