// lib/models/10_ofis/ofis_uye_models.dart
//
// Ofis (ön büro) üye modelleri — yönetici modellerinin parasal ve mahrem
// alanlardan arındırılmış hâli.
//
// Buradaki sınıflarda bakiye, para hareketi, aylık özet, adres, meslek, veli
// bilgisi, acil durum kişisi ve okul ALANI YOK. Bu bir görsel gizleme değil:
// backend'deki `ofisUyeler` / `ofisUyeDetay` uçları o alanları hiç göndermiyor
// (bkz. api/ofis/metots.py beyaz listesi). Alan burada da olmadığı için ekran
// yanlışlıkla gösteremez.
//
// Paket ve ders satırları yönetici tarafıyla aynı — içlerinde para yok —
// dolayısıyla o modeller yeniden kullanılıyor.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart'
    show UyeDersItem, UyePaketItem;
import 'package:flutter/material.dart';

// ==================== LİSTE ====================

/// Üye listesi satırı — bakiyesiz.
class OfisUyeListeItem {
  final int id;
  final int uyeNo;
  final String adi;
  final String soyadi;
  final String adSoyad;
  final String? telefon;
  final String? email;
  final String seviyeRengi;
  final String seviyeRengiHex;
  final bool aktifMi;
  final int uyeTipi;
  final String uyeTuru;
  final int? yas;

  /// Listenin sağ değeri. Yöneticide bu sütunda bakiye duruyor; ofiste
  /// operasyonel karşılığı son ders tarihi.
  final DateTime? sonDersTarihi;

  final String? profilFotografi;

  OfisUyeListeItem({
    required this.id,
    required this.uyeNo,
    required this.adi,
    required this.soyadi,
    required this.adSoyad,
    this.telefon,
    this.email,
    required this.seviyeRengi,
    required this.seviyeRengiHex,
    required this.aktifMi,
    required this.uyeTipi,
    required this.uyeTuru,
    this.yas,
    this.sonDersTarihi,
    this.profilFotografi,
  });

  factory OfisUyeListeItem.fromJson(Map<String, dynamic> json) {
    return OfisUyeListeItem(
      id: json['id'] ?? 0,
      uyeNo: json['uye_no'] ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      adSoyad: json['ad_soyad'] ?? '',
      telefon: json['telefon'],
      email: json['email'],
      seviyeRengi: json['seviye_rengi'] ?? '',
      seviyeRengiHex: json['seviye_rengi_hex'] ?? '#757575',
      aktifMi: json['aktif_mi'] ?? false,
      uyeTipi: json['uye_tipi'] ?? 1,
      uyeTuru: json['uye_turu'] ?? 'Standart',
      yas: json['yas'],
      sonDersTarihi: json['son_ders_tarihi'] != null
          ? parseApiTarih(json['son_ders_tarihi'])
          : null,
      profilFotografi: json['profil_fotografi'],
    );
  }

  Color get seviyeRenkColor {
    try {
      return Color(int.parse(seviyeRengiHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8C8C8C);
    }
  }
}

/// Yalnız liste. Backend istatistik bloğu da gönderiyor ama ofis ekranında
/// "bu ay yeni kayıt" gibi yönetimsel sayaçlar yok; kayıt adedi başlık
/// çubuğunda listenin kendisinden okunuyor.
class OfisUyelerData {
  final List<OfisUyeListeItem> uyeler;

  OfisUyelerData({required this.uyeler});

  factory OfisUyelerData.fromJson(Map<String, dynamic> json) {
    return OfisUyelerData(
      uyeler: (json['uyeler'] as List? ?? [])
          .map((e) => OfisUyeListeItem.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

// ==================== DETAY ====================

/// Üye profili — iletişim ve kulüp bilgileri. Mahrem alanlar yok.
class OfisUyeProfili {
  final int id;
  final int uyeNo;
  final String adi;
  final String soyadi;
  final String adSoyad;
  final String? telefon;
  final String? email;
  final int? yas;
  final String seviyeRengi;
  final String seviyeRengiHex;
  final int uyeTipi;
  final String uyeTuru;
  final bool aktifMi;
  final String? sorumluHocaAdi;
  final String? kayitTarihi;
  final String? profilFotografi;

  OfisUyeProfili({
    required this.id,
    required this.uyeNo,
    required this.adi,
    required this.soyadi,
    required this.adSoyad,
    this.telefon,
    this.email,
    this.yas,
    required this.seviyeRengi,
    required this.seviyeRengiHex,
    required this.uyeTipi,
    required this.uyeTuru,
    required this.aktifMi,
    this.sorumluHocaAdi,
    this.kayitTarihi,
    this.profilFotografi,
  });

  factory OfisUyeProfili.fromJson(Map<String, dynamic> json) {
    return OfisUyeProfili(
      id: json['id'] ?? 0,
      uyeNo: json['uye_no'] ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      adSoyad: json['ad_soyad'] ?? '',
      telefon: json['telefon'],
      email: json['email'],
      yas: json['yas'],
      seviyeRengi: json['seviye_rengi'] ?? '',
      seviyeRengiHex: json['seviye_rengi_hex'] ?? '#757575',
      uyeTipi: json['uye_tipi'] ?? 1,
      uyeTuru: json['uye_turu'] ?? 'Standart',
      aktifMi: json['aktif_mi'] ?? false,
      sorumluHocaAdi: json['sorumlu_hoca_adi'],
      kayitTarihi: json['kayit_tarihi'],
      profilFotografi: json['profil_fotografi'],
    );
  }

  Color get seviyeRenkColor {
    try {
      return Color(int.parse(seviyeRengiHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8C8C8C);
    }
  }
}

class OfisUyeDetayData {
  final OfisUyeProfili profil;
  final List<UyePaketItem> paketler;
  final List<UyeDersItem> yaklasanDersler;
  final List<UyeDersItem> gecmisDersler;

  OfisUyeDetayData({
    required this.profil,
    required this.paketler,
    required this.yaklasanDersler,
    required this.gecmisDersler,
  });

  factory OfisUyeDetayData.fromJson(Map<String, dynamic> json) {
    List<UyeDersItem> dersler(String anahtar) =>
        (json[anahtar] as List? ?? [])
            .map((e) => UyeDersItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

    return OfisUyeDetayData(
      profil: OfisUyeProfili.fromJson(
          Map<String, dynamic>.from(json['profil'] as Map? ?? {})),
      paketler: (json['paketler'] as List? ?? [])
          .map((e) => UyePaketItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      yaklasanDersler: dersler('yaklasan_dersler'),
      gecmisDersler: dersler('gecmis_dersler'),
    );
  }
}
