// lib/models/5_etkinlik/etkinlik_model.dart

import 'package:fitcall/common/tarih_util.dart';
import 'dart:convert';
import 'package:fitcall/models/3_antrenor/ders_devir_talebi_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Üye için katılım teyit bilgisi (EtkinlikTeyitModel'den)
class UyeTeyit {
  final int id;
  final int uyeId;
  final bool?
      katilacakMi; // null = bekliyor, true = katılacak, false = katılmayacak
  final String? aciklama;
  final DateTime? teyitTarihi;
  final bool okundu;

  UyeTeyit({
    required this.id,
    required this.uyeId,
    this.katilacakMi,
    this.aciklama,
    this.teyitTarihi,
    required this.okundu,
  });

  factory UyeTeyit.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);

    return UyeTeyit(
      id: j['id'] ?? 0,
      uyeId: j['uye'] ?? j['uye_id'] ?? 0,
      katilacakMi: j['katilacak_mi'],
      aciklama: j['aciklama']?.toString(),
      teyitTarihi: date(j['teyit_tarihi']),
      okundu: (j['okundu'] ?? false) == true,
    );
  }

  /// Teyit durumu text
  String get durumText {
    if (katilacakMi == null) return 'Bekliyor';
    return katilacakMi! ? 'Katılacağım' : 'Katılmayacağım';
  }

  /// Teyit durumu renk
  Color get durumColor {
    if (katilacakMi == null) return Colors.grey;
    return katilacakMi! ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  }

  /// Teyit durumu ikon
  IconData get durumIcon {
    if (katilacakMi == null) return Icons.help_outline_rounded;
    return katilacakMi! ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }
}

/// Antrenör ders onayı (EtkinlikOnayModel'den rol=antrenor)
class AntrenorOnay {
  final int id;
  final bool tamamlandi;
  final String? onayRedIptalNedeni;
  final String? aciklama;
  final DateTime? onayTarihi;
  final int? onaylayanId;

  AntrenorOnay({
    required this.id,
    required this.tamamlandi,
    this.onayRedIptalNedeni,
    this.aciklama,
    this.onayTarihi,
    this.onaylayanId,
  });

  factory AntrenorOnay.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);

    return AntrenorOnay(
      id: j['id'] ?? 0,
      tamamlandi: (j['tamamlandi'] ?? false) == true,
      onayRedIptalNedeni: j['onay_red_iptal_nedeni']?.toString(),
      aciklama: j['aciklama']?.toString(),
      onayTarihi: date(j['onay_tarihi']),
      onaylayanId: j['onaylayan_id'],
    );
  }

  /// Onay durumu text
  String get durumText => tamamlandi ? 'Onaylandı' : 'Bekliyor';

  /// Onay durumu renk
  Color get durumColor => tamamlandi ? const Color(0xFF10B981) : Colors.orange;

  /// Onay durumu ikon
  IconData get durumIcon =>
      tamamlandi ? Icons.check_circle_rounded : Icons.schedule_rounded;
}

/// Üye ders onayı (EtkinlikOnayModel'den rol=uye)
class UyeDersOnay {
  final int id;
  final int? uyeId;
  final bool tamamlandi;
  final String? onayRedIptalNedeni;
  final String? aciklama;
  final DateTime? onayTarihi;
  final int? onaylayanId;

  UyeDersOnay({
    required this.id,
    this.uyeId,
    required this.tamamlandi,
    this.onayRedIptalNedeni,
    this.aciklama,
    this.onayTarihi,
    this.onaylayanId,
  });

  factory UyeDersOnay.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);

    return UyeDersOnay(
      id: j['id'] ?? 0,
      uyeId: j['uye_id'],
      tamamlandi: (j['tamamlandi'] ?? false) == true,
      onayRedIptalNedeni: j['onay_red_iptal_nedeni']?.toString(),
      aciklama: j['aciklama']?.toString(),
      onayTarihi: date(j['onay_tarihi']),
      onaylayanId: j['onaylayan_id'],
    );
  }

  /// Onay durumu text
  String get durumText => tamamlandi ? 'Onaylandı' : 'Bekliyor';

  /// Onay durumu renk
  Color get durumColor => tamamlandi ? const Color(0xFF10B981) : Colors.orange;

  /// Onay durumu ikon
  IconData get durumIcon =>
      tamamlandi ? Icons.check_circle_rounded : Icons.schedule_rounded;
}

/// Yönetici ders onayı (EtkinlikOnayModel'den rol=yonetici)
class YoneticiOnay {
  final int id;
  final bool tamamlandi;
  final String? onayRedIptalNedeni;
  final String? aciklama;
  final DateTime? onayTarihi;
  final int? onaylayanId;

  YoneticiOnay({
    required this.id,
    required this.tamamlandi,
    this.onayRedIptalNedeni,
    this.aciklama,
    this.onayTarihi,
    this.onaylayanId,
  });

