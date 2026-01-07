// lib/models/5_etkinlik/etkinlik_model.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Üye için katılım teyit bilgisi
class EtkinlikTeyit {
  final int id;
  final int uyeId;
  final bool?
      katilacakMi; // null = bekliyor, true = katılacak, false = katılmayacak
  final String? aciklama;
  final DateTime? teyitTarihi;
  final bool okundu;

  EtkinlikTeyit({
    required this.id,
    required this.uyeId,
    this.katilacakMi,
    this.aciklama,
    this.teyitTarihi,
    required this.okundu,
  });

  factory EtkinlikTeyit.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);

    return EtkinlikTeyit(
      id: j['id'] ?? 0,
      uyeId: j['uye'] ?? 0,
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

  /* YENİ: TEYİT BİLGİSİ */
  final List<EtkinlikTeyit>? uyeOnaylari;

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
    this.uyeOnaylari,
  });

  factory EtkinlikModel.fromMap(Map<String, dynamic> j) {
    DateTime? date(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);
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

    // Teyit listesi - YENİ
    final dynamic teyitHam = j['uye_onaylari'] ?? j['teyitler'];
    final List<EtkinlikTeyit>? teyitler =
        (teyitHam is List && teyitHam.isNotEmpty)
            ? teyitHam
                .map((e) => EtkinlikTeyit.fromMap(e as Map<String, dynamic>))
                .toList()
            : null;

    return EtkinlikModel(
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
      uyeOnaylari: teyitler,
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
      };

  /* YENİ HELPER METODLAR */

  /// Bu üyenin teyit bilgisini getir
  EtkinlikTeyit? getTeyitBilgisi(int uyeId) {
    if (uyeOnaylari == null) return null;
    try {
      return uyeOnaylari!.firstWhere((t) => t.uyeId == uyeId);
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
}
