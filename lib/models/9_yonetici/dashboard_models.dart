// lib/models/9_yonetici/dashboard_models.dart

import 'package:fitcall/common/tarih_util.dart';
import 'package:flutter/material.dart';

// ==================== ENUMS ====================

enum DonemFiltresi { bugun, buHafta, buAy }

extension DonemFiltresiExtension on DonemFiltresi {
  String get apiValue {
    switch (this) {
      case DonemFiltresi.bugun:
        return 'bugun';
      case DonemFiltresi.buHafta:
        return 'bu_hafta';
      case DonemFiltresi.buAy:
        return 'bu_ay';
    }
  }

  String get label {
    switch (this) {
      case DonemFiltresi.bugun:
        return 'Bugün';
      case DonemFiltresi.buHafta:
        return 'Bu Hafta';
      case DonemFiltresi.buAy:
        return 'Bu Ay';
    }
  }
}

// ==================== DASHBOARD - CİRO MODELLERİ ====================

/// Ciro kartı (ders bazlı getiri)
class DashboardCiroKarti {
  final double toplamCiro;
  final int dersSayisi; // Değişti: islemSayisi -> dersSayisi
  final double oncekiDonemCiro;
  final double? degisimYuzdesi;

  DashboardCiroKarti({
    required this.toplamCiro,
    required this.dersSayisi,
    required this.oncekiDonemCiro,
    this.degisimYuzdesi,
  });

  factory DashboardCiroKarti.fromJson(Map<String, dynamic> json) {
    return DashboardCiroKarti(
      toplamCiro: double.tryParse(json['toplam_ciro']?.toString() ?? '0') ?? 0,
      dersSayisi: json['ders_sayisi'] ?? 0,
      oncekiDonemCiro:
          double.tryParse(json['onceki_donem_ciro']?.toString() ?? '0') ?? 0,
      degisimYuzdesi: json['degisim_yuzdesi'] != null
          ? double.tryParse(json['degisim_yuzdesi'].toString())
          : null,
    );
  }
}

/// Haftalık ciro grafiği için günlük veri
class HaftalikCiroItem {
  final String gun;
  final String gunKisa;
  final DateTime tarih;
  final double ciro;

  HaftalikCiroItem({
    required this.gun,
    required this.gunKisa,
    required this.tarih,
    required this.ciro,
  });

  factory HaftalikCiroItem.fromJson(Map<String, dynamic> json) {
    return HaftalikCiroItem(
      gun: json['gun'] ?? '',
      gunKisa: json['gun_kisa'] ?? '',
      tarih: parseApiTarih(json['tarih'] ?? '') ?? simdiKulup(),
      ciro: double.tryParse(json['ciro']?.toString() ?? '0') ?? 0,
    );
  }
}

// ==================== DASHBOARD - TAHSİLAT MODELLERİ (YENİ) ====================

/// Tahsilat kartı (ödeme bazlı)
class DashboardTahsilatKarti {
  final double toplamTahsilat;
  final int islemSayisi;
  final double oncekiDonemTahsilat;
  final double? degisimYuzdesi;

  DashboardTahsilatKarti({
    required this.toplamTahsilat,
    required this.islemSayisi,
    required this.oncekiDonemTahsilat,
    this.degisimYuzdesi,
  });

  factory DashboardTahsilatKarti.fromJson(Map<String, dynamic> json) {
    return DashboardTahsilatKarti(
      toplamTahsilat:
          double.tryParse(json['toplam_tahsilat']?.toString() ?? '0') ?? 0,
      islemSayisi: json['islem_sayisi'] ?? 0,
      oncekiDonemTahsilat:
          double.tryParse(json['onceki_donem_tahsilat']?.toString() ?? '0') ??
              0,
      degisimYuzdesi: json['degisim_yuzdesi'] != null
          ? double.tryParse(json['degisim_yuzdesi'].toString())
          : null,
    );
  }
}

/// Haftalık tahsilat grafiği için günlük veri
class HaftalikTahsilatItem {
  final String gun;
  final String gunKisa;
  final DateTime tarih;
  final double tahsilat;

  HaftalikTahsilatItem({
    required this.gun,
    required this.gunKisa,
    required this.tarih,
    required this.tahsilat,
  });

  factory HaftalikTahsilatItem.fromJson(Map<String, dynamic> json) {
    return HaftalikTahsilatItem(
      gun: json['gun'] ?? '',
      gunKisa: json['gun_kisa'] ?? '',
      tarih: parseApiTarih(json['tarih'] ?? '') ?? simdiKulup(),
      tahsilat: double.tryParse(json['tahsilat']?.toString() ?? '0') ?? 0,
    );
  }
}

