import 'package:fitcall/common/tarih_util.dart';

/// ÜyeUrunModel – Django ‹UyeUrunModel› eşlemesi
class UyeUrunModel {
  /* -------------------------------------------------------------------------- */
  /*                              ZORUNLU alanlar                               */
  /* -------------------------------------------------------------------------- */
  final int id;
  final int uyeId;
  final int urunId;
  final String urunAdi;
  final DateTime baslangic;
  final bool aktifMi;

  /* -------------------------------------------------------------------------- */
  /*                             OPSİYONEL alanlar                              */
  /* -------------------------------------------------------------------------- */
  final int? toplamHak;
  final num? kalanHak;
  final DateTime? bitis;

  /// Ürün tipi: PAKET | ABONELIK | TEK_SEFERLIK (backend UrunTipiEnum).
  final String? urunTipi;

  /// Tek ders (TEK_SEFERLIK) için yapılan ders(ler)in özet bilgisi.
  /// Backend `getUyeUrunList` bu alanı tek ders ürünleri için doldurur;
  /// diğer tiplerde boş gelir.
  final List<UyeUrunDersBilgi> dersler;

  /* -------------------------------------------------------------------------- */
  /*                                   CTOR                                     */
  /* -------------------------------------------------------------------------- */
  UyeUrunModel({
    required this.id,
    required this.uyeId,
    required this.urunId,
    required this.urunAdi,
    required this.baslangic,
    required this.aktifMi,
    this.toplamHak,
    this.kalanHak,
    this.bitis,
    this.urunTipi,
    this.dersler = const [],
  });

  /* -------------------------------------------------------------------------- */
  /*                              Tip yardımcıları                              */
  /* -------------------------------------------------------------------------- */
  bool get isPaket => (urunTipi ?? '').toUpperCase() == 'PAKET';
  bool get isAidat => (urunTipi ?? '').toUpperCase() == 'ABONELIK';
  bool get isTekDers => (urunTipi ?? '').toUpperCase() == 'TEK_SEFERLIK';

  /* -------------------------------------------------------------------------- */
  /*                              JSON → Model                                  */
  /* -------------------------------------------------------------------------- */
  factory UyeUrunModel.fromJson(Map<String, dynamic> j) {
    DateTime? d(String? v) =>
        (v == null || v.isEmpty) ? null : parseApiTarihOrNow(v);
    num? kalan = j['kalan_hak'] is num
        ? j['kalan_hak'] as num
        : num.tryParse('${j['kalan_hak'] ?? ''}');
    if (kalan != null && kalan % 1 == 0) kalan = kalan.toInt();

    final dersHam = j['dersler'];
    final List<UyeUrunDersBilgi> dersList = (dersHam is List)
        ? dersHam
            .whereType<Map>()
            .map((e) => UyeUrunDersBilgi.fromJson(e.cast<String, dynamic>()))
            .toList()
        : const [];

    return UyeUrunModel(
      id: (j['id'] as num).toInt(),
      uyeId: (j['uye'] as num).toInt(),
      urunId: (j['urun'] as num).toInt(),
      urunAdi: j['urun_adi'] ?? '',
      toplamHak: (j['toplam_hak'] as num?)?.toInt(),
      kalanHak: kalan,
      baslangic: parseApiTarihOrNow(j['baslangic']),
      bitis: d(j['bitis']),
      aktifMi: j['aktif_mi'] ?? true,
      urunTipi: j['urun_tipi']?.toString(),
      dersler: dersList,
    );
  }
}

/// Tek ders (TEK_SEFERLIK) ürününe bağlı yapılan ders bilgisi.
class UyeUrunDersBilgi {
  final int? etkinlikId;
  final DateTime? tarih;
  final String? kortAdi;
  final String? antrenorAdi;

  UyeUrunDersBilgi({
    this.etkinlikId,
    this.tarih,
    this.kortAdi,
    this.antrenorAdi,
  });

  factory UyeUrunDersBilgi.fromJson(Map<String, dynamic> j) {
    return UyeUrunDersBilgi(
      etkinlikId: (j['etkinlik_id'] as num?)?.toInt(),
      tarih: (j['tarih'] == null || j['tarih'].toString().isEmpty)
          ? null
          : parseApiTarihOrNow(j['tarih']),
      kortAdi: j['kort_adi']?.toString(),
      antrenorAdi: j['antrenor_adi']?.toString(),
    );
  }
}
