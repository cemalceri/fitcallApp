// lib/models/2_uye/uye_odul_model.dart
//
// getUyeOdulDurumu / odulTalepEt cevapları.
// Sayaç turnike geçişlerinden backend'de hesaplanır; mobil taraf sadece gösterir.

import 'package:fitcall/common/tarih_util.dart';

/// Üyenin hak edip aldığı, kafede kullanılmayı bekleyen ödül kodu.
class OdulKoduModel {
  final String kod;
  final String durum; // BEKLIYOR | KULLANILDI | SURESI_DOLDU
  final DateTime? kazanmaZamani;
  final DateTime? sonKullanma;

  /// Backend'in hazır formatladığı "29.07.2026" metni.
  final String sonKullanmaMetin;

  OdulKoduModel({
    required this.kod,
    required this.durum,
    this.kazanmaZamani,
    this.sonKullanma,
    required this.sonKullanmaMetin,
  });

  factory OdulKoduModel.fromJson(Map<String, dynamic> json) => OdulKoduModel(
        kod: (json['kod'] as String?) ?? '',
        durum: (json['durum'] as String?) ?? 'BEKLIYOR',
        kazanmaZamani: parseApiTarih(json['kazanma_zamani']),
        sonKullanma: parseApiTarih(json['son_kullanma']),
        sonKullanmaMetin: (json['son_kullanma_metin'] as String?) ?? '',
      );
}

/// Ana ekrandaki sayacın ihtiyacı olan her şey.
class OdulDurumModel {
  /// İşletmede tanımlı aktif bir ödül yoksa false; kart hiç gösterilmez.
  final bool aktif;
  final String odulAdi;
  final String? aciklama;

  /// Şimdilik yalnızca "kahve". İleride başka ödüller için görsel anahtarı.
  final String ikon;

  /// Ödülün hak edilmesi için gereken giriş sayısı (yönetici değiştirebilir).
  final int esik;

  /// Sayaç değeri; eşiği aşan geçişler devretmediği için eşikte durur.
  final int sayac;
  final int kalan;
  final bool hakEdildi;
  final OdulKoduModel? bekleyenOdul;

  OdulDurumModel({
    required this.aktif,
    required this.odulAdi,
    this.aciklama,
    required this.ikon,
    required this.esik,
    required this.sayac,
    required this.kalan,
    required this.hakEdildi,
    this.bekleyenOdul,
  });

  factory OdulDurumModel.fromJson(Map<String, dynamic> json) {
    if (json['aktif'] != true) return OdulDurumModel.pasif();

    final bekleyen = (json['bekleyen_odul'] as Map?)?.cast<String, dynamic>();
    return OdulDurumModel(
      aktif: true,
      odulAdi: (json['odul_adi'] as String?) ?? 'Ödül',
      aciklama: json['aciklama'] as String?,
      ikon: (json['ikon'] as String?) ?? 'kahve',
      esik: (json['esik'] as num?)?.toInt() ?? 0,
      sayac: (json['sayac'] as num?)?.toInt() ?? 0,
      kalan: (json['kalan'] as num?)?.toInt() ?? 0,
      hakEdildi: json['hak_edildi'] == true,
      bekleyenOdul: bekleyen == null ? null : OdulKoduModel.fromJson(bekleyen),
    );
  }

  factory OdulDurumModel.pasif() => OdulDurumModel(
        aktif: false,
        odulAdi: '',
        ikon: 'kahve',
        esik: 0,
        sayac: 0,
        kalan: 0,
        hakEdildi: false,
      );

  /// Fincanın ne kadar dolacağı (0.0 - 1.0).
  double get doluluk {
    if (esik <= 0) return 0;
    return (sayac / esik).clamp(0.0, 1.0);
  }

  /// Kullanılmayı bekleyen bir kod var mı?
  bool get kodHazir => bekleyenOdul != null;

  /// "Ödülü al" butonu gösterilsin mi?
  bool get talepEdilebilir => hakEdildi && !kodHazir;
}
