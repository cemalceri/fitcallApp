// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/common/api_urls.dart'; // loginUrl, getUser, getMyMembers
import 'package:fitcall/common/constants.dart'; // Roller enum, routeEnums, SayfaAdi
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/group_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:fitcall/models/4_auth/token_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/services/local/secure_storage_service.dart';

class AuthService {
  /// Token hâlâ geçerli mi?
  static Future<bool> tokenGecerliMi() async {
    String? tokenExp = await SecureStorageService.getValue<String>('token_exp');
    return tokenExp != null &&
        DateTime.tryParse(tokenExp)?.isAfter(DateTime.now()) == true;
  }

  /// Saklanan token’ı getir
  static Future<String?> getToken() async {
    return SecureStorageService.getValue<String>('token');
  }

  /// Çıkış yap
  static void logout(BuildContext context) async {
    await SecureStorageService.clearAll();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
    }
  }

  /// SecureStorage’daki “uye” verisini getir
  static Future<UyeModel?> uyeBilgileriniGetir() async {
    final uyeJson = await SecureStorageService.getValue<String>('uye');
    if (uyeJson != null) {
      return UyeModel.fromJson(json.decode(uyeJson));
    }
    return null;
  }

  /// SecureStorage’daki “antrenor” verisini getir
  static Future<AntrenorModel?> antrenorBilgileriniGetir() async {
    final jsonStr = await SecureStorageService.getValue<String>('antrenor');
    if (jsonStr != null) {
      return AntrenorModel.fromJson(json.decode(jsonStr));
    }
    return null;
  }

  /// SecureStorage’daki “groups” verisini getir (ilk grup)
  static Future<GroupModel?> groupBilgileriniGetir() async {
    final groupsJson = await SecureStorageService.getValue<String>('groups');
    if (groupsJson != null) {
      final parsed = json.decode(groupsJson);
      if (parsed is List && parsed.isNotEmpty) {
        return GroupModel.fromJson(parsed.first);
      }
    }
    return null;
  }

  /// SecureStorage’daki “user” verisini getir
  static Future<UserModel?> userBilgileriniGetir() async {
    final userJson = await SecureStorageService.getValue<String>('user');
    if (userJson != null) {
      return UserModel.fromJson(json.decode(userJson));
    }
    return null;
  }

  /// “Beni Hatırla” işaretli mi?
  static Future<bool> beniHatirlaIsaretlenmisMi() async {
    final val = await SecureStorageService.getValue<bool>('beni_hatirla');
    return val == true;
  }

  /// Sadece üye–kullanıcı ilişkilerini alır ve liste döner. Hata durumunda null.
  static Future<List<KullaniciProfilModel>?> fetchMyMembers(
    String username,
    String password,
  ) async {
    final data = {'username': username, 'password': password};
    try {
      final resp = await http
          .post(
            Uri.parse(getMyMembers),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw ApiException(
          'TOKEN_ERROR',
          'Token alınamadı',
          statusCode: resp.statusCode,
        );
      }
      final List<dynamic> relList = jsonDecode(utf8.decode(resp.bodyBytes));
      return relList
          .map((e) => KullaniciProfilModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('UNKNOWN', 'Bilinmeyen hata: $e');
    }
  }

// lib/services/auth_service.dart  (yalnızca loginUser metodu gösteriliyor)

  static Future<Roller> loginUser(KullaniciProfilModel kullaniciProfil) async {
    /* 1) Profil ve user bilgilerini sakla  */
    await SecureStorageService.setValue<String>(
        'uye', jsonEncode(kullaniciProfil.uye?.toJson()));
    await SecureStorageService.setValue<String>(
        'antrenor', jsonEncode(kullaniciProfil.antrenor?.toJson()));
    await SecureStorageService.setValue<String>(
        'user', jsonEncode(kullaniciProfil.user.toJson()));
    await SecureStorageService.setValue<bool>(
        'ana_hesap_mi', kullaniciProfil.anaHesap);
    await SecureStorageService.setValue<String>(
        'gruplar', jsonEncode(kullaniciProfil.gruplar));
    await SecureStorageService.setValue<String>(
        'uye_profil', jsonEncode(kullaniciProfil.toJson()));

    /* 2) Token isteği */
    final payload = {
      'user_id': kullaniciProfil.user.id,
      'uye_id': kullaniciProfil.uye?.id,
      'antrenor_id': kullaniciProfil.antrenor?.id,
    };

    try {
      final resp = await http
          .post(
            Uri.parse(createToken),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw ApiException(
          'TOKEN_ERROR',
          'Token alınamadı',
          statusCode: resp.statusCode,
        );
      }

      /* 3) Token’ı sakla */
      final tokenModel = TokenModel.fromJson(resp);
      await SecureStorageService.setValue<String>(
          'token', tokenModel.accessToken);
      await SecureStorageService.setValue<String>(
          'token_exp', tokenModel.expireDate.toIso8601String());

      /* 4) Rol belirle */
      final gruplar = kullaniciProfil.gruplar;
      if (gruplar.contains(Roller.antrenor.name)) {
        return Roller.antrenor;
      } else if (gruplar.contains(Roller.uye.name)) {
        return Roller.uye;
      } else if (gruplar.contains(Roller.yonetici.name)) {
        return Roller.yonetici;
      } else if (gruplar.contains(Roller.cafe.name)) {
        return Roller.cafe;
      }

      throw ApiException(
          'ROLE_ERROR',
          'Henüz uygulamaya giriş yetkisi verilmemiş. '
              'Lütfen yönetici ile iletişime geçin.');
    } on TimeoutException {
      throw ApiException('TIMEOUT',
          'Sunucuya bağlanırken bir hata oluştu. Lütfen tekrar deneyin.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('UNKNOWN', 'Bilinmeyen hata: $e');
    }
  }
}
