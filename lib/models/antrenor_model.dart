/// Antrenör bilgilerini içeren model
class TrainerModel {
  final int id;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int isletme;
  final String adi;
  final String ePosta;
  final String? telefon;
  final String? renk;
  final String? ucretKatsayisi;
  final int user;

  TrainerModel({
    required this.id,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.isletme,
    required this.adi,
    required this.ePosta,
    this.telefon,
    this.renk,
    this.ucretKatsayisi,
    required this.user,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['id'] ?? 0,
      isActive: json['is_active'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isletme: json['isletme'] ?? 0,
      adi: json['adi'] ?? '',
      ePosta: json['e_posta'] ?? '',
      telefon: json['telefon'],
      renk: json['renk'],
      ucretKatsayisi: json['ucret_katsayisi']?.toString(),
      user: json['user'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'isletme': isletme,
      'adi': adi,
      'e_posta': ePosta,
      'telefon': telefon,
      'renk': renk,
      'ucret_katsayisi': ucretKatsayisi,
      'user': user,
    };
  }
}
