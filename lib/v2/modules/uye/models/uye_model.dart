// lib/models/uye_model.dart

import 'package:fitcall/v2/shared/models/base_model.dart';

class UyeModel extends BaseModel {
  final int kullaniciId;
  final String? telefon;

  UyeModel({
    required super.id,
    required super.olusturulmaZamani,
    required super.guncellenmeZamani,
    required super.isletmeId,
    required this.kullaniciId,
    this.telefon,
  });

  factory UyeModel.fromJson(Map<String, dynamic> json) => UyeModel(
        id: json['id'] as int,
        olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
        guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
        isletmeId: json['isletme'] as int,
        kullaniciId: json['kullanici'] as int,
        telefon: json['telefon'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'kullanici': kullaniciId,
        'telefon': telefon,
      };
}
