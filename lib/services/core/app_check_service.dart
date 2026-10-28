// lib/services/core/app_check_service.dart
//
// Firebase App Check: API isteğinin mağazadan kurulan orijinal uygulamadan
// geldiğini kanıtlayan kısa ömürlü token (Android Play Integrity, iOS App
// Attest). ApiClient her isteğe `X-Firebase-AppCheck` başlığıyla ekler; sunucu
// tarafı `api/core/app_check.py` (mod, sayaçlar, zorunlu moda geçiş sırası).
//
// Token alınamazsa (GMS'siz cihaz, ağ, Play Integrity kotası) istek başlıksız
// gider; sunucu "log" modundayken geçer. İstekleri yavaşlatmasın diye: bekleme
// en çok 2 sn, başarısızlıktan sonra 1 dk denenmez, token süresi bitene kadar
// bellekte tutulur (her istekte platform kanalına gidilmez).
//
// Debug derlemede debug sağlayıcısı çalışır: ilk açılışta logda çıkan debug
// token'ı Firebase konsolunda (App Check → Uygulamalar → Debug token'ları)
// eklenmezse emülatörün istekleri sayaçta "geçersiz" görünür.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppCheckServisi {
  AppCheckServisi._();

  @visibleForTesting
  static Duration beklemeSuresi = const Duration(seconds: 2);
  static const _denemeArasi = Duration(minutes: 1);

  /// Süresi dolmaya bu kadar kala yenisi istenir.
  static const _yenilemePayi = Duration(minutes: 5);

  static String? _token;
  static DateTime? _yenilemeZamani;
  static DateTime? _denemeYasagiBitis;
  static Future<String?>? _suren;

  @visibleForTesting
  static Future<String?> Function() tokenAl =
      () => FirebaseAppCheck.instance.getToken();

  @visibleForTesting
  static DateTime Function() simdi = DateTime.now;

  @visibleForTesting
  static void sifirla() {
    _token = null;
    _yenilemeZamani = null;
    _denemeYasagiBitis = null;
    _suren = null;
  }

  /// Firebase başlatıldıktan sonra bir kez çağrılır (main.dart).
  static Future<void> baslat() async {
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestProvider(),
      );
      FirebaseAppCheck.instance.onTokenChange
          .listen(_kaydet, onError: (Object _) {});
      // İlk API isteğine kadar hazır olsun.
      unawaited(token());
    } catch (e) {
      debugPrint('App Check başlatılamadı: $e');
    }
  }

  /// Geçerli token; alınamazsa null (hata fırlatmaz).
  static Future<String?> token() async {
    final an = simdi();
    if (_token != null && an.isBefore(_yenilemeZamani!)) return _token;
    if (_denemeYasagiBitis != null && an.isBefore(_denemeYasagiBitis!)) {
      return null;
    }
    // Aynı anda başlayan istekler (ana sayfa 6 istek atar) tek alma işlemini
    // bekler. Süre aşılırsa istek başlıksız gider, alma işlemi arkada sürer.
    _suren ??= _al().whenComplete(() => _suren = null);
    return _suren!.timeout(beklemeSuresi, onTimeout: () => null);
  }

  static Future<String?> _al() async {
    try {
      final t = await tokenAl();
      if (t == null || t.isEmpty) {
        _denemeYasagiBitis = simdi().add(_denemeArasi);
        return null;
      }
      _kaydet(t);
      return t;
    } catch (e) {
      debugPrint('App Check token alınamadı: $e');
      _denemeYasagiBitis = simdi().add(_denemeArasi);
      return null;
    }
  }

  static void _kaydet(String? t) {
    if (t == null || t.isEmpty) return;
    _token = t;
    _denemeYasagiBitis = null;
    _yenilemeZamani = simdi().add(omur(t) - _yenilemePayi);
  }

  /// Token'ın ömrü (`exp - iat`, ikisi de sunucu saati). Cihaz saati yanlış
  /// olsa da önbellek süresi doğru kalsın diye `exp` ile kıyaslanmaz.
  /// Okunamazsa 15 dk.
  @visibleForTesting
  static Duration omur(String jwt) {
    try {
      final govde = jwt.split('.')[1];
      final json =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(govde))));
      final exp = json['exp'], iat = json['iat'];
      if (exp is int && iat is int && exp > iat) {
        return Duration(seconds: exp - iat);
      }
    } catch (_) {}
    return const Duration(minutes: 15);
  }

  /// Sunucudaki App Check sayaçları sürüm ve platforma göre tutulur: zorunlu
  /// moda geçmeden önce "güncel sürümde token'sız istek kaldı mı" sorusu
  /// buradan yanıtlanır.
  static Future<Map<String, String>> istemciBasliklari() async {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      final p => p.name,
    };
    try {
      final paket = await PackageInfo.fromPlatform();
      return {'X-Platform': platform, 'X-Uygulama-Surumu': paket.version};
    } catch (_) {
      return {'X-Platform': platform};
    }
  }
}
