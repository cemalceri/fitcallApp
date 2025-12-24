import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

/// Uygulama başlangıcında bir kez çağrılır (main.dart veya app init)
void initFCMTokenListener() {
  if (kIsWeb) return;

  // Token yenilendiğinde otomatik sunucuya gönder
  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
    (fcmToken) async {
      await _sendTokenToServer(fcmToken);
    },
    onError: (err) {},
  );
}

/// Listener'ı temizle (logout veya dispose)
void disposeFCMTokenListener() {
  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

/// Login sonrası çağrılır
Future<void> sendFCMDevice() async {
  if (kIsWeb) return;

  final messaging = FirebaseMessaging.instance;

  // iOS: izin iste
  if (Platform.isIOS) {
    final perm = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (perm.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Simülatör kontrolü
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    if (!iosInfo.isPhysicalDevice) {
      return;
    }

    // APNs token kontrolü - null ise onTokenRefresh beklenecek
    final apns = await messaging.getAPNSToken();
    if (apns == null) {
      // Return etme, getToken() dene - belki hazırdır
    }
  }

  // FCM token al
  String? fcmToken;
  try {
    fcmToken = await messaging.getToken();
  } catch (e) {
    // iOS'ta APNs hazır değilse hata atar, onTokenRefresh ile gelecek
    return;
  }

  if (fcmToken == null || fcmToken.isEmpty) {
    return;
  }

  await _sendTokenToServer(fcmToken);
}

/// Token'ı sunucuya gönder
Future<void> _sendTokenToServer(String fcmToken) async {
  // Cihaz bilgileri
  String deviceId = "unknown";
  String deviceModel = "unknown";
  String osVersion = "unknown";
  String deviceType = "android";

  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final a = await deviceInfo.androidInfo;
    deviceId = a.id;
    deviceModel = a.model;
    osVersion = a.version.release;
    deviceType = "android";
  } else if (Platform.isIOS) {
    final i = await deviceInfo.iosInfo;
    deviceId = i.identifierForVendor ?? "unknown_ios";
    deviceModel = i.utsname.machine;
    osVersion = i.systemVersion;
    deviceType = "ios";
  }

  final bodyData = {
    "device_id": deviceId,
    "fcm_token": fcmToken,
    "device_type": deviceType,
    "device_model": deviceModel,
    "os_version": osVersion,
  };

  try {
    await ApiClient.postParsed<Map<String, dynamic>>(
      cihazKaydetGuncelle,
      bodyData,
      (json) => (json as Map).cast<String, dynamic>(),
      auth: true,
    );
  } catch (_) {}
}
