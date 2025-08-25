// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:fitcall/models/dtos/kullanici_profilleri_result_dto.dart';
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
  static Future<KullaniciProfilleriResult> fetchMyMembers(
    String username,
    String password,
  ) async {
    final body = {'username': username, 'password': password};

    final ApiResult<dynamic> res = await ApiClient.postParsed<dynamic>(
      getMyMembers,
      body,
      (j) => j,
      auth: false,
    );

    final data = res.data;

    // 1) Eski: direkt liste
    if (data is List) {
      final profiller = data
          .map((e) => KullaniciProfilModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      // Eski formatta user yok; profillerden çıkarabildiğimiz kadar
      final user = profiller.isNotEmpty ? profiller.first.user : null;
      if (user != null) {
        try {
          await SecureStorageService.setValue<int>('user_id', user.id);
        } catch (_) {}
      }
      return KullaniciProfilleriResult(user: user, profiller: profiller);
    }

    if (data is Map<String, dynamic>) {
      UserModel? user;
      final userMap = data['user'];
      if (userMap is Map<String, dynamic>) {
        user = UserModel.fromJson(Map<String, dynamic>.from(userMap));
        try {
          await SecureStorageService.setValue<int>('user_id', user.id);
        } catch (_) {}
      }

      final listJson = (data['profiller'] as List?) ?? const [];
      final profiller = listJson
          .map((e) => KullaniciProfilModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      return KullaniciProfilleriResult(user: user, profiller: profiller);
    }

    return KullaniciProfilleriResult(user: null, profiller: const []);
  }

  /* ============== API: Login (Token üret) ============== */
  static Future<Roller> loginUser(KullaniciProfilModel kp) async {
    // 1) Profil & user sakla (gruplar alanı geriye uyum için tek öğeli liste: rol)
    await StorageService.saveProfileData(
      uye: kp.uye != null ? jsonEncode(kp.uye!.toJson()) : null,
      antrenor: kp.antrenor != null ? jsonEncode(kp.antrenor!.toJson()) : null,
      user: jsonEncode(kp.user.toJson()),
      anaHesapMi: kp.anaHesap,
      gruplar: jsonEncode([kp.rol]),
      uyeProfil: jsonEncode(kp.toJson()),
    );

    // 2) Token isteği (yeni payload)
    final payload = <String, dynamic>{
      'user_id': kp.user.id,
      'rol': kp.rol,
      'profil_id': kp.id, // SistemKullaniciModel.id
    };
    if (kp.rol == Roller.uye.name) {
      payload['uye_id'] = kp.uye?.id;
    } else if (kp.rol == Roller.antrenor.name) {
      payload['antrenor_id'] = kp.antrenor?.id;
    }

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

    // 4) Rol belirle (tekil rol)
    final r = kp.rol;
    if (r == Roller.antrenor.name) return Roller.antrenor;
    if (r == Roller.uye.name) return Roller.uye;
    if (r == Roller.yonetici.name) return Roller.yonetici;
    if (r == Roller.cafe.name) return Roller.cafe;

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
