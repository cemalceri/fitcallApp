class UygunSaatlerRequestModel {
  final DateTime startDate;
  final DateTime endDate;
  final int? antrenorId;
  final int? kortId;
  final int slotSaat;

  UygunSaatlerRequestModel({
    required this.startDate,
    required this.endDate,
    this.antrenorId,
    this.kortId,
    this.slotSaat = 1,
  });

  factory UygunSaatlerRequestModel.fromJson(Map<String, dynamic> json) {
    return UygunSaatlerRequestModel(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      antrenorId:
          json['antrenor_id'] != null ? json['antrenor_id'] as int : null,
      kortId: json['kort_id'] != null ? json['kort_id'] as int : null,
      slotSaat: json['slot_saat'] != null ? json['slot_saat'] as int : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'antrenor_id': antrenorId,
        'kort_id': kortId,
        'slot_saat': slotSaat,
      };
}

class UygunSaatModel {
  final DateTime tarih;
  final String gun;
  final String baslangic;
  final String bitis;
  final String kort;
  final int kortId;
  final String antrenor;
  final int antrenorId;

  UygunSaatModel({
    required this.tarih,
    required this.gun,
    required this.baslangic,
    required this.bitis,
    required this.kort,
    required this.kortId,
    required this.antrenor,
    required this.antrenorId,
  });

  factory UygunSaatModel.fromJson(Map<String, dynamic> json) {
    return UygunSaatModel(
      tarih: DateTime.parse(json['tarih']),
      gun: json['gun'],
      baslangic: json['baslangic'],
      bitis: json['bitis'],
      kort: json['kort'],
      kortId: json['kort_id'],
      antrenor: json['antrenor'],
      antrenorId: json['antrenor_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tarih': tarih.toIso8601String().substring(0, 10),
        'gun': gun,
        'baslangic': baslangic,
        'bitis': bitis,
        'kort': kort,
        'kort_id': kortId,
        'antrenor': antrenor,
        'antrenor_id': antrenorId,
      };
}

class UygunSaatlerResponseModel {
  final List<UygunSaatModel> uygunSaatler;

  UygunSaatlerResponseModel({required this.uygunSaatler});

  factory UygunSaatlerResponseModel.fromJson(Map<String, dynamic> json) {
    var list = json['uygun_saatler'] as List;
    List<UygunSaatModel> saatler = list
        .map((e) => UygunSaatModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return UygunSaatlerResponseModel(uygunSaatler: saatler);
  }

  Map<String, dynamic> toJson() => {
        'uygun_saatler': uygunSaatler.map((e) => e.toJson()).toList(),
      };
}
