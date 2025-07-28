// lib/models/kort_model.dart
class KortModel {
  final int id;
  final String adi;
  final int maxEtkinlikSayisi;
  final String kullanabilecekUyeTurleri;
  final int sira;

  // BaseAbstract alanları
  final bool isActive;
  final bool isDeleted;
  final int? ekleyen;
  final int? guncelleyen;
  final int? isletme;
  final DateTime createdAt;
  final DateTime updatedAt;

  KortModel({
    required this.id,
    required this.adi,
    required this.maxEtkinlikSayisi,
    required this.kullanabilecekUyeTurleri,
    required this.sira,
    required this.isActive,
    required this.isDeleted,
    this.ekleyen,
    this.guncelleyen,
    this.isletme,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _dt(String? v) =>
      (v == null || v.isEmpty) ? DateTime.now() : DateTime.parse(v);

  factory KortModel.fromJson(Map<String, dynamic> json) => KortModel(
        id: json['id'] ?? 0,
        adi: json['adi'] ?? '',
        maxEtkinlikSayisi: json['max_etkinlik_sayisi'] ?? 0,
        kullanabilecekUyeTurleri: json['kullanabilecek_uye_turleri'] ?? '',
        sira: json['sira'] ?? 0,
        isActive: json['is_active'] ?? true,
        isDeleted: json['is_deleted'] ?? false,
        ekleyen: json['ekleyen'],
        guncelleyen: json['guncelleyen'],
        isletme: json['isletme'],
        createdAt: _dt(json['olusturulma_zamani']),
        updatedAt: _dt(json['guncellenme_zamani']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adi': adi,
        'max_etkinlik_sayisi': maxEtkinlikSayisi,
        'kullanabilecek_uye_turleri': kullanabilecekUyeTurleri,
        'sira': sira,
        'is_active': isActive,
        'is_deleted': isDeleted,
        'ekleyen': ekleyen,
        'guncelleyen': guncelleyen,
        'isletme': isletme,
        'olusturulma_zamani': createdAt.toIso8601String(),
        'guncellenme_zamani': updatedAt.toIso8601String(),
      };

  static KortModel empty() => KortModel(
        id: 0,
        adi: '',
        maxEtkinlikSayisi: 0,
        kullanabilecekUyeTurleri: '',
        sira: 0,
        isActive: true,
        isDeleted: false,
        ekleyen: null,
        guncelleyen: null,
        isletme: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
