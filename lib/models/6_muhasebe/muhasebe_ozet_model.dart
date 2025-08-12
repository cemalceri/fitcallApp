class MuhasebeOzetModel {
  final int yil;
  final int ay;
  final double borc;
  final double odeme;

  const MuhasebeOzetModel({
    required this.yil,
    required this.ay,
    required this.borc,
    required this.odeme,
  });

  double get fark => odeme - borc;

  factory MuhasebeOzetModel.fromJson(Map<String, dynamic> json) {
    return MuhasebeOzetModel(
      yil: json['yil'],
      ay: json['ay'],
      borc: double.parse(json['borc'].toString()),
      odeme: double.parse(json['odeme'].toString()),
    );
  }

  static List<MuhasebeOzetModel> listFromJson(dynamic json) {
    return (json as List)
        .map((e) =>
            MuhasebeOzetModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
