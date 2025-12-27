import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitcall/services/notification/notification_router.dart';

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

  NotificationRouter? _router;
  bool _isFlutterLocalNotificationsInitialized = false;

  void registerNavigatorKey(GlobalKey<NavigatorState> key) {
    _router = NotificationRouter(navigatorKey: key);
  }

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers();
    await setupFlutterNotifications();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;
    const channel = AndroidNotificationChannel(
        'high_importance_channel', 'High Importance Notifications',
        description: 'High importance notifications channel.',
        importance: Importance.high);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initDarwin = DarwinInitializationSettings();
    final initSettings =
        InitializationSettings(android: initAndroid, iOS: initDarwin);
    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse);
    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    final not = message.notification;
    final android = message.notification?.android;
    if (not != null && android != null) {
      final payloadData = {
        ...message.data,
        'title': not.title ?? '',
        'body': not.body ?? ''
      };
      await _localNotifications.show(
          not.hashCode,
          not.title,
          not.body,
          const NotificationDetails(
              android: AndroidNotificationDetails(
                  'high_importance_channel', 'High Importance Notifications',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher'),
              iOS: DarwinNotificationDetails()),
          payload: jsonEncode(payloadData));
    }
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) await _handleRemoteMessage(initial);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final fullData = {
      ...message.data,
      'title': message.notification?.title ?? 'Bildirim',
      'body': message.notification?.body ?? ''
    };
    await _router?.routeFromFCMData(null, fullData);
  }

  void _onNotificationResponse(NotificationResponse details) async {
    if (details.payload == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(details.payload!));
      await _router?.routeFromFCMData(null, data);
    } catch (_) {}
  }
}
