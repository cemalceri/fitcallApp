// lib/models/2_uye/uye_home_ozet_model.dart

import 'package:fitcall/models/3_antrenor/home_card_model.dart';

/// getUyeHomeOzet cevabındaki özet şeridi verileri
class UyeOzetModel {
  /// Genel bakiye (ödeme - borç). Negatif = borç.
  final double bakiye;

  /// Aktif paketlerin kalan hak toplamı. Hak takipli paket yoksa null.
  final double? kalanPaketHak;

  /// Kullanılmamış ve süresi geçmemiş telafi hakkı sayısı.
  final int aktifTelafi;

  UyeOzetModel({
    required this.bakiye,
    this.kalanPaketHak,
    required this.aktifTelafi,
  });

  factory UyeOzetModel.fromJson(Map<String, dynamic> json) {
    return UyeOzetModel(
      bakiye: (json['bakiye'] as num?)?.toDouble() ?? 0.0,
      kalanPaketHak: (json['kalan_paket_hak'] as num?)?.toDouble(),
      aktifTelafi: (json['aktif_telafi'] as num?)?.toInt() ?? 0,
    );
  }
}

/// getUyeHomeOzet cevabı: özet + yapılacaklar kartları
class UyeHomeOzetModel {
  final UyeOzetModel ozet;
  final List<HomeCardModel> kartlar;

  UyeHomeOzetModel({required this.ozet, required this.kartlar});

  factory UyeHomeOzetModel.fromJson(Map<String, dynamic> json) {
    final kartlarJson = (json['kartlar'] as List?) ?? const [];
    return UyeHomeOzetModel(
      ozet: UyeOzetModel.fromJson(
          (json['ozet'] as Map?)?.cast<String, dynamic>() ?? const {}),
      kartlar: kartlarJson
          .map(
              (e) => HomeCardModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
