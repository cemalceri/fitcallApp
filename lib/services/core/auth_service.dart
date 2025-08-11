// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:async';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/group_model.dart';
import 'package:fitcall/models/4_auth/token_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/local/secure_storage_service.dart';

class AuthService {
  /* ================== TOKEN & STORAGE ================== */
  static Future<bool> tokenGecerliMi() async {
    final exp = await SecureStorageService.getValue<String>('token_exp');
    final dt = exp != null ? DateTime.tryParse(exp) : null;
    return dt != null && dt.isAfter(DateTime.now());
  }

  static Future<String?> getToken() =>
      SecureStorageService.getValue<String>('token');

  static Future<void> logout(BuildContext context) async {
    await SecureStorageService.clearAll();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  static Future<UyeModel?> uyeBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('uye');
    return s == null ? null : UyeModel.fromJson(json.decode(s));
  }

  static Future<AntrenorModel?> antrenorBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('antrenor');
    return s == null ? null : AntrenorModel.fromJson(json.decode(s));
  }

  static Future<GroupModel?> groupBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('gruplar');
    if (s == null) return null;
    final parsed = json.decode(s);
    if (parsed is List && parsed.isNotEmpty) {
      return GroupModel.fromJson(parsed.first);
    }
    return null;
  }

  static Future<UserModel?> userBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('user');
    return s == null ? null : UserModel.fromJson(json.decode(s));
  }

  static Future<bool> beniHatirlaIsaretlenmisMi() async {
    final v = await SecureStorageService.getValue<bool>('beni_hatirla');
    return v == true;
  }

  /* ============== API: Üyelik İlişkileri ============== */
  static Future<List<KullaniciProfilModel>> fetchMyMembers(
    String username,
    String password,
  ) async {
    final body = {'username': username, 'password': password};

    final ApiResult<List<KullaniciProfilModel>> res =
        await ApiClient.postParsed<List<KullaniciProfilModel>>(
      getMyMembers,
      body,
      (j) => ApiParsing.parseList<KullaniciProfilModel>(
        j,
        (m) => KullaniciProfilModel.fromJson(m),
      ),
    );
    // hata durumunda postParsed zaten ApiException fırlatır
    return res.data ?? <KullaniciProfilModel>[];
  }

  /* ============== API: Login (Token üret) ============== */
  static Future<Roller> loginUser(KullaniciProfilModel kp) async {
    // 1) Profil & user sakla
    await SecureStorageService.setValue<String>(
        'uye', jsonEncode(kp.uye?.toJson()));
    await SecureStorageService.setValue<String>(
        'antrenor', jsonEncode(kp.antrenor?.toJson()));
    await SecureStorageService.setValue<String>(
        'user', jsonEncode(kp.user.toJson()));
    await SecureStorageService.setValue<bool>('ana_hesap_mi', kp.anaHesap);
    await SecureStorageService.setValue<String>(
        'gruplar', jsonEncode(kp.gruplar));
    await SecureStorageService.setValue<String>(
        'uye_profil', jsonEncode(kp.toJson()));

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
    );

    final token = res.data;
    if (token == null) {
      throw ApiException('TOKEN_PARSE', 'Token parse edilemedi.');
    }

    // 3) Token sakla
    await SecureStorageService.setValue<String>('token', token.accessToken);
    await SecureStorageService.setValue<String>(
        'token_exp', token.expireDate.toIso8601String());

    // 4) Rol belirle
    final gruplar = kp.gruplar;
    if (gruplar.contains(Roller.antrenor.name)) return Roller.antrenor;
    if (gruplar.contains(Roller.uye.name)) return Roller.uye;
    if (gruplar.contains(Roller.yonetici.name)) return Roller.yonetici;
    if (gruplar.contains(Roller.cafe.name)) return Roller.cafe;

    throw ApiException('ROLE_ERROR',
        'Henüz uygulamaya giriş yetkisi verilmemiş. Lütfen yönetici ile iletişime geçin.');
  }
}
