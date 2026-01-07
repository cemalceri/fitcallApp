// lib/services/core/fcm_service.dart

import 'dart:async';
import 'dart:io';
import 'package:fitcall/services/core/api_log_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';

StreamSubscription<String>? _tokenRefreshSubscription;

// APNs retry ayarları
const int _apnsMaxRetry = 10;
const Duration _apnsRetryDelay = Duration(seconds: 2);

/// Uygulama başlangıcında bir kez çağrılır (main.dart)
void initFCMTokenListener() {
  if (kIsWeb) return;

  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
    (fcmToken) async {
      final log = LogFlowBuilder('FCMService', 'onTokenRefresh', 24);
      try {
        log.adimEkle('Token yenileme tetiklendi');
        log.bilgiEkle('token_preview', fcmToken.substring(0, 20));

        await _sendTokenToServer(fcmToken);

        await log.basariliGonder('Token sunucuya başarıyla gönderildi');
      } catch (e) {
        await log.hataliGonder('Token yenileme başarısız', e);
      }
    },
    onError: (err) async {
      await mobileLogError(
        'FCMService',
        'onTokenRefresh',
        39,
        'Token refresh listener hatası',
        hata: err,
      );
    },
  );
}

/// Listener'ı temizle (logout veya dispose)
void disposeFCMTokenListener() {
  _tokenRefreshSubscription?.cancel();
  _tokenRefreshSubscription = null;
}

/// Login sonrası çağrılır - Ana FCM kayıt metodu
Future<void> sendFCMDevice() async {
  if (kIsWeb) return;

  final log = LogFlowBuilder('FCMService', 'sendFCMDevice', 57);
  final stopwatch = Stopwatch()..start();

  try {
    log.adimEkle('FCM cihaz kaydı başlatıldı');
    final messaging = FirebaseMessaging.instance;

    // ═══════════════════════════════════════════════════════════
    // iOS PLATFORM KONTROLÜ
    // ═══════════════════════════════════════════════════════════
    if (Platform.isIOS) {
      log.adimEkle('iOS platformu tespit edildi');

      // 1. Bildirim izni iste
      log.adimEkle('Bildirim izni isteniyor');
      final perm = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      log.bilgiEkle('ios_permission', perm.authorizationStatus.toString());

      if (perm.authorizationStatus == AuthorizationStatus.denied) {
        log.adimEkle('Bildirim izni reddedildi');
        await log.basariliGonder('İşlem durduruldu: Kullanıcı izin vermedi');
        return;
      }

      // 2. Simülatör kontrolü
      log.adimEkle('Cihaz tipi kontrol ediliyor');
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      log.bilgiEkle('is_physical_device', iosInfo.isPhysicalDevice);

      if (!iosInfo.isPhysicalDevice) {
        log.adimEkle('Simülatör tespit edildi (APNs desteklenmiyor)');
        await log
            .basariliGonder('İşlem durduruldu: Simülatör APNs desteklemiyor');
        return;
      }

      // 3. APNs token al
      log.adimEkle('APNs token bekleniyor (max $_apnsMaxRetry deneme)');
      final apnsToken = await _waitForApnsToken(messaging);

      if (apnsToken == null) {
        log.adimEkle('APNs token $_apnsMaxRetry denemede alınamadı');
        await log.hataliGonder(
          'APNs token alınamadı, onTokenRefresh ile tekrar denenecek',
          'APNs timeout after $_apnsMaxRetry attempts',
        );
        return;
      }

      log.adimEkle('APNs token başarıyla alındı');
      log.bilgiEkle('apns_token_preview', apnsToken.substring(0, 20));
    } else {
      log.adimEkle('Android platformu tespit edildi');
    }

    // ═══════════════════════════════════════════════════════════
    // FCM TOKEN AL (iOS ve Android ortak)
    // ═══════════════════════════════════════════════════════════
    log.adimEkle('FCM token alınıyor');
    final fcmToken = await messaging.getToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      log.adimEkle('FCM token boş döndü');
      await log.hataliGonder('FCM token alınamadı', 'Token is null or empty');
      return;
    }

    log.adimEkle('FCM token başarıyla alındı');
    log.bilgiEkle('fcm_token_preview', fcmToken.substring(0, 20));

    // ═══════════════════════════════════════════════════════════
    // SUNUCUYA GÖNDER
    // ═══════════════════════════════════════════════════════════
    log.adimEkle('Cihaz bilgileri toplanıyor');
    final deviceInfo = await _collectDeviceInfo();
    log.bilgiEkle('device_type', deviceInfo['device_type']);
    log.bilgiEkle('device_model', deviceInfo['device_model']);
    log.bilgiEkle('os_version', deviceInfo['os_version']);

    log.adimEkle('Backend API çağrısı yapılıyor');
    final bodyData = {
      ...deviceInfo,
      "fcm_token": fcmToken,
    };

    await ApiClient.postParsed<Map<String, dynamic>>(
      cihazKaydetGuncelle,
      bodyData,
      (json) => (json as Map).cast<String, dynamic>(),
      auth: true,
    );

    stopwatch.stop();
    log.adimEkle('Backend API başarılı (${stopwatch.elapsedMilliseconds}ms)');
    log.bilgiEkle('toplam_sure_ms', stopwatch.elapsedMilliseconds);

    await log.basariliGonder('Cihaz başarıyla kaydedildi');
  } catch (e, stackTrace) {
    stopwatch.stop();
    log.bilgiEkle('toplam_sure_ms', stopwatch.elapsedMilliseconds);
    await log.hataliGonder('FCM cihaz kaydı başarısız', '$e\n$stackTrace');
  }
}

