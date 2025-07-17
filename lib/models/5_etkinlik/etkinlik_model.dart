import 'dart:convert';

/// EtkinlikModel
class EtkinlikModel {
  final int id;
  final String? haftalikPlanKodu;
  final String grup; // Django FK: sadece ad
  final String? urun; // Django FK: sadece ad
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String kort; // Django FK: sadece ad
  final String seviye;
  final String? antrenor; // Django FK: sadece ad
  final String? yardimciAntrenor; // Django FK: sadece ad
  final bool iptalMi;
  final String? iptalEden;
  final DateTime? iptalTarihSaat;
  final double? ucret;

  // BaseAbstract alanları
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  EtkinlikModel({
    required this.id,
    this.haftalikPlanKodu,
    required this.grup,
    this.urun,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.kort,
    required this.seviye,
    this.antrenor,
    this.yardimciAntrenor,
    required this.iptalMi,
    this.iptalEden,
    this.iptalTarihSaat,
    this.ucret,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tekil JSON’dan nesne oluşturur
  factory EtkinlikModel.fromMap(Map<String, dynamic> json) {
    DateTime? _tryParse(String? value) =>
        (value == null || value.isEmpty) ? null : DateTime.parse(value);

    return EtkinlikModel(
      id: json['id'] ?? 0,
      haftalikPlanKodu: json['haftalik_plan_kodu'],
      grup: json['grup'] ?? '',
      urun: json['urun'],
      baslangicTarihSaat: DateTime.parse(json['baslangic_tarih_saat'] ?? ''),
      bitisTarihSaat: DateTime.parse(json['bitis_tarih_saat'] ?? ''),
      kort: json['kort'] ?? '',
      seviye: json['seviye'] ?? '',
      antrenor: json['antrenor'],
      yardimciAntrenor: json['yardimci_antrenor'],
      iptalMi: json['iptal_mi'] ?? false,
      iptalEden: json['iptal_eden'],
      iptalTarihSaat: _tryParse(json['iptal_tarih_saat']),
      ucret: json['ucret'] != null
          ? double.tryParse(json['ucret'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['olusturulma_zamani'] ?? ''),
      updatedAt: DateTime.parse(json['guncellenme_zamani'] ?? ''),
    );
  }

  /// HTTP cevabından liste oluşturur
  static List<EtkinlikModel> fromJson(response) {
    final List<dynamic> list =
        json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list.map((item) => EtkinlikModel.fromMap(item)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'haftalik_plan_kodu': haftalikPlanKodu,
      'grup': grup,
      'urun': urun,
      'baslangic_tarih_saat': baslangicTarihSaat.toIso8601String(),
      'bitis_tarih_saat': bitisTarihSaat.toIso8601String(),
      'kort': kort,
      'seviye': seviye,
      'antrenor': antrenor,
      'yardimci_antrenor': yardimciAntrenor,
      'iptal_mi': iptalMi,
      'iptal_eden': iptalEden,
      'iptal_tarih_saat': iptalTarihSaat?.toIso8601String(),
      'ucret': ucret,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'olusturulma_zamani': createdAt.toIso8601String(),
      'guncellenme_zamani': updatedAt.toIso8601String(),
    };
  }
}
