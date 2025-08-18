class EventModel {
  final int id;
  final String ad;
  final DateTime baslangic;
  final DateTime bitis;
  final String? mekan;
  final int? maxMisafirKisiBasi; // camelCase
  final bool aktifMi; // camelCase

  EventModel({
    required this.id,
    required this.ad,
    required this.baslangic,
    required this.bitis,
    required this.mekan,
    required this.maxMisafirKisiBasi,
    required this.aktifMi,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      ad: json['ad'] as String,
      baslangic: DateTime.parse(json['baslangic'] as String),
      bitis: DateTime.parse(json['bitis'] as String),
      mekan: json['mekan'] as String?,
      maxMisafirKisiBasi: json['max_misafir_kisi_basi'] as int?,
      aktifMi: json['aktif_mi'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'baslangic': baslangic.toIso8601String(),
      'bitis': bitis.toIso8601String(),
      'mekan': mekan,
      'max_misafir_kisi_basi': maxMisafirKisiBasi,
      'aktif_mi': aktifMi,
    };
  }
}