/// iOS için APNs token'ı bekle - retry mekanizması ile
Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
  for (int attempt = 1; attempt <= _apnsMaxRetry; attempt++) {
    try {
      final apnsToken = await messaging.getAPNSToken();

      if (apnsToken != null && apnsToken.isNotEmpty) {
        return apnsToken;
      }

      // Son deneme değilse bekle
      if (attempt < _apnsMaxRetry) {
        await Future.delayed(_apnsRetryDelay);
      }
    } catch (e) {
      if (attempt < _apnsMaxRetry) {
        await Future.delayed(_apnsRetryDelay);
      }
    }
  }

  return null;
}

/// Cihaz bilgilerini topla
Future<Map<String, String>> _collectDeviceInfo() async {
  String deviceId = "unknown";
  String deviceModel = "unknown";
  String osVersion = "unknown";
  String deviceType = "android";

  try {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceId = info.id;
      deviceModel = info.model;
      osVersion = info.version.release;
      deviceType = "android";
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? "unknown_ios";
      deviceModel = info.utsname.machine;
      osVersion = info.systemVersion;
      deviceType = "ios";
    }
  } catch (e) {
    // Hata durumunda varsayılan değerler kullanılır
  }

  return {
    "device_id": deviceId,
    "device_type": deviceType,
    "device_model": deviceModel,
    "os_version": osVersion,
  };
}

/// Token'ı backend sunucusuna gönder
Future<void> _sendTokenToServer(String fcmToken) async {
  final log = LogFlowBuilder('FCMService', '_sendTokenToServer', 238);
  final stopwatch = Stopwatch()..start();

  try {
    log.adimEkle('Token sunucuya gönderilmeye başlandı');
    log.bilgiEkle('token_preview', fcmToken.substring(0, 20));

    // Cihaz bilgilerini topla
    log.adimEkle('Cihaz bilgileri toplanıyor');
    final deviceInfo = await _collectDeviceInfo();
    log.bilgiEkle('device_type', deviceInfo['device_type']);
    log.bilgiEkle('device_model', deviceInfo['device_model']);

    final bodyData = {
      ...deviceInfo,
      "fcm_token": fcmToken,
    };

    // Backend'e gönder
    log.adimEkle('Backend API çağrısı yapılıyor');
    await ApiClient.postParsed<Map<String, dynamic>>(
      cihazKaydetGuncelle,
      bodyData,
      (json) => (json as Map).cast<String, dynamic>(),
      auth: true,
    );

    stopwatch.stop();
    log.adimEkle('Backend API başarılı (${stopwatch.elapsedMilliseconds}ms)');
    log.bilgiEkle('toplam_sure_ms', stopwatch.elapsedMilliseconds);

    await log.basariliGonder('Token sunucuya başarıyla güncellendi');
  } catch (e, stackTrace) {
    stopwatch.stop();
    log.bilgiEkle('toplam_sure_ms', stopwatch.elapsedMilliseconds);
    await log.hataliGonder('Token sunucuya gönderilemedi', '$e\n$stackTrace');
  }
}
