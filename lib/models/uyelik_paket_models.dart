import 'dart:convert';

class PaketModel {
  int id;
  String paketAdi;
  bool grupMu;
  DateTime? baslangicTarih;
  DateTime? bitisTarih;
  int adet;
  int kalanAdet;
  String ozellikler;

  PaketModel({
    required this.id,
    required this.paketAdi,
    required this.grupMu,
    required this.baslangicTarih,
    this.bitisTarih,
    required this.adet,
    required this.kalanAdet,
    required this.ozellikler,
  });

  static List<PaketModel?> fromJson(response) {
    List<PaketModel?> paketListesi = [];
    List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
    for (var paket in list) {
      paketListesi.add(PaketModel(
        id: paket['id'] ?? 0,
        grupMu: paket['grup_mu'] ?? false,
        paketAdi: paket['paket_adi'] ?? '',
        baslangicTarih: paket['baslangic_tarih'] != null
            ? DateTime.parse(paket['baslangic_tarih'])
            : null,
        bitisTarih: paket['bitis_tarih'] != null
            ? DateTime.parse(paket['bitis_tarih'])
            : null,
        adet: paket['adet'] ?? 0,
        kalanAdet: paket['kalan_adet'] ?? 0,
        ozellikler: paket['ozellikler'] ?? '',
      ));
    }
    return paketListesi;
  }
}
