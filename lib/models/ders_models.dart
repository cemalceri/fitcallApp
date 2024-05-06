import 'dart:convert';

class DersModel {
  final int id;
  final String? antrenorAdi;
  final String? kortAdi;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String abonelikTipi;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String seviye;
  final bool? tamamlandiAntrenor;
  final bool? tamamlandiYonetici;
  final bool? tamamlandiUye;
  final bool? iptalMi;
  final String? iptalEden;
  final DateTime? iptalTarihSaat;
  final String? aciklama;
  final int grup;
  final int kort;
  final int? antrenor;
  final int user;

  DersModel({
    required this.id,
    this.antrenorAdi,
    this.kortAdi,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.abonelikTipi,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.seviye,
    required this.tamamlandiAntrenor,
    required this.tamamlandiYonetici,
    required this.tamamlandiUye,
    required this.iptalMi,
    this.iptalEden,
    this.iptalTarihSaat,
    this.aciklama,
    required this.grup,
    required this.kort,
    required this.antrenor,
    required this.user,
  });

  static List<DersModel?> fromJson(response) {
    List<DersModel?> dersModelListesi = [];
    List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
    for (var json in list) {
      dersModelListesi.add(DersModel(
        id: json['id'] ?? 0,
        antrenorAdi: json['antrenor_adi'],
        kortAdi: json['kort_adi'] ?? '',
        isActive: json['is_active'] ?? false,
        isDeleted: json['is_deleted'] ?? false,
        createdAt: DateTime.parse(json['created_at'] ?? ''),
        updatedAt: DateTime.parse(json['updated_at'] ?? ''),
        abonelikTipi: json['abonelik_tipi'] ?? '',
        baslangicTarihSaat: DateTime.parse(json['baslangic_tarih_saat'] ?? ''),
        bitisTarihSaat: DateTime.parse(json['bitis_tarih_saat'] ?? ''),
        seviye: json['seviye'] ?? '',
        tamamlandiAntrenor: json['tamamlandi_antrenor'] ?? false,
        tamamlandiYonetici: json['tamamlandi_yonetici'] ?? false,
        tamamlandiUye: json['tamamlandi_uye'] ?? false,
        iptalMi: json['iptal_mi'] ?? false,
        iptalEden: json['iptal_eden'] ?? '',
        iptalTarihSaat: json['iptal_tarih_saat'] != null
            ? DateTime.parse(json['iptal_tarih_saat'])
            : null,
        aciklama: json['aciklama'] ?? '',
        grup: json['grup'] ?? 0,
        kort: json['kort'] ?? 0,
        antrenor: json['antrenor'] ?? 0,
        user: json['user'] ?? 0,
      ));
    }
    return dersModelListesi;
  }
}
