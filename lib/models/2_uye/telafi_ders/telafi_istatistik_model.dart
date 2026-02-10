class TelafiIstatistikModel {
  final int toplam;
  final int aktif;
  final int yapilan;
  final int suresiGecen;

  TelafiIstatistikModel({
    required this.toplam,
    required this.aktif,
    required this.yapilan,
    required this.suresiGecen,
  });

  factory TelafiIstatistikModel.fromJson(Map<String, dynamic> json) {
    return TelafiIstatistikModel(
      toplam: json['toplam'] as int? ?? 0,
      aktif: json['aktif'] as int? ?? 0,
      yapilan: json['yapilan'] as int? ?? 0,
      suresiGecen: json['suresi_geden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toplam': toplam,
      'aktif': aktif,
      'yapilan': yapilan,
      'suresi_geden': suresiGecen,
    };
  }
}
