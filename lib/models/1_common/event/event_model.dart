class EventModel {
  final int id;
  final String ad;
  final DateTime baslangic;
  final DateTime bitis;
  final String? mekan;
  final int? maxMisafirKisiBasi;
  final bool aktifMi;
  final bool hpiPublic; // Herkese açık mı?
  final bool davetliMi; // Kullanıcı davetli mi? (private event için)
  final bool normalGirisAcikMi; // Normal girişe izin verilsin mi?

  EventModel({
    required this.id,
    required this.ad,
    required this.baslangic,
    required this.bitis,
    required this.mekan,
    required this.maxMisafirKisiBasi,
    required this.aktifMi,
    required this.hpiPublic,
    required this.davetliMi,
    required this.normalGirisAcikMi,
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
      hpiPublic: json['herkese_acik'] as bool? ?? true,
      davetliMi: json['davetli_mi'] as bool? ?? false,
      normalGirisAcikMi: json['normal_giris_acik_mi'] as bool? ?? true,
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
      'herkese_acik': hpiPublic,
      'davetli_mi': davetliMi,
      'normal_giris_acik_mi': normalGirisAcikMi,
    };
  }

  /// QR Giriş gösterilsin mi? (Public veya davetli veya normal giriş açık)
  bool get qrGirisGosterilsinMi => hpiPublic || davetliMi || normalGirisAcikMi;

  /// Event/Davet butonu gösterilsin mi? (Public veya davetli)
  bool get eventDavetGosterilsinMi => hpiPublic || davetliMi;
}
