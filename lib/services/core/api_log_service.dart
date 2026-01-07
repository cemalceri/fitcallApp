// lib/services/core/mobile_log_service.dart

import 'dart:io';
import 'package:fitcall/common/api_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fitcall/services/api_client.dart';

/// Mobil uygulama loglarını backend'e gönderen servis
class MobileLogService {
  MobileLogService._();
  static final MobileLogService instance = MobileLogService._();

  String? _deviceType;
  String? _osVersion;
  String? _appVersion;
  String? _deviceModel;

  /// Cihaz bilgilerini bir kez al ve cache'le
  Future<void> _ensureDeviceInfo() async {
    if (_deviceType != null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _deviceType = 'android';
        _osVersion = info.version.release;
        _deviceModel = info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _deviceType = 'ios';
        _osVersion = info.systemVersion;
        _deviceModel = info.utsname.machine;
      }
    } catch (e) {
      _deviceType = 'unknown';
      _osVersion = 'unknown';
      _appVersion = 'unknown';
      _deviceModel = 'unknown';
    }
  }

  /// Başarılı işlem logu (info seviyesi)
  Future<void> logSuccess(
    String sayfa,
    String metot,
    int satir,
    String mesaj, {
    Map<String, dynamic>? ekstraBilgi,
  }) async {
    await _log('info', sayfa, metot, satir, mesaj, null, ekstraBilgi);
  }

  /// Hatalı işlem logu (error seviyesi)
  Future<void> logError(
    String sayfa,
    String metot,
    int satir,
    String mesaj, {
    dynamic hata,
    Map<String, dynamic>? ekstraBilgi,
  }) async {
    await _log(
        'error', sayfa, metot, satir, mesaj, hata?.toString(), ekstraBilgi);
  }

  /// Ana log metodu - backend'e gönderir
  Future<void> _log(
    String seviye,
    String sayfa,
    String metot,
    int satir,
    String mesaj,
    String? hata,
    Map<String, dynamic>? ekstraBilgi,
  ) async {
    // Debug modda konsola yaz
    final logStr =
        '[$seviye] $sayfa.$metot:$satir - $mesaj${hata != null ? ' | Hata: $hata' : ''}';
    debugPrint('[MobileLog] $logStr');

    // Backend'e gönder
    try {
      await _ensureDeviceInfo();

      final body = {
        'seviye': seviye,
        'sayfa': sayfa,
        'metot': metot,
        'satir': satir,
        'mesaj': mesaj,
        if (hata != null) 'hata': hata,
        'ekstra': {
          'device_type': _deviceType,
          'os_version': _osVersion,
          'app_version': _appVersion,
          'device_model': _deviceModel,
          if (ekstraBilgi != null) ...ekstraBilgi,
        },
      };

      // Auth olmadan gönder (AllowAny endpoint)
      await ApiClient.postParsed<Map<String, dynamic>>(
        mobilLogKaydet,
        body,
        (json) => (json as Map).cast<String, dynamic>(),
        auth: false,
      );
    } catch (e) {
      // Log gönderimi başarısız olursa sadece konsola yaz
      debugPrint('[MobileLog] Backend\'e gönderilemedi: $e');
    }
  }
}

/// İşlem akışı takibi için yardımcı sınıf
class LogFlowBuilder {
  final String sayfa;
  final String metot;
  final int satir;
  final List<String> _adimlar = [];
  final Map<String, dynamic> _ekstraBilgi = {};

  LogFlowBuilder(this.sayfa, this.metot, this.satir);

  /// Akışa adım ekle
  void adimEkle(String adim) {
    _adimlar.add('➤ $adim');
  }

  /// Ekstra bilgi ekle
  void bilgiEkle(String anahtar, dynamic deger) {
    _ekstraBilgi[anahtar] = deger;
  }

  /// Başarılı işlem logu gönder
  Future<void> basariliGonder(String sonuc) async {
    final mesaj = '''
İşlem Başarılı ✓
${_adimlar.join('\n')}
➤ $sonuc
''';
    await MobileLogService.instance.logSuccess(
      sayfa,
      metot,
      satir,
      mesaj,
      ekstraBilgi: _ekstraBilgi,
    );
  }

  /// Hatalı işlem logu gönder
  Future<void> hataliGonder(String sonuc, dynamic hata) async {
    final mesaj = '''
İşlem Başarısız ✗
${_adimlar.join('\n')}
➤ $sonuc
''';
    await MobileLogService.instance.logError(
      sayfa,
      metot,
      satir,
      mesaj,
      hata: hata,
      ekstraBilgi: _ekstraBilgi,
    );
  }
}

/// Kısa erişim için global fonksiyonlar
Future<void> mobileLogSuccess(
  String sayfa,
  String metot,
  int satir,
  String mesaj, {
  Map<String, dynamic>? ekstraBilgi,
}) =>
    MobileLogService.instance.logSuccess(
      sayfa,
      metot,
      satir,
      mesaj,
      ekstraBilgi: ekstraBilgi,
    );

Future<void> mobileLogError(
  String sayfa,
  String metot,
  int satir,
  String mesaj, {
  dynamic hata,
  Map<String, dynamic>? ekstraBilgi,
}) =>
    MobileLogService.instance.logError(
      sayfa,
      metot,
      satir,
      mesaj,
      hata: hata,
      ekstraBilgi: ekstraBilgi,
    );