  factory YoneticiOnay.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);

    return YoneticiOnay(
      id: j['id'] ?? 0,
      tamamlandi: (j['tamamlandi'] ?? false) == true,
      onayRedIptalNedeni: j['onay_red_iptal_nedeni']?.toString(),
      aciklama: j['aciklama']?.toString(),
      onayTarihi: date(j['onay_tarihi']),
      onaylayanId: j['onaylayan_id'],
    );
  }

  /// Onay durumu text
  String get durumText => tamamlandi ? 'Onaylandı' : 'Bekliyor';

  /// Onay durumu renk
  Color get durumColor => tamamlandi ? const Color(0xFF10B981) : Colors.orange;

  /// Onay durumu ikon
  IconData get durumIcon =>
      tamamlandi ? Icons.check_circle_rounded : Icons.schedule_rounded;
}

/// UyeModel'in hafif DTO'su
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

/// Etkinlik DTO
class EtkinlikModel {
  /* ZORUNLU ALANLAR */
  final int id;
  final List<UyeLiteModel> uyeList;
  final int kortId;
  final String kortAdi;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String seviye;
  final bool iptalMi;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  /* OPSİYONEL ALANLAR */
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
  final int? ekleyen;
  final int? guncelleyen;
  final int? isletme;
  final String? iptalEdenAdi;
  final AktifDevirTalebiModel? aktifDevirTalebi;

  /* TEYİT VE ONAY BİLGİLERİ */
  /// Üye teyitleri (EtkinlikTeyitModel'den - katılacak mı?)
  final List<UyeTeyit>? uyeTeyitleri;

  /// Antrenör onayı (EtkinlikOnayModel'den - ders tamamlandı mı?)
  final AntrenorOnay? antrenorOnayi;

  /// Yönetici onayı (EtkinlikOnayModel'den - ders tamamlandı mı?)
  final YoneticiOnay? yoneticiOnayi;

  /// Üye ders onayları (EtkinlikOnayModel'den - ders tamamlandı mı?)
  final List<UyeDersOnay>? uyeDersOnaylari;

  EtkinlikModel({
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
    this.uyeTeyitleri,
    this.antrenorOnayi,
    this.uyeDersOnaylari,
    this.yoneticiOnayi,
    this.iptalEdenAdi,
    this.aktifDevirTalebi,
  });

