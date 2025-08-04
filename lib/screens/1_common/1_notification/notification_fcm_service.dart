// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';

/* -------------------------------------------------- */
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotification(message);
}

/* -------------------------------------------------- */
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isFlutterLocalNotificationsInitialized = false;

  /* ------------ MaterialApp’te kullanılan navigatorKey’i kaydet ------------ */
  void registerNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /* ------------------------------- init ----------------------------------- */
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupMessageHandlers();
    await setupFlutterNotifications();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  /* ------------------ Local kanal/kurulum ------------------ */
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  /* ------------------ Bildirim göster ------------------ */
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
        payload: jsonEncode(message.data), // ← parse edilebilir payload
      );
    }
  }

  /* ------------------ FCM Message Handlers ------------------ */
  Future<void> _setupMessageHandlers() async {
    // Uygulama açıkken mesaj geldi → local bildirim göster
    FirebaseMessaging.onMessage.listen(showNotification);

    // Arka planda iken push’a tıklandı
    FirebaseMessaging.onMessageOpenedApp.listen(_cacheRemoteMessageForLater);

    // Uygulama kapalı iken push’a tıklandı
    final initial = await _messaging.getInitialMessage();
    if (initial != null) await _cacheRemoteMessageForLater(initial);
  }

  /* ---------------------- PendingAction & Navigation ---------------------- */
  Future<void> _cacheRemoteMessageForLater(RemoteMessage message) async {
    await _processNotificationData(message.data);
  }

  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    // 1) PendingAction oluştur
    late final PendingAction action;
    if (data['notification_type'] == 'DO' &&
        data['model_name'] == 'EtkinlikModel' &&
        data['model_own_id'] != null) {
      action = PendingAction(
        type: PendingActionType.dersTeyit,
        data: data,
      );
    } else {
      action = PendingAction(
        type: PendingActionType.bildirimListe,
        data: data,
      );
    }
    await PendingActionStore.instance.set(action);

    // 2) Oturum açıksa hemen yönlendir
    _navigateToAction(action);
  }

  /* ------------ Local bildirim tıklandığında (uygulama açık) -------------- */
  void _onNotificationResponse(NotificationResponse details) async {
    if (details.payload == null) return;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(details.payload!));
      await _processNotificationData(data);
    } catch (_) {
      // Payload parse edilemedi → yoksay
    }
  }

  /* ----------------------- Sayfa yönlendirme ----------------------- */
  void _navigateToAction(PendingAction action) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return; // navigatorKey henüz kaydedilmemiş

    switch (action.type) {
      case PendingActionType.dersTeyit:
        nav.pushNamed(routeEnums[SayfaAdi.dersTeyit]!, arguments: action.data);
        break;
      case PendingActionType.bildirimListe:
        nav.pushNamed(routeEnums[SayfaAdi.bildirimler]!);
        break;
    }
  }
}
