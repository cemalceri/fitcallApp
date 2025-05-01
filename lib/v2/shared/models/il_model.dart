// lib/models/il_model.dart
class IlModel {
  final int id;
  final String ad;
  final int plakaKodu;

  IlModel({
    required this.id,
    required this.ad,
    required this.plakaKodu,
  });

  factory IlModel.fromJson(Map<String, dynamic> json) => IlModel(
        id: json['id'] as int,
        ad: json['ad'] as String,
        plakaKodu: json['plaka_kodu'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'plaka_kodu': plakaKodu,
      };
}
