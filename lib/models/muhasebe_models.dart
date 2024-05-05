class OdemeBorcModel {
  String hareketTuru;
  String ucretTuru;
  DateTime tarih;
  String tutar;
  String aciklama;

  OdemeBorcModel(
      {required this.hareketTuru,
      required this.tarih,
      required this.tutar,
      required this.ucretTuru,
      required this.aciklama});

  static List<OdemeBorcModel?> fromJson(decode) {
    List<OdemeBorcModel?> odemeBorcListesi = [];
    for (var odemeBorc in decode) {
      odemeBorcListesi.add(OdemeBorcModel(
        hareketTuru: odemeBorc['hareket_turu'] ?? '',
        ucretTuru: odemeBorc['ucret_turu'] ?? '',
        tarih: DateTime.parse(odemeBorc['tarih']!),
        tutar: odemeBorc['tutar']!,
        aciklama: odemeBorc['aciklama'] ?? '',
      ));
    }
    return odemeBorcListesi;
  }
}
