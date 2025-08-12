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
  final int? kalanHak;
  final DateTime? bitis;

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
  });

  /* -------------------------------------------------------------------------- */
  /*                              JSON → Model                                  */
  /* -------------------------------------------------------------------------- */
  factory UyeUrunModel.fromJson(Map<String, dynamic> j) {
    DateTime? d(String? v) =>
        (v == null || v.isEmpty) ? null : DateTime.parse(v);

    return UyeUrunModel(
      id: j['id'],
      uyeId: j['uye'],
      urunId: j['urun'],
      urunAdi: j['urun_adi'] ?? '',
      toplamHak: j['toplam_hak'],
      kalanHak: j['kalan_hak'],
      baslangic: DateTime.parse(j['baslangic']),
      bitis: d(j['bitis']),
      aktifMi: j['aktif_mi'] ?? true,
    );
  }
}
