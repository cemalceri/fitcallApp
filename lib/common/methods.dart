import 'dart:async';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/auth/token_model.dart';
import 'package:fitcall/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken(BuildContext context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();

  // Eğer token geçerliyse, token'ı döndür.
  if (await tokenGecerliMi()) {
    return sp.getString('token');
  } else {
    String username = sp.getString('username') ?? '';
    String password = sp.getString('password') ?? '';
    String? role;
    if (context.mounted) {
      role = await loginUser(context, username, password);
    }
    if (context.mounted && role != null) {
      return sp.getString('token');
    }
  }
  await sp.remove('token');
  await sp.remove('token_exp');
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
  }
  return null;
}

/// Giriş yapıldığında token alıp, kullanıcı bilgilerini getirir.
/// Gelen veride "antrenor" alanı varsa "antrenor", "uye" alanı varsa "uye" döndürür.
Future<String?> loginUser(
    BuildContext context, String username, String password) async {
  Map<String, String> data = {'username': username, 'password': password};
  try {
    final response = await http.post(
      Uri.parse(loginUrl),
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      // Token bilgisini modelden çekiyoruz.
      TokenModel tokenModel = TokenModel.fromJson(response);
      await savePrefs("token", tokenModel.accessToken);
      await savePrefs("token_exp", tokenModel.expireDate.toString());

      // Kullanıcı bilgilerini çekiyoruz:
      var userResponse = await http.post(
        Uri.parse(getUser),
        headers: {'Authorization': 'Bearer ${tokenModel.accessToken}'},
      );

      if (userResponse.statusCode == 200) {
        // Gelen veriyi decode edip kaydediyoruz:
        var decoded = jsonDecode(utf8.decode(userResponse.bodyBytes));
        await savePrefs("user", jsonEncode(decoded));
        await savePrefs("groups", jsonEncode(decoded["groups"]));

        // Rol kontrolü:
        if (decoded["antrenor"] != null) {
          await savePrefs("antrenor", jsonEncode(decoded["antrenor"]));
          return "antrenor";
        } else if (decoded["uye"] != null) {
          await savePrefs("uye", jsonEncode(decoded["uye"]));
          return "uye";
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Kullanıcı rolü belirlenemedi.")),
            );
          }
          return null;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kullanıcı bilgileri alınamadı.")),
          );
        }
        return null;
      }
    } else if (response.statusCode == 401 || response.statusCode == 404) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı adı veya şifre hatalı')),
        );
      }
    } else if (response.statusCode == 403) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Hesabınız henüz aktif değil. Lütfen yöneticinizle iletişime geçin.'),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapılırken bir hata oluştu')),
        );
      }
    }
  } on TimeoutException catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucuya bağlanırken bir hata oluştu')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    }
  }
  return null;
}

Future<void> savePrefs(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<void> savePrefsBool(String key, bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<UserModel?> kullaniciBilgileriniGetir(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? kullaniciJson = sp.getString('kullanici');
  if (kullaniciJson != null) {
    return UserModel.fromJson(json.decode(kullaniciJson));
  } else {
    return null;
  }
}

void logout(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  sp.remove('token_exp');
  sp.remove('token').then((value) {
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.login]!);
    }
  });
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
  return beniHatirla == true;
}