// ==================== DASHBOARD - DİĞER MODELLER ====================

class DashboardDersKarti {
  final int toplamDers;
  final int tamamlananDers;
  final int iptalEdilenDers;
  final double dolulukYuzdesi;
  final int oncekiDonemIptal;
  final double? iptalDegisimYuzdesi;

  DashboardDersKarti({
    required this.toplamDers,
    required this.tamamlananDers,
    required this.iptalEdilenDers,
    required this.dolulukYuzdesi,
    required this.oncekiDonemIptal,
    this.iptalDegisimYuzdesi,
  });

  factory DashboardDersKarti.fromJson(Map<String, dynamic> json) {
    return DashboardDersKarti(
      toplamDers: json['toplam_ders'] ?? 0,
      tamamlananDers: json['tamamlanan_ders'] ?? 0,
      iptalEdilenDers: json['iptal_edilen_ders'] ?? 0,
      dolulukYuzdesi:
          double.tryParse(json['doluluk_yuzdesi']?.toString() ?? '0') ?? 0,
      oncekiDonemIptal: json['onceki_donem_iptal'] ?? 0,
      iptalDegisimYuzdesi: json['iptal_degisim_yuzdesi'] != null
          ? double.tryParse(json['iptal_degisim_yuzdesi'].toString())
          : null,
    );
  }
}

class DashboardUyeKarti {
  final int aktifUyeSayisi;
  final int oncekiDonemAktif;
  final double? degisimYuzdesi;

  DashboardUyeKarti({
    required this.aktifUyeSayisi,
    required this.oncekiDonemAktif,
    this.degisimYuzdesi,
  });

  factory DashboardUyeKarti.fromJson(Map<String, dynamic> json) {
    return DashboardUyeKarti(
      aktifUyeSayisi: json['aktif_uye_sayisi'] ?? 0,
      oncekiDonemAktif: json['onceki_donem_aktif'] ?? 0,
      degisimYuzdesi: json['degisim_yuzdesi'] != null
          ? double.tryParse(json['degisim_yuzdesi'].toString())
          : null,
    );
  }
}

/// Toplam Alacak kartı (eski: VadesiGecmis)
class DashboardToplamAlacakKarti {
  final double toplamBorc;
  final int borcluUyeSayisi;

  DashboardToplamAlacakKarti({
    required this.toplamBorc,
    required this.borcluUyeSayisi,
  });

  factory DashboardToplamAlacakKarti.fromJson(Map<String, dynamic> json) {
    return DashboardToplamAlacakKarti(
      toplamBorc: double.tryParse(json['toplam_borc']?.toString() ?? '0') ?? 0,
      borcluUyeSayisi: json['borclu_uye_sayisi'] ?? 0,
    );
  }
}

class HizliErisimDersler {
  final int toplamDers;
  final int onayBekleyen;

  HizliErisimDersler({
    required this.toplamDers,
    required this.onayBekleyen,
  });

  factory HizliErisimDersler.fromJson(Map<String, dynamic> json) {
    return HizliErisimDersler(
      toplamDers: json['toplam_ders'] ?? 0,
      onayBekleyen: json['onay_bekleyen'] ?? 0,
    );
  }
}

class HizliErisimAntrenor {
  final int gunlukTamamlananDers;

  HizliErisimAntrenor({required this.gunlukTamamlananDers});

  factory HizliErisimAntrenor.fromJson(Map<String, dynamic> json) {
    return HizliErisimAntrenor(
      gunlukTamamlananDers: json['gunluk_tamamlanan_ders'] ?? 0,
    );
  }
}

class GununOzeti {
  final int yeniKayit;
  final int telafiDers;
  final double dolulukYuzdesi;

  GununOzeti({
    required this.yeniKayit,
    required this.telafiDers,
    required this.dolulukYuzdesi,
  });

  factory GununOzeti.fromJson(Map<String, dynamic> json) {
    return GununOzeti(
      yeniKayit: json['yeni_kayit'] ?? 0,
      telafiDers: json['telafi_ders'] ?? 0,
      dolulukYuzdesi:
          double.tryParse(json['doluluk_yuzdesi']?.toString() ?? '0') ?? 0,
    );
  }
}

// ==================== ANA DASHBOARD DATA ====================

