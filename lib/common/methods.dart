import 'dart:async';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/antrenor_model.dart';
import 'package:fitcall/models/auth/group_model.dart';
import 'package:fitcall/models/auth/token_model.dart';
import 'package:fitcall/models/auth/user_model.dart';
import 'package:fitcall/models/uye_model.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
        await savePrefs("user", jsonEncode(decoded["user"]));
        await savePrefs("groups", jsonEncode(decoded["groups"]));
        await savePrefs("uye", jsonEncode(decoded["uye"]));
        await savePrefs("antrenor", jsonEncode(decoded["antrenor"]));

        // Rol kontrolü:
        if (decoded["antrenor"] != null) {
          await savePrefs("antrenor", jsonEncode(decoded["antrenor"]));
          // Başarılı login sonrası FCM cihaz bilgisini gönder
          await sendFCMDevice(tokenModel.accessToken);
          return "antrenor";
        } else if (decoded["uye"] != null) {
          await savePrefs("uye", jsonEncode(decoded["uye"]));
          // Başarılı login sonrası FCM cihaz bilgisini gönder
          await sendFCMDevice(tokenModel.accessToken);
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

Future<UyeModel?> uyeBilgileriniGetir(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? uyeJson = sp.getString('uye');
  if (uyeJson != null) {
    return UyeModel.fromJson(json.decode(uyeJson));
  } else {
    return null;
  }
}

Future<AntrenorModel?> antrenorBilgileriniGetir(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? antrenor = sp.getString('antrenor');
  if (antrenor != null) {
    return AntrenorModel.fromJson(json.decode(antrenor));
  } else {
    return null;
  }
}

Future<GroupModel?> groupBilgileriniGetir(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? groups = sp.getString('groups');
  if (groups != null) {
    return GroupModel.fromJson(json.decode(groups));
  } else {
    return null;
  }
}

Future<UserModel?> userBilgileriniGetir(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? user = sp.getString('user');
  if (user != null) {
    return UserModel.fromJson(json.decode(user));
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

Future<void> sendFCMDevice(String bearerToken) async {
  // FCM token'ını al
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) {
    print("FCM token alınamadı");
    return;
  }

  // Cihaz bilgilerini al
  String deviceId = "unknown_device";
  String deviceModel = "unknown_model";
  String osVersion = "unknown_version";
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id;
    deviceModel = androidInfo.model;
    osVersion = androidInfo.version.release;
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? "unknown_ios_id";
    // iOS'ta cihaz model bilgisini almak için:
    deviceModel = iosInfo.utsname.machine;
    osVersion = iosInfo.systemVersion;
  }

  // Cihaz tipini belirle
  String deviceType = Platform.isAndroid ? "android" : "ios";

  // API'ye gönderilecek body verisini hazırla. Ek alanlar da ekleniyor.
  Map<String, dynamic> bodyData = {
    "device_id": deviceId,
    "fcm_token": fcmToken,
    "device_type": deviceType,
    "device_model": deviceModel,
    "os_version": osVersion,
  };

  // API URL'nizi buraya yerleştirin.

  try {
    final response = await http.post(
      Uri.parse(cihazKaydetGuncelle),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("FCM cihaz bilgileri kaydedildi/güncellendi");
    } else {
      print("FCM cihaz bilgileri kaydedilemedi: ${response.statusCode}");
    }
  } catch (e) {
    print("FCM cihaz bilgileri gönderilirken hata oluştu: $e");
  }
}
