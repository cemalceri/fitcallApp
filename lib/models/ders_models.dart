import 'dart:convert';

class DersModel {
  final int id;
  final String? haftalikPlanKodu; // Django: haftalik_plan_kodu
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
  bool? tamamlandiAntrenor;
  final bool? tamamlandiYonetici;
  final bool? tamamlandiUye;
  final bool? iptalMi;
  final String? iptalEden;
  final DateTime? iptalTarihSaat;
  final String? aciklama;
  String? antrenorAciklama; // Django: antrenor_aciklama
  final int grup;
  final int kort;
  final int? antrenor;
  final int? yardimciAntrenor; // Django: yardimci_antrenor
  final int user;
  final double? ucret; // Django: ucret

  DersModel({
    required this.id,
    this.haftalikPlanKodu,
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
    this.antrenorAciklama,
    required this.grup,
    required this.kort,
    required this.antrenor,
    required this.yardimciAntrenor,
    required this.user,
    required this.ucret,
  });

  static List<DersModel?> fromJson(response) {
    List<DersModel?> dersModelListesi = [];
    List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
    for (var jsonItem in list) {
      dersModelListesi.add(DersModel(
        id: jsonItem['id'] ?? 0,
        haftalikPlanKodu: jsonItem['haftalik_plan_kodu'],
        antrenorAdi: jsonItem['antrenor_adi'],
        kortAdi: jsonItem['kort_adi'] ?? '',
        isActive: jsonItem['is_active'] ?? false,
        isDeleted: jsonItem['is_deleted'] ?? false,
        createdAt: DateTime.parse(jsonItem['created_at'] ?? ''),
        updatedAt: DateTime.parse(jsonItem['updated_at'] ?? ''),
        abonelikTipi: jsonItem['abonelik_tipi'] ?? '',
        baslangicTarihSaat:
            DateTime.parse(jsonItem['baslangic_tarih_saat'] ?? ''),
        bitisTarihSaat: DateTime.parse(jsonItem['bitis_tarih_saat'] ?? ''),
        seviye: jsonItem['seviye'] ?? '',
        tamamlandiAntrenor: jsonItem['tamamlandi_antrenor'] ?? false,
        tamamlandiYonetici: jsonItem['tamamlandi_yonetici'] ?? false,
        tamamlandiUye: jsonItem['tamamlandi_uye'] ?? false,
        iptalMi: jsonItem['iptal_mi'] ?? false,
        iptalEden: jsonItem['iptal_eden'] ?? '',
        iptalTarihSaat: jsonItem['iptal_tarih_saat'] != null
            ? DateTime.parse(jsonItem['iptal_tarih_saat'])
            : null,
        aciklama: jsonItem['aciklama'] ?? '',
        antrenorAciklama: jsonItem['antrenor_aciklama'] ?? '',
        grup: jsonItem['grup'] ?? 0,
        kort: jsonItem['kort'] ?? 0,
        antrenor: jsonItem['antrenor'] ?? 0,
        yardimciAntrenor: jsonItem['yardimci_antrenor'],
        user: jsonItem['user'] ?? 0,
        ucret: jsonItem['ucret'] != null
            ? double.tryParse(jsonItem['ucret'].toString())
            : null,
      ));
    }
    return dersModelListesi;
  }
}