class DashboardData {
  // Ciro (ders bazlı getiri)
  final DashboardCiroKarti ciro;
  final DashboardCiroKarti aylikCiro;
  final List<HaftalikCiroItem> haftalikCiro;

  // Tahsilat (ödeme bazlı)
  final DashboardTahsilatKarti tahsilat;
  final DashboardTahsilatKarti aylikTahsilat;
  final List<HaftalikTahsilatItem> haftalikTahsilat;

  // Diğer
  final DashboardDersKarti ders;
  final DashboardUyeKarti uye;
  final DashboardToplamAlacakKarti toplamAlacak;
  final HizliErisimDersler hizliErisimDersler;
  final HizliErisimAntrenor hizliErisimAntrenor;
  final GununOzeti gununOzeti;

  DashboardData({
    required this.ciro,
    required this.aylikCiro,
    required this.haftalikCiro,
    required this.tahsilat,
    required this.aylikTahsilat,
    required this.haftalikTahsilat,
    required this.ders,
    required this.uye,
    required this.toplamAlacak,
    required this.hizliErisimDersler,
    required this.hizliErisimAntrenor,
    required this.gununOzeti,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      // Ciro
      ciro: DashboardCiroKarti.fromJson(json['ciro'] ?? {}),
      aylikCiro: DashboardCiroKarti.fromJson(json['aylik_ciro'] ?? {}),
      haftalikCiro: (json['haftalik_ciro'] as List? ?? [])
          .map((e) => HaftalikCiroItem.fromJson(e))
          .toList(),

      // Tahsilat
      tahsilat: DashboardTahsilatKarti.fromJson(json['tahsilat'] ?? {}),
      aylikTahsilat:
          DashboardTahsilatKarti.fromJson(json['aylik_tahsilat'] ?? {}),
      haftalikTahsilat: (json['haftalik_tahsilat'] as List? ?? [])
          .map((e) => HaftalikTahsilatItem.fromJson(e))
          .toList(),

      // Diğer
      ders: DashboardDersKarti.fromJson(json['ders'] ?? {}),
      uye: DashboardUyeKarti.fromJson(json['uye'] ?? {}),
      toplamAlacak:
          DashboardToplamAlacakKarti.fromJson(json['toplam_alacak'] ?? {}),
      hizliErisimDersler:
          HizliErisimDersler.fromJson(json['hizli_erisim_dersler'] ?? {}),
      hizliErisimAntrenor:
          HizliErisimAntrenor.fromJson(json['hizli_erisim_antrenor'] ?? {}),
      gununOzeti: GununOzeti.fromJson(json['gunun_ozeti'] ?? {}),
    );
  }
}

// ==================== RAPORLAR MODELLERİ ====================

class RaporOzetKarti {
  final String baslik;
  final String deger;
  final String? altBaslik;
  final String ikon;
  final String renk;

  RaporOzetKarti({
    required this.baslik,
    required this.deger,
    this.altBaslik,
    required this.ikon,
    required this.renk,
  });

  factory RaporOzetKarti.fromJson(Map<String, dynamic> json) {
    return RaporOzetKarti(
      baslik: json['baslik'] ?? '',
      deger: json['deger'] ?? '',
      altBaslik: json['alt_baslik'],
      ikon: json['ikon'] ?? '',
      renk: json['renk'] ?? '#757575',
    );
  }

  Color get renkColor {
    try {
      return Color(int.parse(renk.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8C8C8C);
    }
  }
}

/// Ciro raporu satırı (günlük) - Güncellendi
class CiroRaporuItem {
  final DateTime tarih;
  final double ciro;
  final int dersSayisi; // Değişti: islemSayisi -> dersSayisi

  CiroRaporuItem({
    required this.tarih,
    required this.ciro,
    required this.dersSayisi,
  });

  factory CiroRaporuItem.fromJson(Map<String, dynamic> json) {
    return CiroRaporuItem(
      tarih: parseApiTarih(json['tarih'] ?? '') ?? simdiKulup(),
      ciro: double.tryParse(json['ciro']?.toString() ?? '0') ?? 0,
      dersSayisi: json['ders_sayisi'] ?? 0,
    );
  }
}

/// Tahsilat raporu satırı (günlük) - YENİ
class TahsilatRaporuItem {
  final DateTime tarih;
  final double tahsilat;
  final int islemSayisi;

  TahsilatRaporuItem({
    required this.tarih,
    required this.tahsilat,
    required this.islemSayisi,
  });

