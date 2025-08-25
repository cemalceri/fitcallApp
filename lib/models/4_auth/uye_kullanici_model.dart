import 'dart:convert';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';

class KullaniciProfilModel {
  final int id; // SistemKullaniciModel.id (profilId)
  final UserModel user; // Nested user
  final String rol; // 'uye' | 'antrenor' | diger roller
  final UyeModel? uye; // rol=='uye' ise dolu
  final AntrenorModel? antrenor; // rol=='antrenor' ise dolu
  final bool anaHesap; // ana_hesap_mi
  bool isLoginSuccess;

  KullaniciProfilModel({
    required this.id,
    required this.user,
    required this.rol,
    required this.uye,
    required this.antrenor,
    required this.anaHesap,
    this.isLoginSuccess = false,
  });

  factory KullaniciProfilModel.fromJson(Map<String, dynamic> json) {
    return KullaniciProfilModel(
      id: json['id'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      rol: (json['rol'] as String?)?.toLowerCase() ?? '',
      uye: json['uye'] != null
          ? UyeModel.fromJson(json['uye'] as Map<String, dynamic>)
          : null,
      antrenor: json['antrenor'] != null
          ? AntrenorModel.fromJson(json['antrenor'] as Map<String, dynamic>)
          : null,
      anaHesap: (json['ana_hesap_mi'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'rol': rol,
      'uye': uye?.toJson(),
      'antrenor': antrenor?.toJson(),
      'ana_hesap_mi': anaHesap,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
