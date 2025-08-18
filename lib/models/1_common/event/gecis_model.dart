class GecisModel {
  final String kapsam;
  final String gecisTipi;
  final int? eventId;
  final String code;
  final DateTime expiresAt;
  final bool iptalMi;
  final String? label; // davetli adı-soyadı (opsiyonel)

  GecisModel({
    required this.kapsam,
    required this.gecisTipi,
    required this.eventId,
    required this.code,
    required this.expiresAt,
    required this.iptalMi,
    this.label,
  });

  factory GecisModel.fromJson(Map<String, dynamic> json) => GecisModel(
        kapsam: json['kapsam'] as String,
        gecisTipi: json['gecis_tipi'] as String,
        eventId: json['event_id'] as int?,
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        iptalMi: json['iptal_mi'] as bool,
        label: json['label'] as String?, // backend eklediyse gelir
      );

  Map<String, dynamic> toJson() => {
        'kapsam': kapsam,
        'gecis_tipi': gecisTipi,
        'event_id': eventId,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'iptal_mi': iptalMi,
        if (label != null) 'label': label,
      };
}
