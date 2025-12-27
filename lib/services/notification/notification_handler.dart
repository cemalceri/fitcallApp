import 'package:flutter/material.dart';
import 'package:fitcall/models/notification/notification_model.dart';

abstract class NotificationHandler {
  Future<void> handle(BuildContext? context, NotificationModel notification);
}

class NavigateToScreenHandler implements NotificationHandler {
  final GlobalKey<NavigatorState> navigatorKey;

  NavigateToScreenHandler(this.navigatorKey);

  @override
  Future<void> handle(
      BuildContext? context, NotificationModel notification) async {
    final nav = navigatorKey.currentState;
    if (nav == null || notification.actionScreen == null) return;

    final routeName = _getRouteName(notification.actionScreen!);
    if (routeName == null) return;

    nav.pushNamed(routeName, arguments: notification.actionParams ?? {});
  }

  String? _getRouteName(String actionScreen) {
    final routes = {
      'ders_teyit': '/ders-teyit',
      'odeme_onay': '/odeme-onay',
      'bildirim_detay': '/bildirim-detay',
    };
    return routes[actionScreen];
  }
}

class OpenDialogHandler implements NotificationHandler {
  @override
  Future<void> handle(
      BuildContext? context, NotificationModel notification) async {
    if (context == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }
}

class NoActionHandler implements NotificationHandler {
  @override
  Future<void> handle(
      BuildContext? context, NotificationModel notification) async {
    // Hiçbir şey yapma
  }
}
