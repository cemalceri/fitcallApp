// lib/screens/7_yonetici/program/widgets/program_constants.dart
//
// Yönetici haftalık program ızgarasının ölçü/renk sabitleri.
// Web'deki DayPilot "Resources" görünümünün mobil karşılığı: satırlar saat,
// kolonlar kort. Kortlar telefona sığmadığı için yatay kaydırmalı.

import 'package:flutter/material.dart';

class ProgramOlculeri {
  ProgramOlculeri._();

  /// Dikey ölçek: 1 dakika = kaç piksel
  static const double dakikaBasinaPiksel = 1.2;
  static const double saatYuksekligi = dakikaBasinaPiksel * 60; // 72
  static const double saatKolonGenisligi = 46.0;
  static const double kortKolonGenisligi = 128.0;
  static const double kortBaslikYuksekligi = 38.0;

  /// Varsayılan gösterim aralığı (veri dışına taşarsa genişletilir)
  static const int varsayilanBaslangicSaati = 7;
  static const int varsayilanBitisSaati = 23;

  static const double blokYatayBosluk = 3.0;
  static const double blokKoseYaricapi = 8.0;
  static const double blokSolSeritGenisligi = 3.0;

  /// Blok içeriğinin okunabildiği en küçük yükseklik
  static const double blokDetayEsigi = 46.0;
  static const double blokMinYukseklik = 22.0;
}

class ProgramRenkleri {
  ProgramRenkleri._();

  static const Color saatCizgisi = Color(0xFFE2E8F0);
  static Color yarimSaatCizgisi = const Color(0x22808080);
  static const Color kortAyraci = Color(0xFFE2E8F0);
  static const Color simdiCizgisi = Color(0xFFEF4444);

  static const Color iptal = Color(0xFFEF4444);
  static const Color tamamlandi = Color(0xFF10B981);
  static const Color devamEdiyor = Color(0xFFF59E0B);
  static const Color planli = Color(0xFF2563EB);
  static Color onayBekliyor = const Color(0xFF8C8C8C);

  static Color durumRengi(String durum) {
    switch (durum) {
      case 'iptal':
        return iptal;
      case 'tamamlandi':
        return tamamlandi;
      case 'devam_ediyor':
        return devamEdiyor;
      case 'onay_bekliyor':
        return onayBekliyor;
      default:
        return planli;
    }
  }

  static String durumMetni(String durum) {
    switch (durum) {
      case 'iptal':
        return 'İptal';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'devam_ediyor':
        return 'Devam ediyor';
      case 'onay_bekliyor':
        return 'Onay bekliyor';
      default:
        return 'Planlı';
    }
  }
}

/// Saat ↔ piksel dönüşümleri. [baslangicSaati] ızgaranın üst sınırıdır.
class ProgramZaman {
  ProgramZaman._();

  static double zamandanPiksel(DateTime zaman, int baslangicSaati) {
    final dakika = zaman.hour * 60 + zaman.minute - baslangicSaati * 60;
    return dakika * ProgramOlculeri.dakikaBasinaPiksel;
  }

  static double sureyeGoreYukseklik(int dakika) {
    final h = dakika * ProgramOlculeri.dakikaBasinaPiksel;
    return h < ProgramOlculeri.blokMinYukseklik
        ? ProgramOlculeri.blokMinYukseklik
        : h;
  }

  static String saatMetni(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
