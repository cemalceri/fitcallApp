import 'dart:convert';

class UyeEtkinlikOnayModel {
  final int id;
  final int uye; // JSON üzerinden gelen String (StringRelatedField)
  bool tamamlandi;
  String? aciklama;

  UyeEtkinlikOnayModel({
    required this.id,
    required this.uye,
    required this.tamamlandi,
    this.aciklama,
  });

  factory UyeEtkinlikOnayModel.fromJson(Map<String, dynamic> json) {
    return UyeEtkinlikOnayModel(
      id: json['id'],
      uye: json['uye'],
      tamamlandi: json['tamamlandi'] ?? false,
      aciklama: json['aciklama'] ?? '',
    );
  }
}

class EtkinlikModel {
  final int id;
  final String? haftalikPlanKodu; // Django: haftalik_plan_kodu
  final String? antrenorAdi; // JSON üzerinden alınan hesaplanmış alan
  final String? kortAdi; // JSON üzerinden alınan hesaplanmış alan
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String abonelikTipi;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String seviye;
  bool? tamamlandiAntrenor; // Django: tamamlandi_antrenor
  bool? tamamlandiYardimciAntrenor; // Django: tamamlandi_yardimci_antrenor
  bool? tamamlandiYonetici; // Django: tamamlandi_yonetici
  final bool? iptalMi;
  final String? iptalEden;
  final DateTime? iptalTarihSaat;
  String? antrenorAciklama; // Django: antrenor_aciklama
  String? yoneticiAciklama; // Django: yonetici_aciklama
  final int grup; // Django: grup (FK id)
  final String grupAdi; // Grup bilgisinin gösterimi (computed)
  final int kort; // Django: kort (FK id)
  final int? antrenor; // Django: antrenor (FK id)
  final int? yardimciAntrenor; // Django: yardimci_antrenor (FK id)
  String? yardimciAntrenorAciklama; // Django: yardimci_antrenor_aciklama
  final int user; // Django: user (FK id)
  final double? ucret; // Django: ucret
  final List<UyeEtkinlikOnayModel>? uyeOnaylari; // İlişkili üye onayları

  EtkinlikModel({
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
    required this.tamamlandiYardimciAntrenor,
    required this.tamamlandiYonetici,
    required this.iptalMi,
    this.iptalEden,
    this.iptalTarihSaat,
    this.antrenorAciklama,
    this.yoneticiAciklama,
    required this.grup,
    required this.grupAdi,
    required this.kort,
    required this.antrenor,
    required this.yardimciAntrenor,
    required this.user,
    required this.ucret,
    this.yardimciAntrenorAciklama,
    this.uyeOnaylari,
  });

  static List<EtkinlikModel>? fromJson(response) {
    List<EtkinlikModel>? etkinlikModelListesi = [];
    List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
    for (var jsonItem in list) {
      etkinlikModelListesi.add(EtkinlikModel(
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
        tamamlandiYardimciAntrenor:
            jsonItem['tamamlandi_yardimci_antrenor'] ?? false,
        tamamlandiYonetici: jsonItem['tamamlandi_yonetici'] ?? false,
        iptalMi: jsonItem['iptal_mi'] ?? false,
        iptalEden: jsonItem['iptal_eden'] ?? '',
        iptalTarihSaat: jsonItem['iptal_tarih_saat'] != null
            ? DateTime.parse(jsonItem['iptal_tarih_saat'])
            : null,
        antrenorAciklama: jsonItem['antrenor_aciklama'] ?? '',
        yoneticiAciklama: jsonItem['yonetici_aciklama'] ?? '',
        grup: jsonItem['grup'] ?? 0,
        grupAdi: jsonItem['grup_adi'] ?? '',
        kort: jsonItem['kort'] ?? 0,
        antrenor: jsonItem['antrenor'] ?? 0,
        yardimciAntrenor: jsonItem['yardimci_antrenor'],
        user: jsonItem['user'] ?? 0,
        ucret: jsonItem['ucret'] != null
            ? double.tryParse(jsonItem['ucret'].toString())
            : null,
        yardimciAntrenorAciklama: jsonItem['yardimci_antrenor_aciklama'] ?? '',
        uyeOnaylari: jsonItem['uye_onaylari'] != null
            ? List<UyeEtkinlikOnayModel>.from(jsonItem['uye_onaylari']
                .map((x) => UyeEtkinlikOnayModel.fromJson(x)))
            : [],
      ));
    }
    return etkinlikModelListesi;
  }
}
