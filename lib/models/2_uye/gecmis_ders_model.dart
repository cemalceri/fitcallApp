import 'package:fitcall/common/tarih_util.dart';

// lib/models/2_uye/gecmis_ders_model.dart

/// Geçmiş dersteki üye katılım kaydı (yoklama)
class GecmisDersKatilim {
  final bool katildi;
  final bool planDisiMi;
  final String? notMetni;

  GecmisDersKatilim({
    required this.katildi,
    required this.planDisiMi,
    this.notMetni,
  });

  factory GecmisDersKatilim.fromJson(Map<String, dynamic> json) {
    return GecmisDersKatilim(
      katildi: json['katildi'] == true,
      planDisiMi: json['plan_disi_mi'] == true,
      notMetni: json['not_metni'],
    );
  }
}

/// Üyenin geçmiş derse verdiği puan
class GecmisDersPuan {
  final int puan;
  final String? yorum;

  GecmisDersPuan({required this.puan, this.yorum});

  factory GecmisDersPuan.fromJson(Map<String, dynamic> json) {
    return GecmisDersPuan(
      puan: (json['puan'] as num?)?.toInt() ?? 0,
      yorum: json['yorum'],
    );
  }
}

/// getUyeGecmisDersler cevabındaki tek ders kaydı
class GecmisDersModel {
  final int id;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String kortAdi;
  final String antrenorAdi;
  final String urunAdi;
  final String seviye;
  final bool iptalMi;

  /// Üyenin yoklama kaydı; yoklama girilmemişse null.
  final GecmisDersKatilim? katilim;

  /// Antrenörün ders sonucu: true=yapıldı, false=yapılmadı, null=girilmedi.
  final bool? dersYapildi;

  /// Üyenin verdiği puan; değerlendirme yapılmamışsa null.
  final GecmisDersPuan? puanim;

  GecmisDersModel({
    required this.id,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.kortAdi,
    required this.antrenorAdi,
    required this.urunAdi,
    required this.seviye,
    required this.iptalMi,
    this.katilim,
    this.dersYapildi,
    this.puanim,
  });

  factory GecmisDersModel.fromJson(Map<String, dynamic> json) {
    return GecmisDersModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      baslangicTarihSaat:
          parseApiTarih(json['baslangic_tarih_saat'] ?? '') ??
              DateTime.now(),
      bitisTarihSaat:
          parseApiTarih(json['bitis_tarih_saat'] ?? '') ?? DateTime.now(),
      kortAdi: json['kort_adi'] ?? '',
      antrenorAdi: json['antrenor_adi'] ?? '',
      urunAdi: json['urun_adi'] ?? '',
      seviye: json['seviye'] ?? '',
      iptalMi: json['iptal_mi'] == true,
      katilim: json['katilim'] != null
          ? GecmisDersKatilim.fromJson(
              (json['katilim'] as Map).cast<String, dynamic>())
          : null,
      dersYapildi: json['ders_yapildi'],
      puanim: json['puanim'] != null
          ? GecmisDersPuan.fromJson(
              (json['puanim'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

/// getUyeGecmisDersler cevabı (pencere bilgisi + dersler)
class GecmisDerslerResponse {
  final DateTime? baslangic;
  final DateTime? bitis;
  final List<GecmisDersModel> dersler;

  GecmisDerslerResponse({this.baslangic, this.bitis, required this.dersler});

  factory GecmisDerslerResponse.fromJson(Map<String, dynamic> json) {
    return GecmisDerslerResponse(
      baslangic: parseApiTarih(json['baslangic'] ?? ''),
      bitis: parseApiTarih(json['bitis'] ?? ''),
      dersler: ((json['dersler'] as List?) ?? const [])
          .map((e) =>
              GecmisDersModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
