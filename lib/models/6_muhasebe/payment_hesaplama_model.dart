// lib/models/6_muhasebe/payment_hesaplama_model.dart

class OdemeKalemModel {
  final String type;
  final String aciklama;
  final double tutar;
  final double? oran;
  final int? yil;
  final int? ay;

  const OdemeKalemModel({
    required this.type,
    required this.aciklama,
    required this.tutar,
    this.oran,
    this.yil,
    this.ay,
  });

  factory OdemeKalemModel.fromJson(Map<String, dynamic> json) {
    return OdemeKalemModel(
      type: json['type'] ?? '',
      aciklama: json['aciklama'] ?? '',
      tutar: double.parse(json['tutar'].toString()),
      oran: json['oran'] != null ? double.parse(json['oran'].toString()) : null,
      yil: json['yil'],
      ay: json['ay'],
    );
  }

  bool get isBorc => type == 'borc';
}

class PaymentHesaplamaModel {
  final double araToplam;
  final List<OdemeKalemModel> kalemler;
  final double toplamTutar;

  const PaymentHesaplamaModel({
    required this.araToplam,
    required this.kalemler,
    required this.toplamTutar,
  });

  factory PaymentHesaplamaModel.fromJson(Map<String, dynamic> json) {
    return PaymentHesaplamaModel(
      araToplam: double.parse(json['ara_toplam'].toString()),
      kalemler: (json['kalemler'] as List)
          .map((e) => OdemeKalemModel.fromJson(e))
          .toList(),
      toplamTutar: double.parse(json['toplam_tutar'].toString()),
    );
  }

  List<OdemeKalemModel> get borcKalemleri =>
      kalemler.where((k) => k.isBorc).toList();

  List<OdemeKalemModel> get feeKalemleri =>
      kalemler.where((k) => !k.isBorc).toList();
}
