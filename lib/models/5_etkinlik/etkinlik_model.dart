import 'dart:convert';
import 'package:http/http.dart' as http;

/// UyeModel'in hafif DTO'su – backend'in "uyeler" listesindeki öğelerle uyumlu
class UyeLiteModel {
  final int id;
  final String ad;
  final String soyad;
  final String? telefon;
  final String? email;

  UyeLiteModel({
    required this.id,
    required this.ad,
    required this.soyad,
    this.telefon,
    this.email,
  });

  String get adSoyad => '$ad $soyad'.trim();

  factory UyeLiteModel.fromMap(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    String asStr(dynamic v) => (v ?? '').toString();

    return UyeLiteModel(
      id: asInt(j['id']),
      // Backend bazen 'adi/soyadi', bazen 'ad/soyad', bazen first/last_name döndürebilir
      ad: asStr(j['ad'] ?? j['adi'] ?? j['first_name']),
      soyad: asStr(j['soyad'] ?? j['soyadi'] ?? j['last_name']),
      telefon: j['telefon']?.toString(),
      email: j['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'soyad': soyad,
        if (telefon != null) 'telefon': telefon,
        if (email != null) 'email': email,
      };
}

/// Etkinlik DTO – Django ‹EtkinlikModel› ile uyumlu
class EtkinlikModel {
  /* -------------------------------------------------------------------------- */
  /*                              ZORUNLU alanlar                               */
  /* -------------------------------------------------------------------------- */
  final int id;

  /// UI geriye uyumluluk için alan adı `uyeList` bırakıldı.
  /// JSON'dan 'uyeler' (tercih edilen), yoksa 'uye_list'/'participants' -> `uyeList`
  final List<UyeLiteModel> uyeList;

  // Kort FK zorunlu
  final int kortId;
  final String kortAdi;

  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;

  final String seviye; // default'u var ama null olamaz
  final bool iptalMi;

  // BaseAbstract alanları
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
  /*                                   CTOR                                     */
  /* -------------------------------------------------------------------------- */
  EtkinlikModel({
    /* zorunlular */
    required this.id,
    required this.uyeList,
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
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);
    double? dbl(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int? asIntN(dynamic v) =>
        (v == null) ? null : (v is int ? v : int.tryParse(v.toString()));

    // Katılımcı listesi: öncelik 'uyeler' (SerializerMethodField), geri uyumluluk için 'uye_list'/'participants'
    final dynamic katilimciHam =
        j['uyeler'] ?? j['uye_list'] ?? j['participants'];
    final List<UyeLiteModel> uyeler = (katilimciHam is List)
        ? katilimciHam
            .map((e) => UyeLiteModel.fromMap(e as Map<String, dynamic>))
            .toList()
        : <UyeLiteModel>[];

    return EtkinlikModel(
      /* zorunlu */
      id: j['id'],
      uyeList: uyeler,
      kortId: j['kort'],
      kortAdi: j['kort_adi']?.toString() ?? '',
      baslangicTarihSaat: DateTime.parse(j['baslangic_tarih_saat']),
      bitisTarihSaat: DateTime.parse(j['bitis_tarih_saat']),
      seviye: j['seviye']?.toString() ?? '',
      iptalMi: (j['iptal_mi'] ?? false) == true,
      isActive: (j['is_active'] ?? true) == true,
      isDeleted: (j['is_deleted'] ?? false) == true,
      createdAt: DateTime.parse(j['olusturulma_zamani']),
      updatedAt: DateTime.parse(j['guncellenme_zamani']),
      /* opsiyonel */
      haftalikPlanKodu: j['haftalik_plan_kodu']?.toString(),
      urunId: asIntN(j['urun']),
      urunAdi: j['urun_adi']?.toString(),
      antrenorId: asIntN(j['antrenor']),
      antrenorAdi: j['antrenor_adi']?.toString(),
      yardimciAntrenorId: asIntN(j['yardimci_antrenor']),
      yardimciAntrenorAdi: j['yardimci_antrenor_adi']?.toString(),
      iptalEden: j['iptal_eden']?.toString(),
      iptalTarihSaat: date(j['iptal_tarih_saat']),
      ucret: dbl(j['ucret']),
      ekleyen: asIntN(j['ekleyen']),
      guncelleyen: asIntN(j['guncelleyen']),
      isletme: asIntN(j['isletme']),
    );
  }

  /* ----------------------- HTTP cevabından liste üretir --------------------- */
  static List<EtkinlikModel> fromJson(http.Response res) {
    final raw = json.decode(utf8.decode(res.bodyBytes));
    if (raw is List) {
      return raw
          .map((e) => EtkinlikModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (raw is Map<String, dynamic>) {
      // Bazı endpointler tek obje döndürebilir
      return [EtkinlikModel.fromMap(raw)];
    } else {
      return <EtkinlikModel>[];
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               Model → JSON                                 */
  /* -------------------------------------------------------------------------- */
  Map<String, dynamic> toJson() => {
        'id': id,
        'haftalik_plan_kodu': haftalikPlanKodu,
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

        // Backend uyumu: katılımcılar "uyeler" altında dönsün
        'uyeler': uyeList.map((e) => e.toJson()).toList(),
      };
}
