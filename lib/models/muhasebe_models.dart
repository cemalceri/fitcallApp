import 'dart:convert';

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

  static List<OdemeBorcModel?> fromJson(response) {
    List<OdemeBorcModel?> odemeBorcListesi = [];
    List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
    for (var odemeBorc in list) {
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