  factory EtkinlikModel.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);
    double? dbl(dynamic v) => v == null ? null : double.tryParse(v.toString());
    int? asIntN(dynamic v) =>
        (v == null) ? null : (v is int ? v : int.tryParse(v.toString()));

    // Katılımcı listesi
    final dynamic katilimciHam =
        j['uyeler'] ?? j['uye_list'] ?? j['participants'];
    final List<UyeLiteModel> uyeler = (katilimciHam is List)
        ? katilimciHam
            .map((e) => UyeLiteModel.fromMap(e as Map<String, dynamic>))
            .toList()
        : <UyeLiteModel>[];

    // Üye teyitleri - yeni isim öncelikli, eski isim fallback
    final dynamic teyitHam =
        j['uye_teyitleri'] ?? j['uye_onaylari'] ?? j['teyitler'];
    final List<UyeTeyit>? teyitler = (teyitHam is List && teyitHam.isNotEmpty)
        ? teyitHam
            .map((e) => UyeTeyit.fromMap(e as Map<String, dynamic>))
            .toList()
        : null;

    // Antrenör onayı - YENİ
    final dynamic antrenorOnayHam = j['antrenor_onayi'];
    final AntrenorOnay? antrenorOnay = (antrenorOnayHam is Map<String, dynamic>)
        ? AntrenorOnay.fromMap(antrenorOnayHam)
        : null;

    // Yönetici onayı - YENİ
    final dynamic yoneticiOnayHam = j['yonetici_onayi'];
    final YoneticiOnay? yoneticiOnay = (yoneticiOnayHam is Map<String, dynamic>)
        ? YoneticiOnay.fromMap(yoneticiOnayHam)
        : null;

    // Üye ders onayları - YENİ
    final dynamic uyeDersOnayHam = j['uye_ders_onaylari'];
    final List<UyeDersOnay>? uyeDersOnaylar =
        (uyeDersOnayHam is List && uyeDersOnayHam.isNotEmpty)
            ? uyeDersOnayHam
                .map((e) => UyeDersOnay.fromMap(e as Map<String, dynamic>))
                .toList()
            : null;

    final dynamic devirHam = j['aktif_devir_talebi'];
    final AktifDevirTalebiModel? devirTalebi =
        (devirHam is Map<String, dynamic>)
            ? AktifDevirTalebiModel.fromMap(devirHam)
            : null;

    return EtkinlikModel(
      id: j['id'],
      uyeList: uyeler,
      kortId: j['kort'],
      kortAdi: j['kort_adi']?.toString() ?? '',
      baslangicTarihSaat: parseApiTarihOrNow(j['baslangic_tarih_saat']),
      bitisTarihSaat: parseApiTarihOrNow(j['bitis_tarih_saat']),
      seviye: j['seviye']?.toString() ?? '',
      iptalMi: (j['iptal_mi'] ?? false) == true,
      isActive: (j['is_active'] ?? true) == true,
      isDeleted: (j['is_deleted'] ?? false) == true,
      createdAt: parseApiTarihOrNow(j['olusturulma_zamani']),
      updatedAt: parseApiTarihOrNow(j['guncellenme_zamani']),
      haftalikPlanKodu:
          (j['sabit_plan'] ?? j['haftalik_plan_kodu'])?.toString(),
      urunId: asIntN(j['urun']),
      urunAdi: j['urun_adi']?.toString(),
      antrenorId: asIntN(j['antrenor']),
      antrenorAdi: j['antrenor_adi']?.toString(),
      yardimciAntrenorId: asIntN(j['yardimci_antrenor']),
      yardimciAntrenorAdi: j['yardimci_antrenor_adi']?.toString(),
      iptalEden: j['iptal_eden']?.toString(),
      iptalTarihSaat:
          date((j['iptal_tarihi'] ?? j['iptal_tarih_saat']) as String?),
      ucret: dbl(j['ucret']),
      ekleyen: asIntN(j['ekleyen']),
      guncelleyen: asIntN(j['guncelleyen']),
      isletme: asIntN(j['isletme']),
      uyeTeyitleri: teyitler,
      antrenorOnayi: antrenorOnay,
      uyeDersOnaylari: uyeDersOnaylar,
      yoneticiOnayi: yoneticiOnay,
      iptalEdenAdi: j['iptal_eden_adi']?.toString(),
      aktifDevirTalebi: devirTalebi,
    );
  }

  static List<EtkinlikModel> fromJson(http.Response res) {
    final raw = json.decode(utf8.decode(res.bodyBytes));
    if (raw is List) {
      return raw
          .map((e) => EtkinlikModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (raw is Map<String, dynamic>) {
      return [EtkinlikModel.fromMap(raw)];
    } else {
      return <EtkinlikModel>[];
    }
  }

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
        'uyeler': uyeList.map((e) => e.toJson()).toList(),
        'aktif_devir_talebi': null, // backend tarafından doldurulur
      };

  /* ==================== TEYİT HELPER METODLARI ==================== */

  /// Bu üyenin teyit bilgisini getir
  UyeTeyit? getTeyitBilgisi(int uyeId) {
    if (uyeTeyitleri == null) return null;
    try {
      return uyeTeyitleri!.firstWhere((t) => t.uyeId == uyeId);
    } catch (e) {
      return null;
    }
  }

  /// Bu üye teyit vermiş mi?
  bool teyitVerilmisMi(int uyeId) {
    final teyit = getTeyitBilgisi(uyeId);
    return teyit?.katilacakMi != null;
  }

  /// Bu üye katılacak mı?
  bool? katilacakMi(int uyeId) {
    return getTeyitBilgisi(uyeId)?.katilacakMi;
  }

  /* ==================== ONAY HELPER METODLARI ==================== */

  /// Antrenör onayı verilmiş mi?
  bool get antrenorOnayiVerilmisMi => antrenorOnayi?.tamamlandi ?? false;

  /// Bu üyenin ders onayını getir
  UyeDersOnay? getUyeDersOnayi(int uyeId) {
    if (uyeDersOnaylari == null) return null;
    try {
      return uyeDersOnaylari!.firstWhere((o) => o.uyeId == uyeId);
    } catch (e) {
      return null;
    }
  }

  /// Bu üye ders onayı vermiş mi?
  bool uyeDersOnayiVerilmisMi(int uyeId) {
    final onay = getUyeDersOnayi(uyeId);
    return onay?.tamamlandi ?? false;
  }

  /// Tüm üyeler onay vermiş mi?
  bool get tumUyelerOnayVermisMi {
    if (uyeDersOnaylari == null || uyeDersOnaylari!.isEmpty) return false;
    if (uyeList.isEmpty) return true;

    for (final uye in uyeList) {
      if (!uyeDersOnayiVerilmisMi(uye.id)) return false;
    }
    return true;
  }

  /// Yönetici onayı verilmiş mi?
  bool get yoneticiOnayiVerilmisMi => yoneticiOnayi?.tamamlandi ?? false;

  /// Ders tam onaylı mı? (antrenör + yönetici + tüm üyeler)
  bool get dersTamOnayliMi =>
      antrenorOnayiVerilmisMi &&
      yoneticiOnayiVerilmisMi &&
      tumUyelerOnayVermisMi;
}
