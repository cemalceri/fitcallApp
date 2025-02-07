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

  static List<PaketModel>? fromJson(response) {
    List<PaketModel>? paketListesi = [];
    var body = utf8.decode(response.bodyBytes);
    List<dynamic> list = json.decode(body)['paketler'];
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

class UyelikModel {
  int id;
  String haftaninGunu;
  String baslangicSaati;
  String bitisSaati;
  String kortAdi;
  String aktifMi;

  UyelikModel({
    required this.id,
    required this.haftaninGunu,
    required this.baslangicSaati,
    required this.bitisSaati,
    required this.kortAdi,
    required this.aktifMi,
  });

  static List<UyelikModel>? fromJson(response) {
    List<UyelikModel>? uyelikListesi = [];
    var body = utf8.decode(response.bodyBytes);
    List<dynamic> list = json.decode(body)['uyelikler'];
    for (var uyelik in list) {
      uyelikListesi.add(UyelikModel(
          id: uyelik['id'] ?? 0,
          haftaninGunu: uyelik['gun_adi'] ?? '',
          baslangicSaati:
              uyelik['baslangic_tarih_saat'].toString().split('T')[1],
          bitisSaati: uyelik['bitis_tarih_saat'].toString().split('T')[1],
          kortAdi: uyelik['kort_adi'] ?? '',
          aktifMi: uyelik['aktif_mi'] ? "Aktif" : "Pasif"));
    }
    return uyelikListesi;
  }
}
