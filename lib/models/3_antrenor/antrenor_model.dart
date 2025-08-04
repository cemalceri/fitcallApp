// lib/models/antrenor_model.dart
class AntrenorModel {
  final int id;
  final String adi;
  final String soyadi;
  final String? ePosta;
  final String? telefon;
  final String renk; // Hex renk
  final double ucretKatsayisi;
  final String? profileImageUrl;

  // BaseAbstract alanları
  final bool isActive;
  final bool isDeleted;
  final int? ekleyen; // User ID
  final int? guncelleyen; // User ID
  final int? isletme; // İşletme ID
  final DateTime createdAt;
  final DateTime updatedAt;

  AntrenorModel({
    required this.id,
    required this.adi,
    required this.soyadi,
    this.ePosta,
    this.telefon,
    required this.renk,
    required this.ucretKatsayisi,
    this.profileImageUrl,
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

  factory AntrenorModel.fromJson(Map<String, dynamic> json) => AntrenorModel(
        id: json['id'] ?? 0,
        adi: json['adi'] ?? '',
        soyadi: json['soyadi'] ?? '',
        ePosta: json['e_posta'],
        telefon: json['telefon'],
        renk: json['renk'] ?? '#757575',
        ucretKatsayisi: (json['ucret_katsayisi'] is num)
            ? json['ucret_katsayisi'].toDouble()
            : 1.0,
        profileImageUrl: json['profile_image_url'],
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
        'soyadi': soyadi,
        'e_posta': ePosta,
        'telefon': telefon,
        'renk': renk,
        'ucret_katsayisi': ucretKatsayisi,
        'profile_image_url': profileImageUrl,
        'is_active': isActive,
        'is_deleted': isDeleted,
        'ekleyen': ekleyen,
        'guncelleyen': guncelleyen,
        'isletme': isletme,
        'olusturulma_zamani': createdAt.toIso8601String(),
        'guncellenme_zamani': updatedAt.toIso8601String(),
      };

  static AntrenorModel empty() => AntrenorModel(
        id: 0,
        adi: '',
        soyadi: '',
        ePosta: null,
        telefon: null,
        renk: '#757575',
        ucretKatsayisi: 1.0,
        profileImageUrl: null,
        isActive: true,
        isDeleted: false,
        ekleyen: null,
        guncelleyen: null,
        isletme: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
