import 'dart:convert';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';

class KullaniciProfilModel {
  final int id;
  final UyeModel? uye;
  final UserModel user;
  final AntrenorModel? antrenor;
  final bool anaHesap;
  final List<String> gruplar;
  bool isLoginSuccess;

  KullaniciProfilModel({
    required this.id,
    required this.uye,
    required this.antrenor,
    required this.user,
    required this.anaHesap,
    required this.gruplar,
    this.isLoginSuccess = false,
  });

  factory KullaniciProfilModel.fromJson(Map<String, dynamic> json) {
    return KullaniciProfilModel(
      id: json['id'] as int,
      uye: json['uye'] != null
          ? UyeModel.fromJson(json['uye'] as Map<String, dynamic>)
          : null,
      antrenor: json['antrenor'] != null
          ? AntrenorModel.fromJson(json['antrenor'] as Map<String, dynamic>)
          : null,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      anaHesap: json['ana_hesap_mi'] as bool? ?? false,
      gruplar: (json['gruplar'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uye': uye?.toJson(),
      'antrenor': antrenor?.toJson(),
      'user': user.toJson(),
      'ana_hesap': anaHesap,
      'gruplar': gruplar,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