  factory TahsilatRaporuItem.fromJson(Map<String, dynamic> json) {
    return TahsilatRaporuItem(
      tarih: parseApiTarih(json['tarih'] ?? '') ?? simdiKulup(),
      tahsilat: double.tryParse(json['tahsilat']?.toString() ?? '0') ?? 0,
      islemSayisi: json['islem_sayisi'] ?? 0,
    );
  }
}

class DolulukRaporuItem {
  final String kortAdi;
  final int kortId;
  final int toplamSaat;
  final int doluSaat;
  final double dolulukYuzdesi;

  DolulukRaporuItem({
    required this.kortAdi,
    required this.kortId,
    required this.toplamSaat,
    required this.doluSaat,
    required this.dolulukYuzdesi,
  });

  factory DolulukRaporuItem.fromJson(Map<String, dynamic> json) {
    return DolulukRaporuItem(
      kortAdi: json['kort_adi'] ?? '',
      kortId: json['kort_id'] ?? 0,
      toplamSaat: json['toplam_saat'] ?? 0,
      doluSaat: json['dolu_saat'] ?? 0,
      dolulukYuzdesi:
          double.tryParse(json['doluluk_yuzdesi']?.toString() ?? '0') ?? 0,
    );
  }
}

class AntrenorPerformansItem {
  final int antrenorId;
  final String antrenorAdi;
  final int toplamDers;
  final int tamamlananDers;
  final int iptalDers;
  final double? ortalamaPuan;

  AntrenorPerformansItem({
    required this.antrenorId,
    required this.antrenorAdi,
    required this.toplamDers,
    required this.tamamlananDers,
    required this.iptalDers,
    this.ortalamaPuan,
  });

  factory AntrenorPerformansItem.fromJson(Map<String, dynamic> json) {
    return AntrenorPerformansItem(
      antrenorId: json['antrenor_id'] ?? 0,
      antrenorAdi: json['antrenor_adi'] ?? '',
      toplamDers: json['toplam_ders'] ?? 0,
      tamamlananDers: json['tamamlanan_ders'] ?? 0,
      iptalDers: json['iptal_ders'] ?? 0,
      ortalamaPuan: json['ortalama_puan'] != null
          ? double.tryParse(json['ortalama_puan'].toString())
          : null,
    );
  }
}

class RaporlarData {
  final List<RaporOzetKarti> ozetKartlar;
  final List<CiroRaporuItem> ciroRaporu;
  final List<TahsilatRaporuItem> tahsilatRaporu; // YENİ
  final List<DolulukRaporuItem> dolulukRaporu;
  final List<AntrenorPerformansItem> antrenorPerformans;

  RaporlarData({
    required this.ozetKartlar,
    required this.ciroRaporu,
    required this.tahsilatRaporu,
    required this.dolulukRaporu,
    required this.antrenorPerformans,
  });

  factory RaporlarData.fromJson(Map<String, dynamic> json) {
    return RaporlarData(
      ozetKartlar: (json['ozet_kartlar'] as List? ?? [])
          .map((e) => RaporOzetKarti.fromJson(e))
          .toList(),
      ciroRaporu: (json['ciro_raporu'] as List? ?? [])
          .map((e) => CiroRaporuItem.fromJson(e))
          .toList(),
      tahsilatRaporu: (json['tahsilat_raporu'] as List? ?? [])
          .map((e) => TahsilatRaporuItem.fromJson(e))
          .toList(),
      dolulukRaporu: (json['doluluk_raporu'] as List? ?? [])
          .map((e) => DolulukRaporuItem.fromJson(e))
          .toList(),
      antrenorPerformans: (json['antrenor_performans'] as List? ?? [])
          .map((e) => AntrenorPerformansItem.fromJson(e))
          .toList(),
    );
  }
}

// ==================== ÜYELER MODELLERİ ====================

class UyeIstatistik {
  final int toplamUye;
  final int aktifUye;
  final int pasifUye;
  final int buAyYeniKayit;

  UyeIstatistik({
    required this.toplamUye,
    required this.aktifUye,
    required this.pasifUye,
    required this.buAyYeniKayit,
  });

  factory UyeIstatistik.fromJson(Map<String, dynamic> json) {
    return UyeIstatistik(
      toplamUye: json['toplam_uye'] ?? 0,
      aktifUye: json['aktif_uye'] ?? 0,
      pasifUye: json['pasif_uye'] ?? 0,
      buAyYeniKayit: json['bu_ay_yeni_kayit'] ?? 0,
    );
  }
}

class UyeListeItem {
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
  final double bakiye;
  final DateTime? sonDersTarihi;
  final String? profilFotografi;

