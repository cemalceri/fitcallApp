// lib/models/9_yonetici/doluluk_haritasi_model.dart

/// Kort doluluk ısı haritası: saat (satır) x haftanın günü (sütun) ders sayısı.
class DolulukHaritasiSatir {
  final int saat;
  final List<int> degerler; // 7 gün (Pzt..Paz)

  DolulukHaritasiSatir({
    required this.saat,
    required this.degerler,
  });

  factory DolulukHaritasiSatir.fromJson(Map<String, dynamic> json) {
    return DolulukHaritasiSatir(
      saat: json['saat'] ?? 0,
      degerler: (json['degerler'] as List? ?? [])
          .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
          .toList(),
    );
  }
}

class DolulukHaritasi {
  final String donem;
  final List<String> gunler;
  final List<int> saatler;
  final List<DolulukHaritasiSatir> hucreler;
  final int maxSayi;
  final int toplamDers;

  DolulukHaritasi({
    required this.donem,
    required this.gunler,
    required this.saatler,
    required this.hucreler,
    required this.maxSayi,
    required this.toplamDers,
  });

  factory DolulukHaritasi.fromJson(Map<String, dynamic> json) {
    return DolulukHaritasi(
      donem: json['donem'] ?? '',
      gunler:
          (json['gunler'] as List? ?? []).map((e) => e.toString()).toList(),
      saatler: (json['saatler'] as List? ?? [])
          .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
          .toList(),
      hucreler: (json['hucreler'] as List? ?? [])
          .map((e) => DolulukHaritasiSatir.fromJson(e))
          .toList(),
      maxSayi: json['max_sayi'] ?? 0,
      toplamDers: json['toplam_ders'] ?? 0,
    );
  }
}
