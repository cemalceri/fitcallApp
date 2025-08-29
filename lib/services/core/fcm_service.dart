// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_exception.dart';

/// Cihazı kaydeder/günceller.
/// [isMainAccount]: Giriş yapan kullanıcının bu üyenin ana hesabı olup olmadığı.
Future<void> sendFCMDevice({required bool isMainAccount}) async {
  // Web'de FCM cihaz kaydı yapmıyoruz
  if (kIsWeb) return;

  final messaging = FirebaseMessaging.instance;

  // --- iOS özel akış: izin + APNs kontrolü + simülatör koruması ---
  if (Platform.isIOS) {
    // Bildirim izni iste (kullanıcı reddederse çık)
    final perm = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (perm.authorizationStatus == AuthorizationStatus.denied) {
      print('[FCM] iOS: bildirim izni reddedildi, kayıt atlandı.');
      return;
    }

    // Simülatörde APNs token gelmez -> hatayı önlemek için atla
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    final isPhysical = iosInfo.isPhysicalDevice;
    if (!isPhysical) {
      print('[FCM] iOS Simulator: APNs token yok, kayıt atlandı.');
      return;
    }

    // Fiziksel cihazda APNs token hazır mı?
    final apns = await messaging.getAPNSToken();
    if (apns == null) {
      print('[FCM] iOS: APNs token henüz hazır değil, sonra tekrar denenecek.');
      return; // İstersen burada gecikmeli retry kurgulayabilirsin.
    }
  }

  // --- FCM token al ---
  String? fcmToken;
  try {
    fcmToken = await messaging
        .getToken(); // iOS'ta APNs hazır değilse hata atıyordu; yukarıda önledik.
  } catch (e) {
    print('[FCM] getToken hata: $e');
    return;
  }
  if (fcmToken == null || fcmToken.isEmpty) {
    print('[FCM] FCM token null/empty; sonra tekrar denenecek.');
    return;
  }

  // --- Cihaz bilgileri ---
  String deviceId = "unknown_device";
  String deviceModel = "unknown_model";
  String osVersion = "unknown_version";

  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final a = await deviceInfo.androidInfo;
    deviceId = a.id;
    deviceModel = a.model;
    osVersion = a.version.release;
  } else if (Platform.isIOS) {
    final i = await deviceInfo.iosInfo;
    deviceId = i.identifierForVendor ?? "unknown_ios_id";
    deviceModel = i.utsname.machine;
    osVersion = i.systemVersion;
  }

  final deviceType = Platform.isAndroid ? "android" : "ios";

  // --- Sunucuya gönder ---
  final bodyData = {
    "device_id": deviceId,
    "fcm_token": fcmToken,
    "device_type": deviceType,
    "device_model": deviceModel,
    "os_version": osVersion,
    "isMainAccount": isMainAccount,
  };

  try {
    await ApiClient.postParsed<Map<String, dynamic>>(
      cihazKaydetGuncelle,
      bodyData,
      (json) => (json as Map).cast<String, dynamic>(),
      auth: true,
    );
  } on ApiException catch (e) {
    print("FCM cihaz bilgileri gönderilirken API hatası: ${e.message}");
  } catch (e) {
    print("FCM cihaz bilgileri gönderilirken hata oluştu: $e");
  }
}
