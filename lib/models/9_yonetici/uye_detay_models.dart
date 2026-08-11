// lib/models/9_yonetici/uye_detay_models.dart

import 'package:fitcall/common/tarih_util.dart';
import 'package:flutter/material.dart';

double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

// ==================== PROFİL ====================

class UyeProfilBilgi {
  final int id;
  final int uyeNo;
  final String adi;
  final String soyadi;
  final String adSoyad;
  final String? telefon;
  final String? email;
  final String? cinsiyet;
  final String? dogumTarihi;
  final int? yas;
  final String? adres;
  final String seviyeRengi;
  final String seviyeRengiHex;
  final int uyeTipi;
  final String uyeTuru;
  final bool aktifMi;
  final bool? onaylandiMi;
  final String? sorumluHocaAdi;
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
  final String? meslek;
  final String? kayitTarihi;
  final String? profilFotografi;
  // Genç / sporcu üye
  final String? anneAdiSoyadi;
  final String? anneTelefon;
  final String? babaAdiSoyadi;
  final String? babaTelefon;
  final String? okulAdi;

  UyeProfilBilgi({
    required this.id,
    required this.uyeNo,
    required this.adi,
    required this.soyadi,
    required this.adSoyad,
    this.telefon,
    this.email,
    this.cinsiyet,
    this.dogumTarihi,
    this.yas,
    this.adres,
    required this.seviyeRengi,
    required this.seviyeRengiHex,
    required this.uyeTipi,
    required this.uyeTuru,
    required this.aktifMi,
    this.onaylandiMi,
    this.sorumluHocaAdi,
    this.acilDurumKisi,
    this.acilDurumTelefon,
    this.meslek,
    this.kayitTarihi,
    this.profilFotografi,
    this.anneAdiSoyadi,
    this.anneTelefon,
    this.babaAdiSoyadi,
    this.babaTelefon,
    this.okulAdi,
  });

