// lib/models/base_model.dart
class BaseModel {
  final int id;
  final DateTime olusturulmaZamani;
  final DateTime guncellenmeZamani;
  final int isletmeId;

  BaseModel({
    required this.id,
    required this.olusturulmaZamani,
    required this.guncellenmeZamani,
    required this.isletmeId,
  });

  factory BaseModel.fromJson(Map<String, dynamic> json) => BaseModel(
        id: json['id'] as int,
        olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
        guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
        isletmeId: json['isletme'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'olusturulma_zamani': olusturulmaZamani.toIso8601String(),
        'guncellenme_zamani': guncellenmeZamani.toIso8601String(),
        'isletme': isletmeId,
      };
}
