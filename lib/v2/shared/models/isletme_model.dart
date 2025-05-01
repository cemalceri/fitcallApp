// lib/models/isletme_model.dart

class IsletmeModel {
  final int id;
  final String ad;
  final bool aktifMi;
  final DateTime olusturulmaZamani;
  final DateTime guncellenmeZamani;

  IsletmeModel({
    required this.id,
    required this.ad,
    required this.aktifMi,
    required this.olusturulmaZamani,
    required this.guncellenmeZamani,
  });

  factory IsletmeModel.fromJson(Map<String, dynamic> json) => IsletmeModel(
        id: json['id'] as int,
        ad: json['ad'] as String,
        aktifMi: json['aktif_mi'] as bool,
        olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
        guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'aktif_mi': aktifMi,
        'olusturulma_zamani': olusturulmaZamani.toIso8601String(),
        'guncellenme_zamani': guncellenmeZamani.toIso8601String(),
      };
}
