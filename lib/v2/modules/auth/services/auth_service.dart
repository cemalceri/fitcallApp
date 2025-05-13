// lib/services/auth_service.dart

import 'dart:convert';
import 'package:fitcall/services/fcm_service.dart';
import 'package:fitcall/v2/modules/auth/models/kullanici_profil_model.dart';
import 'package:fitcall/v2/shared/api_urls.dart';
import 'package:fitcall/v2/shared/services/secure_storage_service.dart';
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
      await SecureStorageService.setValue<String>('token', data['token']);
      await SecureStorageService.setValue<String>('kullanici_adi',
          data['kullanici_adi'] ?? kullaniciAdi.trim().toLowerCase());
      await SecureStorageService.setValue<String>('parola', parola);
      await SecureStorageService.setValue<bool>(
          'ana_hesap_mi', data['ana_hesap_mi'] == 'true');

      await sendFCMDevice(
        data['token'],
        isMainAccount: data['ana_hesap_mi'] == 'true',
      );
      return LoginResponse.fromJson(data);
    } else {
      final hataJson = jsonDecode(utf8.decode(response.bodyBytes));
      final mesaj = hataJson is Map<String, dynamic>
          ? (hataJson['hata'] as String?)
          : null;
      throw Exception(mesaj ?? 'Giriş işlemi başarısız.');
    }
  }

  /// Yeni kullanıcı kaydı yapar: e-posta, telefon, ad & soyad ve parola gönderilir.
  static Future<void> register({
    required String email,
    required String phone,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final uri = Uri.parse(kayitOlV2); // api_urls.dart içindeki kayıt endpoint'i
    final body = jsonEncode({
      'email': email.trim().toLowerCase(),
      'telefon': phone.trim(),
      'adi': firstName.trim(),
      'soyadi': lastName.trim(),
      'parola': password,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      // Kayıt başarılı
      return;
    } else {
      // Hata yanıtını ayrıştırıp kullanıcıya gösterilecek mesajı al
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      final mesaj = errorData is Map<String, dynamic>
          ? (errorData['hata'] as String?)
          : null;
      throw Exception(mesaj ?? 'Kayıt işlemi başarısız.');
    }
  }
}
