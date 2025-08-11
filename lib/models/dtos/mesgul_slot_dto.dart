class MesgulSlotDto {
  final DateTime baslangic;
  final DateTime bitis;
  final int? kortId;
  final int? antrenorId;
  final String? kortAdi;
  final String? antrenorAdi;

  MesgulSlotDto({
    required this.baslangic,
    required this.bitis,
    this.kortId,
    this.antrenorId,
    this.kortAdi,
    this.antrenorAdi,
  });

  factory MesgulSlotDto.fromJson(Map<String, dynamic> j) {
    return MesgulSlotDto(
      baslangic: DateTime.parse(j['baslangic_tarih_saat']).toLocal(),
      bitis: DateTime.parse(j['bitis_tarih_saat']).toLocal(),
      kortId: j['kort_id'] is int
          ? j['kort_id']
          : int.tryParse('${j['kort_id'] ?? ''}'),
      antrenorId: j['antrenor_id'] is int
          ? j['antrenor_id']
          : int.tryParse('${j['antrenor_id'] ?? ''}'),
      kortAdi: j['kort_adi']?.toString(),
      antrenorAdi: j['antrenor_adi']?.toString(),
    );
  }
}
