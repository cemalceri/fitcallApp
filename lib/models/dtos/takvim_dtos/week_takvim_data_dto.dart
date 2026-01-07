import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/mesgul_slot_dto.dart';
import 'package:fitcall/models/dtos/takvim_dtos/uygun_slot_dto.dart';

class WeekTakvimDataDto {
  final List<EtkinlikModel> dersler;
  final List<MesgulSlotDto> mesgul;
  final List<UygunSlotDto> uygun;

  WeekTakvimDataDto(
      {required this.dersler, required this.mesgul, required this.uygun});
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
