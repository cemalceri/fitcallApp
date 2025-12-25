abstract class BaseSlotDto {
  final DateTime baslangic;
  final DateTime bitis;
  final int? kortId;
  final int? antrenorId;
  final String? kortAdi;
  final String? antrenorAdi;

  BaseSlotDto({
    required this.baslangic,
    required this.bitis,
    this.kortId,
    this.antrenorId,
    this.kortAdi,
    this.antrenorAdi,
  });
}
