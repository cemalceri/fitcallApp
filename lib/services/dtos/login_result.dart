// lib/models/4_auth/login_result.dart

import 'dart:convert';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';

/// API’den dönen Üye–Kullanıcı ilişkisi listesini sarmalayan model
class LoginResult {
  /// Bu user’a ait Üye–Kullanıcı ilişkileri
  final List<KullaniciProfilModel> uyeKullaniciListesi;

  LoginResult({
    required this.uyeKullaniciListesi,
  });

  /// JSON’dan LoginResult oluşturur
  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      uyeKullaniciListesi: (json['uye_kullanici_listesi'] as List<dynamic>)
          .map((e) => KullaniciProfilModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// LoginResult’u JSON’a çevirir
  Map<String, dynamic> toJson() {
    return {
      'uye_kullanici_listesi':
          uyeKullaniciListesi.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
