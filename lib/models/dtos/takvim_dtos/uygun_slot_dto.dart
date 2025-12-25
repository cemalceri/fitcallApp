import 'package:fitcall/models/dtos/takvim_dtos/base_slot_dto.dart';

class UygunSlotDto extends BaseSlotDto {
  final List<KortMiniDto> kortlar;

  UygunSlotDto({
    required super.baslangic,
    required super.bitis,
    super.antrenorId,
    super.antrenorAdi,
    required this.kortlar,
  });

  factory UygunSlotDto.fromJson(Map<String, dynamic> j) {
    return UygunSlotDto(
      baslangic: DateTime.parse(j['baslangic_tarih_saat']).toLocal(),
      bitis: DateTime.parse(j['bitis_tarih_saat']).toLocal(),
      antrenorId: j['antrenor_id'] is int
          ? j['antrenor_id']
          : int.tryParse('${j['antrenor_id'] ?? ''}'),
      antrenorAdi: j['antrenor_adi']?.toString(),
      kortlar: (j['kortlar'] as List? ?? [])
          .map((e) => KortMiniDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class KortMiniDto {
  final int id;
  final String adi;

  KortMiniDto({
    required this.id,
    required this.adi,
  });

  factory KortMiniDto.fromJson(Map<String, dynamic> j) {
    return KortMiniDto(
      id: j['id'] is int ? j['id'] : int.parse('${j['id']}'),
      adi: j['adi']?.toString() ?? '',
    );
  }
}
