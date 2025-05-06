// lib/services/auth_service.dart

import 'dart:convert';
import 'package:fitcall/v2/modules/auth/models/kullanici_profil_model.dart';
import 'package:fitcall/v2/shared/api_urls.dart';
import 'package:http/http.dart' as http;

class AuthService {
  /// Giriş talebini yapar, dönen JSON’dan hem token hem de
  /// birden fazla üye/antrenör profilini içeren LoginResponse oluşturur.
  static Future<LoginResponse> login(
    String kullaniciAdi,
    String parola,
  ) async {
    final uri = Uri.parse(loginV2).replace(queryParameters: {
      'kullanici_adi': kullaniciAdi.trim().toLowerCase(),
      'parola': parola,
    });

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      print(data);
      return LoginResponse.fromJson(data);
    } else {
      final hataJson = jsonDecode(utf8.decode(response.bodyBytes));
      final mesaj = hataJson is Map<String, dynamic>
          ? (hataJson['hata'] as String?)
          : null;
      throw Exception(mesaj ?? 'Giriş işlemi başarısız.');
    }
  }
}