  UyeListeItem({
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
    required this.bakiye,
    this.sonDersTarihi,
    this.profilFotografi,
  });

  factory UyeListeItem.fromJson(Map<String, dynamic> json) {
    return UyeListeItem(
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
      bakiye: double.tryParse(json['bakiye']?.toString() ?? '0') ?? 0,
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

class UyelerData {
  final UyeIstatistik istatistikler;
  final List<UyeListeItem> uyeler;
  final int toplamSayfa;
  final int mevcutSayfa;

  UyelerData({
    required this.istatistikler,
    required this.uyeler,
    required this.toplamSayfa,
    required this.mevcutSayfa,
  });

  factory UyelerData.fromJson(Map<String, dynamic> json) {
    return UyelerData(
      istatistikler: UyeIstatistik.fromJson(json['istatistikler'] ?? {}),
      uyeler: (json['uyeler'] as List? ?? [])
          .map((e) => UyeListeItem.fromJson(e))
          .toList(),
      toplamSayfa: json['toplam_sayfa'] ?? 1,
      mevcutSayfa: json['mevcut_sayfa'] ?? 1,
    );
  }
}

// ==================== ANTRENÖRLER MODELLERİ ====================

class AntrenorIstatistik {
  final int toplamAntrenor;
  final int aktifAntrenor;
  final int bugunToplamDers;
  final double? ortalamaPuan;

  AntrenorIstatistik({
    required this.toplamAntrenor,
    required this.aktifAntrenor,
    required this.bugunToplamDers,
    this.ortalamaPuan,
  });

  factory AntrenorIstatistik.fromJson(Map<String, dynamic> json) {
    return AntrenorIstatistik(
      toplamAntrenor: json['toplam_antrenor'] ?? 0,
      aktifAntrenor: json['aktif_antrenor'] ?? 0,
      bugunToplamDers: json['bugunki_toplam_ders'] ?? 0,
      ortalamaPuan: json['ortalama_puan'] != null
          ? double.tryParse(json['ortalama_puan'].toString())
          : null,
    );
  }
}

class AntrenorListeItem {
  final int id;
  final String adi;
  final String soyadi;
  final String adSoyad;
  final String? ePosta;
  final String? telefon;
  final String renk;
  final bool aktifMi;
  final int bugunDersSayisi;
  final int haftalikDersSayisi;
  final double? ortalamaPuan;
  final int ogrenciSayisi;

  AntrenorListeItem({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.adSoyad,
    this.ePosta,
    this.telefon,
    required this.renk,
    required this.aktifMi,
    required this.bugunDersSayisi,
    required this.haftalikDersSayisi,
    this.ortalamaPuan,
    required this.ogrenciSayisi,
  });

  factory AntrenorListeItem.fromJson(Map<String, dynamic> json) {
    return AntrenorListeItem(
      id: json['id'] ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      adSoyad: json['ad_soyad'] ?? '',
      ePosta: json['e_posta'],
      telefon: json['telefon'],
      renk: json['renk'] ?? '#757575',
      aktifMi: json['aktif_mi'] ?? false,
      bugunDersSayisi: json['bugunki_ders_sayisi'] ?? 0,
      haftalikDersSayisi: json['haftalik_ders_sayisi'] ?? 0,
      ortalamaPuan: json['ortalama_puan'] != null
          ? double.tryParse(json['ortalama_puan'].toString())
          : null,
      ogrenciSayisi: json['ogrenci_sayisi'] ?? 0,
    );
  }

  Color get renkColor {
    try {
      return Color(int.parse(renk.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF8C8C8C);
    }
  }
}

class AntrenorlerData {
  final AntrenorIstatistik istatistikler;
  final List<AntrenorListeItem> antrenorler;

  AntrenorlerData({
    required this.istatistikler,
    required this.antrenorler,
  });

  factory AntrenorlerData.fromJson(Map<String, dynamic> json) {
    return AntrenorlerData(
      istatistikler: AntrenorIstatistik.fromJson(json['istatistikler'] ?? {}),
      antrenorler: (json['antrenorler'] as List? ?? [])
          .map((e) => AntrenorListeItem.fromJson(e))
          .toList(),
    );
  }
}

// ==================== DERSLER MODELLERİ ====================

class DersIstatistik {
  final int bugunDers;
  final int tamamlanan;
  final int devamEden;
  final int bekleyen;
  final int iptal;

  DersIstatistik({
    required this.bugunDers,
    required this.tamamlanan,
    required this.devamEden,
    required this.bekleyen,
    required this.iptal,
  });

  factory DersIstatistik.fromJson(Map<String, dynamic> json) {
    return DersIstatistik(
      bugunDers: json['bugunki_ders'] ?? 0,
      tamamlanan: json['tamamlanan'] ?? 0,
      devamEden: json['devam_eden'] ?? 0,
      bekleyen: json['bekleyen'] ?? 0,
      iptal: json['iptal'] ?? 0,
    );
  }
}

class DersKatilimci {
  final int id;
  final String adSoyad;
  final String? telefon;

  DersKatilimci({
    required this.id,
    required this.adSoyad,
    this.telefon,
  });

  factory DersKatilimci.fromJson(Map<String, dynamic> json) {
    return DersKatilimci(
      id: json['id'] ?? 0,
      adSoyad: json['ad_soyad'] ?? '',
      telefon: json['telefon'],
    );
  }
}

class DersListeItem {
  final int id;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String tarih;
  final String saat;
  final int? antrenorId;
  final String? antrenorAdi;
  final int? kortId;
  final String? kortAdi;
  final int? urunId;
  final String? urunAdi;
  final String seviye;
  final bool iptalMi;
  final int katilimciSayisi;
  final List<DersKatilimci> katilimcilar;
  final String durum; // planli, devam_ediyor, tamamlandi, iptal, onay_bekliyor
  final String onayDurumu; // bekliyor, onaylandi, reddedildi
  final String? aciklama;

  DersListeItem({
    required this.id,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.tarih,
    required this.saat,
    this.antrenorId,
    this.antrenorAdi,
    this.kortId,
    this.kortAdi,
    this.urunId,
    this.urunAdi,
    required this.seviye,
    required this.iptalMi,
    required this.katilimciSayisi,
    required this.katilimcilar,
    required this.durum,
    required this.onayDurumu,
    this.aciklama,
  });

  factory DersListeItem.fromJson(Map<String, dynamic> json) {
    return DersListeItem(
      id: json['id'] ?? 0,
      baslangicTarihSaat:
          parseApiTarih(json['baslangic_tarih_saat'] ?? '') ?? simdiKulup(),
      bitisTarihSaat:
          parseApiTarih(json['bitis_tarih_saat'] ?? '') ?? simdiKulup(),
      tarih: json['tarih'] ?? '',
      saat: json['saat'] ?? '',
      antrenorId: json['antrenor'],
      antrenorAdi: json['antrenor_adi'],
      kortId: json['kort'],
      kortAdi: json['kort_adi'],
      urunId: json['urun'],
      urunAdi: json['urun_adi'],
      seviye: json['seviye'] ?? '',
      iptalMi: json['iptal_mi'] ?? false,
      katilimciSayisi: json['katilimci_sayisi'] ?? 0,
      katilimcilar: (json['katilimcilar'] as List? ?? [])
          .map((e) => DersKatilimci.fromJson(e))
          .toList(),
      durum: json['durum'] ?? 'planli',
      onayDurumu: json['onay_durumu'] ?? 'bekliyor',
      aciklama: json['aciklama'],
    );
  }

  Color get durumRenk {
    switch (durum) {
      case 'tamamlandi':
        return Colors.green;
      case 'devam_ediyor':
        return Colors.blue;
      case 'iptal':
        return Colors.red;
      case 'onay_bekliyor':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }

  String get durumText {
    switch (durum) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'iptal':
        return 'İptal';
      case 'onay_bekliyor':
        return 'Onay Bekliyor';
      default:
        return 'Planlı';
    }
  }
}

class DerslerData {
  final DersIstatistik istatistikler;
  final List<DersListeItem> dersler;
  final int toplamSayfa;
  final int mevcutSayfa;

  DerslerData({
    required this.istatistikler,
    required this.dersler,
    required this.toplamSayfa,
    required this.mevcutSayfa,
  });

  factory DerslerData.fromJson(Map<String, dynamic> json) {
    return DerslerData(
      istatistikler: DersIstatistik.fromJson(json['istatistikler'] ?? {}),
      dersler: (json['dersler'] as List? ?? [])
          .map((e) => DersListeItem.fromJson(e))
          .toList(),
      toplamSayfa: json['toplam_sayfa'] ?? 1,
      mevcutSayfa: json['mevcut_sayfa'] ?? 1,
    );
  }
}
