// lib/services/core/indirme_service.dart
//
// Dosyayı telefonun "İndirilenler" klasörüne kaydeder (yönetici dekont PDF'i).
//
// Native taraf MainActivity.kt'de: Android 10+ MediaStore ile izin istemeden
// yazar. iOS'ta ve Android 9 ve altında "İndirilenler"e izinsiz yazılamaz;
// çağrı null döner, sayfa paylaşım menüsüne düşer (iOS'ta "Dosyalar'a Kaydet"
// oradadır). Her çağrı hataya karşı korumalıdır, istisna fırlatmaz.

import 'dart:io';

import 'package:flutter/services.dart';

class IndirmeService {
  static const MethodChannel _kanal = MethodChannel('fitcall/indirme');

  /// Kaydedilen dosyanın içerik adresi; kaydedilemediyse null.
  static Future<String?> indirilenlereKaydet({
    required String ad,
    required Uint8List baytlar,
    required String tur,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _kanal.invokeMethod<String>(
          'kaydet', {'ad': ad, 'baytlar': baytlar, 'tur': tur});
    } catch (_) {
      return null;
    }
  }

  /// İndirilen dosyayı uygun uygulamayla açar; açacak uygulama yoksa false.
  static Future<bool> ac(String uri, String tur) async {
    try {
      return await _kanal.invokeMethod<bool>('ac', {'uri': uri, 'tur': tur}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
