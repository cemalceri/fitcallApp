import 'package:fitcall/models/dtos/takvim_dtos/base_slot_dto.dart';

class MesgulSlotDto extends BaseSlotDto {
  MesgulSlotDto({
    required super.baslangic,
    required super.bitis,
    super.antrenorId,
    super.antrenorAdi,
  });

  factory MesgulSlotDto.fromJson(Map<String, dynamic> j) {
    return MesgulSlotDto(
      baslangic: DateTime.parse(j['baslangic_tarih_saat']).toLocal(),
      bitis: DateTime.parse(j['bitis_tarih_saat']).toLocal(),
      antrenorId: j['antrenor_id'] is int
          ? j['antrenor_id']
          : int.tryParse('${j['antrenor_id'] ?? ''}'),
      antrenorAdi: j['antrenor_adi']?.toString(),
    );
  }
}
