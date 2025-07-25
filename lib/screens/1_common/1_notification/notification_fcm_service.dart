// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/* -------------------------------------------------- */

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  /* ------------------ Local kanal ------------------ */
  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'High importance notifications channel.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initDarwin = DarwinInitializationSettings();
    final initSettings =
        InitializationSettings(android: initAndroid, iOS: initDarwin);

    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: (details) {});
    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    final not = message.notification;
    final android = message.notification?.android;
    if (not != null && android != null) {
      await _localNotifications.show(
        not.hashCode,
        not.title,
        not.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /* ------------------ Mesaj Handlers ------------------ */
  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_cacheForLater);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) await _cacheForLater(initial);
  }

  /* ----------------------------------------------------
     Bildirim tıklandığında → pendingActionStore.set(...)
     App login’liyse ayrıca hemen push da yap
  ---------------------------------------------------- */
  Future<void> _cacheForLater(RemoteMessage message) async {
    PendingAction action;

    if (message.data['notification_type'] == 'DO' &&
        message.data['model_name'] == 'EtkinlikModel' &&
        message.data['model_own_id'] != null) {
      action = PendingAction(
        type: PendingActionType.dersTeyit,
        data: message.data,
      );
    } else {
      action = PendingAction(
        type: PendingActionType.bildirimListe,
        data: message.data,
      );
    }
    await PendingActionStore.instance.set(action);
  }
}