  factory UyeProfilBilgi.fromJson(Map<String, dynamic> json) {
    return UyeProfilBilgi(
      id: json['id'] ?? 0,
      uyeNo: json['uye_no'] ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      adSoyad: json['ad_soyad'] ?? '',
      telefon: json['telefon'],
      email: json['email'],
      cinsiyet: json['cinsiyet'],
      dogumTarihi: json['dogum_tarihi'],
      yas: json['yas'],
      adres: json['adres'],
      seviyeRengi: json['seviye_rengi'] ?? '',
      seviyeRengiHex: json['seviye_rengi_hex'] ?? '#757575',
      uyeTipi: json['uye_tipi'] ?? 1,
      uyeTuru: json['uye_turu'] ?? 'Standart',
      aktifMi: json['aktif_mi'] ?? false,
      onaylandiMi: json['onaylandi_mi'],
      sorumluHocaAdi: json['sorumlu_hoca_adi'],
      acilDurumKisi: json['acil_durum_kisi'],
      acilDurumTelefon: json['acil_durum_telefon'],
      meslek: json['meslek'],
      kayitTarihi: json['kayit_tarihi'],
      profilFotografi: json['profil_fotografi'],
      anneAdiSoyadi: json['anne_adi_soyadi'],
      anneTelefon: json['anne_telefon'],
      babaAdiSoyadi: json['baba_adi_soyadi'],
      babaTelefon: json['baba_telefon'],
      okulAdi: json['okul_adi'],
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

// ==================== PARA HAREKETİ ====================

class ParaHareketItem {
  final int id;
  final DateTime? tarih;
  final String hareketTuru;
  final String hareketTuruLabel;
  final double tutar;
  final bool borcMu;
  final String? aciklama;
  final String? urunAdi;

  ParaHareketItem({
    required this.id,
    this.tarih,
    required this.hareketTuru,
    required this.hareketTuruLabel,
    required this.tutar,
    required this.borcMu,
    this.aciklama,
    this.urunAdi,
  });

  factory ParaHareketItem.fromJson(Map<String, dynamic> json) {
    return ParaHareketItem(
      id: json['id'] ?? 0,
      tarih: json['tarih'] != null ? parseApiTarih(json['tarih']) : null,
      hareketTuru: json['hareket_turu'] ?? '',
      hareketTuruLabel:
          json['hareket_turu_label'] ?? json['hareket_turu'] ?? '',
      tutar: _toDouble(json['tutar']),
      borcMu: json['borc_mu'] ?? false,
      aciklama: json['aciklama'],
      urunAdi: json['urun_adi'],
    );
  }
}

// ==================== AYLIK ÖZET ====================

class AylikOzetItem {
  final int yil;
  final int ay;
  final double borc;
  final double odeme;
  final double acilisBakiyesi;
  final double kapanisBakiyesi;

  AylikOzetItem({
    required this.yil,
    required this.ay,
    required this.borc,
    required this.odeme,
    required this.acilisBakiyesi,
    required this.kapanisBakiyesi,
  });

  factory AylikOzetItem.fromJson(Map<String, dynamic> json) {
    return AylikOzetItem(
      yil: json['yil'] ?? 0,
      ay: json['ay'] ?? 0,
      borc: _toDouble(json['borc']),
      odeme: _toDouble(json['odeme']),
      acilisBakiyesi: _toDouble(json['acilis_bakiyesi']),
      kapanisBakiyesi: _toDouble(json['kapanis_bakiyesi']),
    );
  }
}

// ==================== PAKET / HAK ====================

class UyePaketItem {
  final int id;
  final String urunAdi;
  final String? urunTipi;
  final int? toplamHak;
  final double? kalanHak;
  final String? baslangic;
  final String? bitis;
  final bool aktifMi;

  UyePaketItem({
    required this.id,
    required this.urunAdi,
    this.urunTipi,
    this.toplamHak,
    this.kalanHak,
    this.baslangic,
    this.bitis,
    required this.aktifMi,
  });

  factory UyePaketItem.fromJson(Map<String, dynamic> json) {
    return UyePaketItem(
      id: json['id'] ?? 0,
      urunAdi: json['urun_adi'] ?? '',
      urunTipi: json['urun_tipi'],
      toplamHak: json['toplam_hak'],
      kalanHak: json['kalan_hak'] != null ? _toDouble(json['kalan_hak']) : null,
      baslangic: json['baslangic'],
      bitis: json['bitis'],
      aktifMi: json['aktif_mi'] ?? false,
    );
  }
}

// ==================== DERS ====================

class UyeDersItem {
  final int id;
  final String tarih;
  final String saat;
  final String? antrenorAdi;
  final String? kortAdi;
  final String? urunAdi;
  final bool iptalMi;

  UyeDersItem({
    required this.id,
    required this.tarih,
    required this.saat,
    this.antrenorAdi,
    this.kortAdi,
    this.urunAdi,
    required this.iptalMi,
  });

  factory UyeDersItem.fromJson(Map<String, dynamic> json) {
    return UyeDersItem(
      id: json['id'] ?? 0,
      tarih: json['tarih'] ?? '',
      saat: json['saat'] ?? '',
      antrenorAdi: json['antrenor_adi'],
      kortAdi: json['kort_adi'],
      urunAdi: json['urun_adi'],
      iptalMi: json['iptal_mi'] ?? false,
    );
  }
}

// ==================== ANA DATA ====================

class UyeDetayData {
  final UyeProfilBilgi profil;
  final double bakiye;
  final List<ParaHareketItem> paraHareketleri;
  final List<AylikOzetItem> aylikOzet;
  final List<UyePaketItem> paketler;
  final List<UyeDersItem> yaklasanDersler;
  final List<UyeDersItem> gecmisDersler;

  UyeDetayData({
    required this.profil,
    required this.bakiye,
    required this.paraHareketleri,
    required this.aylikOzet,
    required this.paketler,
    required this.yaklasanDersler,
    required this.gecmisDersler,
  });

  factory UyeDetayData.fromJson(Map<String, dynamic> json) {
    return UyeDetayData(
      profil: UyeProfilBilgi.fromJson(json['profil'] ?? {}),
      bakiye: _toDouble(json['bakiye']),
      paraHareketleri: (json['para_hareketleri'] as List? ?? [])
          .map((e) => ParaHareketItem.fromJson(e))
          .toList(),
      aylikOzet: (json['aylik_ozet'] as List? ?? [])
          .map((e) => AylikOzetItem.fromJson(e))
          .toList(),
      paketler: (json['paketler'] as List? ?? [])
          .map((e) => UyePaketItem.fromJson(e))
          .toList(),
      yaklasanDersler: (json['yaklasan_dersler'] as List? ?? [])
          .map((e) => UyeDersItem.fromJson(e))
          .toList(),
      gecmisDersler: (json['gecmis_dersler'] as List? ?? [])
          .map((e) => UyeDersItem.fromJson(e))
          .toList(),
    );
  }
}
