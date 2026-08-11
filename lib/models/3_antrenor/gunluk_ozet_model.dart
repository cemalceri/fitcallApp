// lib/models/3_antrenor/gunluk_ozet_model.dart

/// Yoklaması eksik ders özeti (kokpit uyarı satırı için)
class EksikYoklamaDers {
  final int id;
  final String saat;
  final String kortAdi;

  EksikYoklamaDers(
      {required this.id, required this.saat, required this.kortAdi});

  factory EksikYoklamaDers.fromJson(Map<String, dynamic> json) {
    return EksikYoklamaDers(
      id: (json['id'] as num?)?.toInt() ?? 0,
      saat: json['saat'] ?? '',
      kortAdi: json['kort_adi'] ?? '',
    );
  }
}

/// getAntrenorGunlukOzet cevabı: antrenör günlük kokpiti
class GunlukOzetModel {
  final String tarih;
  final int dersSayisi;
  final int iptal;
  final int tamamlanan;
  final int kalan;
  final int ogrenciSayisi;
  final String? ilkDers;
  final String? sonDers;
  final int eksikYoklama;
  final List<EksikYoklamaDers> eksikYoklamaDersler;
  final int eksikYoklamaGecmis;

  GunlukOzetModel({
    required this.tarih,
    required this.dersSayisi,
    required this.iptal,
    required this.tamamlanan,
    required this.kalan,
    required this.ogrenciSayisi,
    this.ilkDers,
    this.sonDers,
    required this.eksikYoklama,
    required this.eksikYoklamaDersler,
    required this.eksikYoklamaGecmis,
  });

  factory GunlukOzetModel.fromJson(Map<String, dynamic> json) {
    return GunlukOzetModel(
      tarih: json['tarih'] ?? '',
      dersSayisi: (json['ders_sayisi'] as num?)?.toInt() ?? 0,
      iptal: (json['iptal'] as num?)?.toInt() ?? 0,
      tamamlanan: (json['tamamlanan'] as num?)?.toInt() ?? 0,
      kalan: (json['kalan'] as num?)?.toInt() ?? 0,
      ogrenciSayisi: (json['ogrenci_sayisi'] as num?)?.toInt() ?? 0,
      ilkDers: json['ilk_ders'],
      sonDers: json['son_ders'],
      eksikYoklama: (json['eksik_yoklama'] as num?)?.toInt() ?? 0,
      eksikYoklamaDersler:
          ((json['eksik_yoklama_dersler'] as List?) ?? const [])
              .map((e) =>
                  EksikYoklamaDers.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
      eksikYoklamaGecmis: (json['eksik_yoklama_gecmis'] as num?)?.toInt() ?? 0,
    );
  }
}
