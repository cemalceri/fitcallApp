/// UyeEtkinlikOnayModel  (Django: EtkinlikOnayModel)
class EtkinlikOnayModel {
  final int id;
  final String etkinlik; // FK: Etkinlik adı
  final String? uye; // FK: Üye adı
  final String? onaylayan; // FK: User adı
  final String rol; // Onay rolü (OnayRoluEnum)
  bool tamamlandi; // Tamamlandı mı?
  String? aciklama; // Açıklama
  final DateTime onayTarihi; // onay_tarihi

  // BaseAbstract ortak alanları
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt; // olusturulma_zamani
  final DateTime updatedAt; // guncellenme_zamani

  EtkinlikOnayModel({
    required this.id,
    required this.etkinlik,
    this.uye,
    this.onaylayan,
    required this.rol,
    required this.tamamlandi,
    this.aciklama,
    required this.onayTarihi,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _tryParse(String? v) =>
      (v == null || v.isEmpty) ? null : DateTime.parse(v);

  factory EtkinlikOnayModel.fromJson(Map<String, dynamic> json) {
    return EtkinlikOnayModel(
      id: json['id'] ?? 0,
      etkinlik: json['etkinlik'] ?? '',
      uye: json['uye'],
      onaylayan: json['onaylayan'],
      rol: json['rol'] ?? '',
      tamamlandi: json['tamamlandi'] ?? false,
      aciklama: json['aciklama'],
      onayTarihi: _tryParse(json['onay_tarihi']) ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: _tryParse(json['olusturulma_zamani']) ?? DateTime.now(),
      updatedAt: _tryParse(json['guncellenme_zamani']) ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'etkinlik': etkinlik,
      'uye': uye,
      'onaylayan': onaylayan,
      'rol': rol,
      'tamamlandi': tamamlandi,
      'aciklama': aciklama,
      'onay_tarihi': onayTarihi.toIso8601String(),
      'is_active': isActive,
      'is_deleted': isDeleted,
      'olusturulma_zamani': createdAt.toIso8601String(),
      'guncellenme_zamani': updatedAt.toIso8601String(),
    };
  }

  static EtkinlikOnayModel empty() {
    return EtkinlikOnayModel(
      id: 0,
      etkinlik: '',
      uye: null,
      onaylayan: null,
      rol: '',
      tamamlandi: false,
      aciklama: null,
      onayTarihi: DateTime.now(),
      isActive: true,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
