// lib/models/9_yonetici/bekleyen_dekont_models.dart
//
// Yönetici ana sayfasındaki "ödeme onay bekliyor" maddesinin listesi: üyelerin
// gönderdiği, ofisin henüz işlemediği havale/EFT dekontları. Yalnız okuma;
// onay, bağlama ve ret web'deki dekont masasında.

import 'package:fitcall/common/tarih_util.dart';

class BekleyenDekont {
  final int id;
  final String uyeAdi;

  /// Dekontu yükleyen hesap (çoğu zaman veli).
  final String hesapSahibi;
  final double? beyanTutar;
  final String aciklama;
  final DateTime? yuklenme;

  /// "bugün" / "3 gün": ne kadardır bekliyor.
  final String beklemeMetni;
  final int beklemeGun;
  final String dosyaAdi;
  final bool pdfMi;

  /// İşlenmişken ödeme kaydı silindi ya da onay geri alındı.
  final bool yenidenKontrol;

  /// Aynı dosya başka bir dekontta da var (mükerrer olabilir).
  final bool ayniDosya;

  const BekleyenDekont({
    required this.id,
    required this.uyeAdi,
    this.hesapSahibi = '',
    this.beyanTutar,
    this.aciklama = '',
    this.yuklenme,
    this.beklemeMetni = '',
    this.beklemeGun = 0,
    this.dosyaAdi = '',
    this.pdfMi = false,
    this.yenidenKontrol = false,
    this.ayniDosya = false,
  });

  factory BekleyenDekont.fromJson(Map<String, dynamic> json) => BekleyenDekont(
        id: (json['id'] as num?)?.toInt() ?? 0,
        uyeAdi: json['uye_adi']?.toString() ?? '',
        hesapSahibi: json['hesap_sahibi_adi']?.toString() ?? '',
        beyanTutar: _sayi(json['beyan_tutar']),
        aciklama: json['uye_aciklamasi']?.toString() ?? '',
        yuklenme: parseApiTarih(json['olusturulma_zamani']),
        beklemeMetni: json['bekleme_metni']?.toString() ?? '',
        beklemeGun: (json['bekleme_gun'] as num?)?.toInt() ?? 0,
        dosyaAdi: json['dosya_adi']?.toString() ?? '',
        pdfMi: json['pdf_mi'] == true,
        yenidenKontrol: json['yeniden_kontrol'] == true,
        ayniDosya: json['ayni_dosya'] == true,
      );

  static List<BekleyenDekont> liste(dynamic json) {
    final harita = (json as Map? ?? const {});
    return (harita['dekontlar'] as List? ?? const [])
        .map((e) => BekleyenDekont.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

double? _sayi(dynamic deger) {
  if (deger == null) return null;
  if (deger is num) return deger.toDouble();
  return double.tryParse(deger.toString());
}
