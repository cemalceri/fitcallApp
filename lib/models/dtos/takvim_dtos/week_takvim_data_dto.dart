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
