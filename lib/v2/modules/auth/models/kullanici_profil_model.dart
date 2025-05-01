// lib/models/kullanici_profil_model.dart

import 'package:fitcall/v2/modules/antrenor/models/antrenor_model.dart';
import 'package:fitcall/v2/modules/auth/models/kullanici_model.dart';
import 'package:fitcall/v2/modules/uye/models/uye_model.dart';
import 'package:fitcall/v2/shared/models/base_model.dart';

class KullaniciProfilModel extends BaseModel {
  final int? uyeId;
  final int? antrenorId;
  final int kullaniciId;
  final bool anaHesapMi;

  /// Nested objects
  final UyeModel? uye;
  final AntrenorModel? antrenor;
  final KullaniciModel kullanici;

  KullaniciProfilModel({
    required super.id,
    required super.olusturulmaZamani,
    required super.guncellenmeZamani,
    required super.isletmeId,
    this.uyeId,
    this.antrenorId,
    required this.kullaniciId,
    required this.anaHesapMi,
    this.uye,
    this.antrenor,
    required this.kullanici,
  });

  factory KullaniciProfilModel.fromJson(Map<String, dynamic> json) {
    final uyeJson = json['uye'];
    final antrenorJson = json['antrenor'];
    final kullaniciJson = json['kullanici'] as Map<String, dynamic>;

    return KullaniciProfilModel(
      id: json['id'] as int,
      olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
      guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
      isletmeId: json['isletme'] as int,
      uyeId: uyeJson != null ? (uyeJson['id'] as int?) : null,
      antrenorId: antrenorJson != null ? (antrenorJson['id'] as int?) : null,
      kullaniciId: kullaniciJson['id'] as int,
      anaHesapMi: json['ana_hesap_mi'] as bool,
      uye: uyeJson != null
          ? UyeModel.fromJson(uyeJson as Map<String, dynamic>)
          : null,
      antrenor: antrenorJson != null
          ? AntrenorModel.fromJson(antrenorJson as Map<String, dynamic>)
          : null,
      kullanici: KullaniciModel.fromJson(kullaniciJson),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'uye': uye?.toJson(),
        'antrenor': antrenor?.toJson(),
        'kullanici': kullanici.toJson(),
        'ana_hesap_mi': anaHesapMi,
      };
}
