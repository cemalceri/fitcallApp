import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_exception.dart';

/// Cihazı kaydeder/günceller.
/// [isMainAccount]: Giriş yapan kullanıcının bu üyenin ana hesabı olup olmadığı.
Future<void> sendFCMDevice({required bool isMainAccount}) async {
  // 1) FCM token’ı al
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) {
    return;
  }

  // 2) Cihaz bilgileri
  String deviceId = "unknown_device";
  String deviceModel = "unknown_model";
  String osVersion = "unknown_version";

  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
    deviceModel = androidInfo.model;
    osVersion = androidInfo.version.release;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? "unknown_ios_id";
    deviceModel = iosInfo.utsname.machine;
    osVersion = iosInfo.systemVersion;
  }

  final deviceType = Platform.isAndroid ? "android" : "ios";

  // 3) Gönderilecek veri gövdesi
  final bodyData = {
    "device_id": deviceId,
    "fcm_token": fcmToken,
    "device_type": deviceType,
    "device_model": deviceModel,
    "os_version": osVersion,
    "isMainAccount": isMainAccount,
  };

  // 4) HTTP isteğini yap
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
