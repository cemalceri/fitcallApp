import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';

class WeekTakvimDataDto {
  final List<EtkinlikModel> dersler;

  WeekTakvimDataDto({required this.dersler});
}

class AntrenorTakvimDataDto {
  final List<EtkinlikModel> dersler;

  AntrenorTakvimDataDto({
    required this.dersler,
  });

  /// Backend'den gelen ders listesini parse eder
  factory AntrenorTakvimDataDto.fromBackendList(List<dynamic> jsonList) {
    final dersler = jsonList
        .map((item) => EtkinlikModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return AntrenorTakvimDataDto(dersler: dersler);
  }
}
