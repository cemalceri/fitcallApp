// lib/models/6_muhasebe/muhasebe_ozet_model.dart

class MuhasebeOzetModel {
  final int yil;
  final int ay;
  final double borc;
  final double odeme;
  final double acilisBakiyesi; // önceki aylardan devreden (+ fazla / - borç)
  final double kapanisBakiyesi; // ay sonu kümülatif (+ fazla / - borç)

  const MuhasebeOzetModel({
    required this.yil,
    required this.ay,
    required this.borc,
    required this.odeme,
    required this.acilisBakiyesi,
    required this.kapanisBakiyesi,
  });

  /// Bu ayın net hareketi (+ ödeme fazlalığı / - borç fazlalığı)
  double get buAyNet => odeme - borc;

  /// Eski kullanım için geriye uyumluluk
  double get fark => odeme - borc;

  bool get bakiyeFazla => kapanisBakiyesi > 0;
  bool get bakiyeBorc => kapanisBakiyesi < 0;
  bool get bakiyeSifir => kapanisBakiyesi == 0;

  factory MuhasebeOzetModel.fromJson(Map<String, dynamic> json) {
    return MuhasebeOzetModel(
      yil: json['yil'] as int,
      ay: json['ay'] as int,
      borc: double.parse(json['borc'].toString()),
      odeme: double.parse(json['odeme'].toString()),
      acilisBakiyesi: double.parse(
        (json['acilis_bakiyesi'] ?? 0).toString(),
      ),
      kapanisBakiyesi: double.parse(
        (json['kapanis_bakiyesi'] ?? 0).toString(),
      ),
    );
  }

  static List<MuhasebeOzetModel> listFromJson(dynamic json) {
    return (json as List)
        .map((e) =>
            MuhasebeOzetModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
