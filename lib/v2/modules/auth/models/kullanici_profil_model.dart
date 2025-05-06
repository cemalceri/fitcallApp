// lib/models/login_response.dart

import 'package:fitcall/v2/modules/auth/models/kullanici_model.dart';

class UyeProfil {
  final int id;
  final String adi;
  final String soyadi;
  final bool anaHesapMi;

  UyeProfil({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.anaHesapMi,
  });

  factory UyeProfil.fromJson(Map<String, dynamic> json) => UyeProfil(
        id: json['id'] as int,
        adi: json['adi'] as String,
        soyadi: json['soyadi'] as String,
        anaHesapMi: json['ana_hesap_mi'] as bool,
      );
}

class AntrenorProfil {
  final int id;
  final String adi;
  final String soyadi;
  final bool anaHesapMi;

  AntrenorProfil({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.anaHesapMi,
  });

  factory AntrenorProfil.fromJson(Map<String, dynamic> json) => AntrenorProfil(
        id: json['id'] as int,
        adi: json['adi'] as String,
        soyadi: json['soyadi'] as String,
        anaHesapMi: json['ana_hesap_mi'] as bool,
      );
}

class GroupModel {
  final int id;
  final String name;

  GroupModel({required this.id, required this.name});

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class PermissionModel {
  final int id;
  final String name;
  final String grup;

  PermissionModel({
    required this.id,
    required this.name,
    required this.grup,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        id: json['id'] as int,
        name: json['name'] as String,
        grup: json['grup'] as String,
      );
}

class LoginResponse {
  final String token;
  final KullaniciModel user;
  final List<UyeProfil> uyeler;
  final List<AntrenorProfil> antrenorler;
  final List<GroupModel> gruplar;
  final List<PermissionModel> izinler;

  LoginResponse({
    required this.token,
    required this.user,
    required this.uyeler,
    required this.antrenorler,
    required this.gruplar,
    required this.izinler,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // 1) token
    final token = json['token'] as String;

    // 2) user nesnesi, JSON'daki first_name/last_name → KullaniciModel
    final u = json['user'] as Map<String, dynamic>;
    final user = KullaniciModel(
      id: u['id'] as int,
      firstName: u['first_name'] as String,
      lastName: u['last_name'] as String,
      email: u['email'] as String,
      // Eğer KullaniciModel başka required alanlar alıyorsa onları da burada ekleyin
    );

    // 3) listeleri parse et
    final uyelerJson = json['uyeler'] as List<dynamic>;
    final antrenorlerJson = json['antrenorler'] as List<dynamic>;
    final gruplarJson = json['gruplar'] as List<dynamic>;
    final izinlerJson = json['izinler'] as List<dynamic>;

    return LoginResponse(
      token: token,
      user: user,
      uyeler: uyelerJson
          .map((e) => UyeProfil.fromJson(e as Map<String, dynamic>))
          .toList(),
      antrenorler: antrenorlerJson
          .map((e) => AntrenorProfil.fromJson(e as Map<String, dynamic>))
          .toList(),
      gruplar: gruplarJson
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      izinler: izinlerJson
          .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
