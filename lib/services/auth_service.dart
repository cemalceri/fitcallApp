// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/windgets/show_message_widget.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/group_model.dart';
import 'package:fitcall/models/4_auth/token_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:fitcall/services/fcm_service.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static Future<bool> tokenGecerliMi() async {
    String? tokenExp = await SecureStorageService.getValue<String>('token_exp');
    return tokenExp != null &&
        DateTime.tryParse(tokenExp)?.isAfter(DateTime.now()) == true;
    //todo expire olmuşsa refresh token alacağız
  }

  static Future<String?> getToken() async {
    return SecureStorageService.getValue<String>('token');
  }

  static void logout(BuildContext context) async {
    await SecureStorageService.clearAll();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
    }
  }

  static Future<UyeModel?> uyeBilgileriniGetir() async {
    final uyeJson = await SecureStorageService.getValue<String>('uye');
    if (uyeJson != null) {
      return UyeModel.fromJson(json.decode(uyeJson));
    }
    return null;
  }

  static Future<AntrenorModel?> antrenorBilgileriniGetir() async {
    final antrenorJson =
        await SecureStorageService.getValue<String>('antrenor');
    if (antrenorJson != null) {
      return AntrenorModel.fromJson(json.decode(antrenorJson));
    }
    return null;
  }

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

  static Future<UserModel?> userBilgileriniGetir() async {
    final userJson = await SecureStorageService.getValue<String>('user');
    if (userJson != null) {
      return UserModel.fromJson(json.decode(userJson));
    }
    return null;
  }

  static Future<bool> beniHatirlaIsaretlenmisMi() async {
    final value = await SecureStorageService.getValue<bool>('beni_hatirla');
    return value == true;
  }

  static Future<String?> loginUser(
      BuildContext context, String username, String password) async {
    final data = {'username': username, 'password': password};

    try {
      final response = await http.post(Uri.parse(loginUrl),
          body: jsonEncode(data),
          headers: {
            'Content-Type': 'application/json'
          }).timeout(const Duration(seconds: 15));

      // 1) Başarılı durum
      if (response.statusCode == 200) {
        final tokenModel = TokenModel.fromJson(response);
        await _storeCredentials(tokenModel, username, password);

        // Kullanıcı bilgisi al
        final userResponse = await http.post(
          Uri.parse(getUser),
          headers: {'Authorization': 'Bearer ${tokenModel.accessToken}'},
        );
        if (userResponse.statusCode != 200) {
          ShowMessage.error(context, 'Kullanıcı bilgileri alınamadı.');
          return null;
        }

        final decoded = jsonDecode(utf8.decode(userResponse.bodyBytes));
        await _storeUser(decoded);

        // Rol kontrolü
        if (decoded["antrenor"] != null) {
          await _storeAndSendFcm(
              'antrenor', decoded["antrenor"], tokenModel.accessToken);
          return "antrenor";
        }
        if (decoded["uye"] != null) {
          await _storeAndSendFcm('uye', decoded["uye"], tokenModel.accessToken);
          return "uye";
        }

        ShowMessage.error(context, 'Rol bilgisi alınamadı.');
        return null;
      }

      // 2) Hatalı durum (200 dışı)
      return _handleErrorStatus(context, response.statusCode);
    } on TimeoutException {
      ShowMessage.error(context, 'Sunucuya bağlanırken bir hata oluştu');
    } catch (e) {
      ShowMessage.error(context, 'Bir hata oluştu: $e');
    }

    return null;
  }

  /// Token ve kullanıcı adı/şifreyi kaydeder.
  static Future<void> _storeCredentials(
      TokenModel tokenModel, String user, String pass) async {
    await SecureStorageService.setValue<String>(
        'token', tokenModel.accessToken);
    await SecureStorageService.setValue<String>(
        'token_exp', tokenModel.expireDate.toString());
    await SecureStorageService.setValue<String>('username', user);
    await SecureStorageService.setValue<String>('password', pass);
  }

  /// User, Groups gibi genel bilgileri kaydeder.
  static Future<void> _storeUser(Map<String, dynamic> decoded) async {
    await SecureStorageService.setValue<String>(
        'user', jsonEncode(decoded["user"]));
    await SecureStorageService.setValue<String>(
        'groups', jsonEncode(decoded["groups"]));
  }

  /// Antrenör veya Üye verisini kaydedip FCM gönderir.
  static Future<void> _storeAndSendFcm(
      String key, dynamic data, String accessToken) async {
    await SecureStorageService.setValue<String>(key, jsonEncode(data));
    await sendFCMDevice(accessToken);
  }

  /// StatusCode'a göre hata mesajı
  static String? _handleErrorStatus(BuildContext context, int code) {
    switch (code) {
      case 401:
      case 404:
        _showSnackBar(context, 'Kullanıcı adı veya şifre hatalı');
        break;
      case 403:
        _showSnackBar(context,
            'Hesabınız henüz aktif değil. Lütfen yöneticinizle iletişime geçin.');
        break;
      default:
        _showSnackBar(context, 'Giriş yapılırken bir hata oluştu');
    }
    return null;
  }

  /// SnackBar yardımcısı
  static void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
