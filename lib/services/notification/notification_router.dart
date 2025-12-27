// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/notification/notification_handler.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';

class NotificationRouter {
  final Map<String, NotificationHandler> _handlers;

  NotificationRouter({required GlobalKey<NavigatorState> navigatorKey})
      : _handlers = {
          ActionType.navigateToScreen: NavigateToScreenHandler(navigatorKey),
          ActionType.openDialog: OpenDialogHandler(),
          ActionType.refreshData: NoActionHandler(),
          ActionType.noAction: NoActionHandler(),
        };

  Future<void> route(
      BuildContext? context, NotificationModel notification) async {
    final handler = _handlers[notification.actionType] ?? NoActionHandler();
    await handler.handle(context, notification);
  }

  Future<void> routeFromFCMData(
      BuildContext? context, Map<String, dynamic> data) async {
    Map<String, dynamic>? actionParams;
    try {
      final actionParamsRaw = data['action_params'];
      if (actionParamsRaw is String && actionParamsRaw.isNotEmpty) {
        actionParams = Map<String, dynamic>.from(jsonDecode(actionParamsRaw));
      } else if (actionParamsRaw is Map) {
        actionParams = Map<String, dynamic>.from(actionParamsRaw);
      }
    } catch (e) {
      actionParams = null;
    }

    final isLoggedIn = await StorageService.tokenGecerliMi();

    if (!isLoggedIn) {
      await PendingActionStore.instance.set(PendingAction(
        notificationId:
            int.tryParse(data['notification_id']?.toString() ?? '0') ?? 0,
        title: data['title']?.toString() ?? 'Bildirim',
        body: data['body']?.toString() ?? '',
        actionType: data['action_type']?.toString() ?? ActionType.noAction,
        actionScreen: data['action_screen']?.toString(),
        actionParams: actionParams,
      ));
      return;
    }

    try {
      final notification = NotificationModel(
        id: int.tryParse(data['notification_id']?.toString() ?? '0') ?? 0,
        notificationType: data['notification_type']?.toString() ?? '',
        title: data['title']?.toString() ?? 'Bildirim',
        body: data['body']?.toString() ?? '',
        actionType: data['action_type']?.toString() ?? ActionType.noAction,
        actionScreen: data['action_screen']?.toString(),
        actionParams: actionParams,
        isRead: false,
        timestamp: DateTime.now(),
      );
      await route(context, notification);
    } catch (e) {
      // Parse hatası
    }
  }
}
