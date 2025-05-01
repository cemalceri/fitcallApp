// lib/models/okul_model.dart
import 'base_model.dart';

class OkulModel extends BaseModel {
  final String ad;
  final int ilId;
  final int ilceId;
  final String adres;

  OkulModel({
    required int id,
    required DateTime olusturulmaZamani,
    required DateTime guncellenmeZamani,
    required int isletmeId,
    required this.ad,
    required this.ilId,
    required this.ilceId,
    required this.adres,
  }) : super(
          id: id,
          olusturulmaZamani: olusturulmaZamani,
          guncellenmeZamani: guncellenmeZamani,
          isletmeId: isletmeId,
        );

  factory OkulModel.fromJson(Map<String, dynamic> json) => OkulModel(
        id: json['id'] as int,
        olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
        guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
        isletmeId: json['isletme'] as int,
        ad: json['ad'] as String,
        ilId: json['il'] as int,
        ilceId: json['ilce'] as int,
        adres: json['adres'] as String? ?? '',
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'ad': ad,
        'il': ilId,
        'ilce': ilceId,
        'adres': adres,
      };
}
