// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/auth/login_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  if (await tokenGecerliMi()) {
    return sp.getString('token');
  } else {
    if (await beniHatirlaIsaretlenmisMi()) {
      String username = sp.getString('username') ?? '';
      String password = sp.getString('password') ?? '';
      bool loginResult = await loginUser(context, username, password);
      if (loginResult) {
        return sp.getString('token');
      }
    }
  }
  sp.remove('token');
  sp.remove('token_exp');
  Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
  return null;
}

Future<bool> loginUser(
    BuildContext context, String username, String password) async {
  Map<String, String> data = {'username': username, 'password': password};
  try {
    final response = await http.post(
      Uri.parse(loginUrl),
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      TokenModel tokenModel = TokenModel.fromJson(response);
      await savePrefs("token", tokenModel.accessToken);
      await savePrefs("token_exp", tokenModel.expireDate.toString());
      bool userInfoFetched =
          await kullaniciBilgileriniGetir(tokenModel.accessToken);
      if (userInfoFetched) {
        return true;
      }
      return false;
    } else if (response.statusCode == 401 || response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı veya şifre hatalı'),
        ),
      );
    } else if (response.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Hesabınız henüz aktif değil. Lütfen yöneticinizle iletişime geçin.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yapılırken bir hata oluştu'),
        ),
      );
    }
  } on TimeoutException catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sunucuya bağlanırken bir hata oluştu'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bir hata oluştu: $e'),
      ),
    );
  }
  return false;
}

Future<bool> kullaniciBilgileriniGetir(String token) async {
  try {
    var response = await http.post(
      Uri.parse(getSporcu),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      savePrefs("kullanici", utf8.decode(response.bodyBytes));
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

void logout(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.remove('token_exp');
  sp.remove('token').then((value) =>
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!));
}

Future<void> savePrefs(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> savePrefsBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<String?> getPrefs(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? value = prefs.getString(key);
  return value;
}

Future<bool> tokenGecerliMi() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? tokenExp = sp.getString('token_exp');
  return tokenExp != null &&
      DateTime.tryParse(tokenExp)?.isAfter(DateTime.now()) == true;
}

Future<bool> beniHatirlaIsaretlenmisMi() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  bool? beniHatirla = sp.getBool('beni_hatirla');
  if (beniHatirla == true) {
    return true;
  } else {
    return false;
  }
}
