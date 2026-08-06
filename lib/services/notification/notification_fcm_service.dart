import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fitcall/services/notification/app_badge_service.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:fitcall/services/notification/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationFCMService.instance.setupFlutterNotifications();
  // Uygulama kapalı/arka planda: token'a erişip sunucudaki gerçek sayıyı
  // sormak yerine saklanan sayaç bir artırılır. Uygulama açılınca
  // refreshUnreadCount gerçek değeri yazar.
  final rozet = await AppBadgeService.artir();
  await NotificationFCMService.instance
      .showNotification(message, rozetSayisi: rozet);
}

class NotificationFCMService {
  NotificationFCMService._();
  static final NotificationFCMService instance = NotificationFCMService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Login sayfasının auto-login tetiklemesini yönetmek için.
  /// `true` iken bildirim cache'de var veya dialog açık.
  /// `false` olunca (kullanıcı dialog'u kapatınca) auto-login serbest.
  final ValueNotifier<bool> hasPendingNotification = ValueNotifier(false);

  NotificationRouter? _router;
  bool _isInitialized = false;
  RemoteMessage? _initialMessage;
  Map<String, dynamic>? _pendingNotificationData;

  void registerNavigatorKey(GlobalKey<NavigatorState> key) {
    _router = NotificationRouter(navigatorKey: key);
  }

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await setupFlutterNotifications();
    await _cacheInitialMessage();
    _setupMessageHandlers();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> setupFlutterNotifications() async {
    if (_isInitialized) return;

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
    const initDarwin = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: initAndroid, iOS: initDarwin);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  /// Uygulama kapalıyken gelen bildirimi cache'le
  Future<void> _cacheInitialMessage() async {
    _initialMessage = await _messaging.getInitialMessage();
    if (_initialMessage != null) {
      hasPendingNotification.value = true;
    }
  }

  /// Navigator hazır olduktan sonra çağrılacak
  Future<void> handleInitialMessage() async {
    // Önce pending local notification varsa işle
    if (_pendingNotificationData != null) {
      await _processNotificationData(_pendingNotificationData!);
      _pendingNotificationData = null;
      return;
    }

    // Sonra FCM initial message varsa işle
    if (_initialMessage != null) {
      await _handleRemoteMessage(_initialMessage!);
      _initialMessage = null;
    }
  }

  /// [rozetSayisi] > 0 ise Android bildirimine okunmamış adedi iliştirilir;
  /// launcher simge rozetini bu değerden okur.
  Future<void> showNotification(RemoteMessage message,
      {int rozetSayisi = 0}) async {
    final notification = message.notification;
    final android = notification?.android;

    if (notification != null && android != null) {
      final payloadData = {
        ...message.data,
        'title': notification.title ?? '',
        'body': notification.body ?? '',
      };

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            number: rozetSayisi > 0 ? rozetSayisi : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(payloadData),
      );
    }
  }

  void _setupMessageHandlers() {
    // Uygulama açıkken gelen bildirimler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklanınca (uygulama arka planda)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
  }

  /// Uygulama önplandayken gelen bildirim: sunucudaki gerçek okunmamış sayısı
  /// alınabildiği için rozet ondan beslenir.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final rozet = await _okunmamisSayisiniTazele();
    await showNotification(message, rozetSayisi: rozet);
  }

  Future<int> _okunmamisSayisiniTazele() async {
    try {
      // refreshUnreadCount rozeti de senkronlar.
      final res = await NotificationService.refreshUnreadCount();
      return res.data ?? NotificationService.unreadCount.value;
    } catch (_) {
      // Ağ/oturum sorunu: sayaç en azından bir artırılır.
      return AppBadgeService.artir();
    }
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    hasPendingNotification.value = true;
    final fullData = {
      ...message.data,
      'title': message.notification?.title ?? 'Bildirim',
      'body': message.notification?.body ?? '',
    };
    await _processNotificationData(fullData);
  }

  void _onNotificationResponse(NotificationResponse details) async {
    if (details.payload == null) return;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(details.payload!));

      hasPendingNotification.value = true;

      // Router henüz hazır değilse beklet
      if (_router == null) {
        _pendingNotificationData = data;
        return;
      }

      await _processNotificationData(data);
    } catch (_) {}
  }

  Future<void> _processNotificationData(Map<String, dynamic> data) async {
    // Router hazır olana kadar bekle
    if (_router == null) {
      _pendingNotificationData = data;
      return;
    }

    // Navigator state hazır olana kadar kısa bekle
    await _waitForNavigator();

    await _router!.routeFromFCMData(null, data);
  }

  Future<void> _waitForNavigator() async {
    int attempts = 0;
    while (_router?.navigatorKey.currentState == null && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  /// Bildirim dialog'u kapandığında router tarafından çağrılır.
  /// Pending flag'i temizler, dinleyenler (örn. LoginPage) auto-login'i tetikler.
  void notifyDismissed() {
    hasPendingNotification.value = false;
  }
}
