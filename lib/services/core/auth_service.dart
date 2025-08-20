// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/models/4_auth/token_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/api_exception.dart';

class AuthService {
  /* ============== API: Üyelik İlişkileri ============== */
  static Future<List<KullaniciProfilModel>> fetchMyMembers(
    String username,
    String password,
  ) async {
    final body = {'username': username, 'password': password};

    // Hem eski (List) hem yeni ({user_id, profiller}) formatı destekle
    final ApiResult<dynamic> res = await ApiClient.postParsed<dynamic>(
      getMyMembers,
      body,
      (j) => j, // geleni olduğu gibi geçir
      auth: false,
    );

    final data = res.data;

    // 1) Eski: direkt liste dönüyor
    if (data is List) {
      return data
          .map((e) => KullaniciProfilModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    // 2) Yeni: { user_id, profiller: [...] }
    if (data is Map<String, dynamic>) {
      final uid = data['user_id'];
      if (uid is int && uid > 0) {
        // user_id'yi cache'e yaz (LoginPage aktif event çağrısında kullanacağız)
        try {
          await SecureStorageService.setValue<int>('user_id', uid);
        } catch (_) {}
      }

      final listJson = (data['profiller'] as List?) ?? const [];
      return listJson
          .map((e) => KullaniciProfilModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    // Beklenmeyen durum
    return <KullaniciProfilModel>[];
  }

  /* ============== API: Login (Token üret) ============== */
  static Future<Roller> loginUser(KullaniciProfilModel kp) async {
    // 1) Profil & user sakla
    await StorageService.saveProfileData(
      uye: kp.uye != null ? jsonEncode(kp.uye!.toJson()) : null,
      antrenor: kp.antrenor != null ? jsonEncode(kp.antrenor!.toJson()) : null,
      user: jsonEncode(kp.user.toJson()),
      anaHesapMi: kp.anaHesap,
      gruplar: jsonEncode(kp.gruplar),
      uyeProfil: jsonEncode(kp.toJson()),
    );

    // 2) Token isteği
    final payload = {
      'user_id': kp.user.id,
      'uye_id': kp.uye?.id,
      'antrenor_id': kp.antrenor?.id,
    };

    final ApiResult<TokenModel> res = await ApiClient.postParsed<TokenModel>(
      createToken,
      payload,
      (j) => TokenModel.fromMap(j),
      auth: false,
    );

    final token = res.data;
    if (token == null) {
      throw ApiException('TOKEN_PARSE', 'Token parse edilemedi.');
    }

    // 3) Token sakla
    await StorageService.saveTokenData(
      token: token.accessToken,
      expireDate: token.expireDate,
    );

    // 4) Rol belirle
    final gruplar = kp.gruplar;
    if (gruplar.contains(Roller.antrenor.name)) return Roller.antrenor;
    if (gruplar.contains(Roller.uye.name)) return Roller.uye;
    if (gruplar.contains(Roller.yonetici.name)) return Roller.yonetici;
    if (gruplar.contains(Roller.cafe.name)) return Roller.cafe;

    throw ApiException(
      'ROLE_ERROR',
      'Henüz uygulamaya giriş yetkisi verilmemiş. Lütfen yönetici ile iletişime geçin.',
    );
  }

  /* ============== Logout ============== */
  static Future<void> logout(BuildContext context) async {
    await StorageService.clearAll();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
    }
  }
}
