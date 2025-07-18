import 'dart:convert';
import 'package:http/http.dart' as http;

/// Etkinlik DTO – Django ‹EtkinlikModel› eşlemesi
class EtkinlikModel {
  /* -------------------------------------------------------------------------- */
  /*                              ZORUNLU alanlar                               */
  /* -------------------------------------------------------------------------- */
  final int id;

  // Grup FK zorunlu
  final int grupId;
  final String grupAdi;

  // Kort FK zorunlu
  final int kortId;
  final String kortAdi;

  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;

  final String seviye; // default'u var ama null olamaz
  final bool iptalMi;

  // BaseAbstract alanları da her kayıtta bulunur
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /* -------------------------------------------------------------------------- */
  /*                             OPSİYONEL alanlar                              */
  /* -------------------------------------------------------------------------- */
  final String? haftalikPlanKodu;

  final int? urunId;
  final String? urunAdi;

  final int? antrenorId;
  final String? antrenorAdi;

  final int? yardimciAntrenorId;
  final String? yardimciAntrenorAdi;

  final String? iptalEden;
  final DateTime? iptalTarihSaat;
  final double? ucret;

  // Diğer meta
  final int? ekleyen;
  final int? guncelleyen;
  final int? isletme;

  /* -------------------------------------------------------------------------- */
  /*                                 CTOR                                       */
  /* -------------------------------------------------------------------------- */
  EtkinlikModel({
    /* zorunlular */
    required this.id,
    required this.grupId,
    required this.grupAdi,
    required this.kortId,
    required this.kortAdi,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.seviye,
    required this.iptalMi,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    /* opsiyoneller */
    this.haftalikPlanKodu,
    this.urunId,
    this.urunAdi,
    this.antrenorId,
    this.antrenorAdi,
    this.yardimciAntrenorId,
    this.yardimciAntrenorAdi,
    this.iptalEden,
    this.iptalTarihSaat,
    this.ucret,
    this.ekleyen,
    this.guncelleyen,
    this.isletme,
  });

  /* -------------------------------------------------------------------------- */
  /*                              JSON → Model                                  */
  /* -------------------------------------------------------------------------- */
  factory EtkinlikModel.fromMap(Map<String, dynamic> j) {
    DateTime? _d(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);
    double? _dbl(dynamic v) => v == null ? null : double.tryParse(v.toString());

    return EtkinlikModel(
      /* zorunlu */
      id: j['id'],
      grupId: j['grup'],
      grupAdi: j['grup_adi'] ?? '',
      kortId: j['kort'],
      kortAdi: j['kort_adi'] ?? '',
      baslangicTarihSaat: DateTime.parse(j['baslangic_tarih_saat']),
      bitisTarihSaat: DateTime.parse(j['bitis_tarih_saat']),
      seviye: j['seviye'] ?? '',
      iptalMi: j['iptal_mi'] ?? false,
      isActive: j['is_active'] ?? true,
      isDeleted: j['is_deleted'] ?? false,
      createdAt: DateTime.parse(j['olusturulma_zamani']),
      updatedAt: DateTime.parse(j['guncellenme_zamani']),
      /* opsiyonel */
      haftalikPlanKodu: j['haftalik_plan_kodu'],
      urunId: j['urun'],
      urunAdi: j['urun_adi'],
      antrenorId: j['antrenor'],
      antrenorAdi: j['antrenor_adi'],
      yardimciAntrenorId: j['yardimci_antrenor'],
      yardimciAntrenorAdi: j['yardimci_antrenor_adi'],
      iptalEden: j['iptal_eden'],
      iptalTarihSaat: _d(j['iptal_tarih_saat']),
      ucret: _dbl(j['ucret']),
      ekleyen: j['ekleyen'],
      guncelleyen: j['guncelleyen'],
      isletme: j['isletme'],
    );
  }

  /* ----------------------- HTTP cevabından liste üretir --------------------- */
  static List<EtkinlikModel> fromJson(http.Response res) {
    final raw = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return raw.map((e) => EtkinlikModel.fromMap(e)).toList();
  }

  /* -------------------------------------------------------------------------- */
  /*                               Model → JSON                                 */
  /* -------------------------------------------------------------------------- */
  Map<String, dynamic> toJson() => {
        'id': id,
        'haftalik_plan_kodu': haftalikPlanKodu,
        'grup': grupId,
        'grup_adi': grupAdi,
        'urun': urunId,
        'urun_adi': urunAdi,
        'baslangic_tarih_saat': baslangicTarihSaat.toIso8601String(),
        'bitis_tarih_saat': bitisTarihSaat.toIso8601String(),
        'kort': kortId,
        'kort_adi': kortAdi,
        'seviye': seviye,
        'antrenor': antrenorId,
        'antrenor_adi': antrenorAdi,
        'yardimci_antrenor': yardimciAntrenorId,
        'yardimci_antrenor_adi': yardimciAntrenorAdi,
        'iptal_mi': iptalMi,
        'iptal_eden': iptalEden,
        'iptal_tarih_saat': iptalTarihSaat?.toIso8601String(),
        'ucret': ucret,
        'is_active': isActive,
        'is_deleted': isDeleted,
        'olusturulma_zamani': createdAt.toIso8601String(),
        'guncellenme_zamani': updatedAt.toIso8601String(),
        'ekleyen': ekleyen,
        'guncelleyen': guncelleyen,
        'isletme': isletme,
      };
}
