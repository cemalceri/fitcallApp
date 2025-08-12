// lib/models/dtos/paket_secim_item.dart
class PaketSecimItem {
  final int urunId;
  final String urunAdi;
  final int ucret; // orijinal
  final int ucretCarpanli; // katsayı uygulanmış
  final bool sahipMi;
  final String urunTipi;

  const PaketSecimItem({
    required this.urunId,
    required this.urunAdi,
    required this.ucret,
    required this.ucretCarpanli,
    required this.sahipMi,
    required this.urunTipi,
  });

  factory PaketSecimItem.fromJson(Map<String, dynamic> j) => PaketSecimItem(
        urunId: j['urun_id'],
        urunAdi: j['urun_adi'] ?? '',
        ucret: (j['ucret'] ?? 0) is int
            ? j['ucret']
            : int.tryParse('${j['ucret'] ?? 0}') ?? 0,
        ucretCarpanli: (j['ucret_carpanli'] ?? 0) is int
            ? j['ucret_carpanli']
            : int.tryParse('${j['ucret_carpanli'] ?? 0}') ?? 0,
        sahipMi: j['sahip_mi'] ?? false,
        urunTipi: j['urun_tipi'] ?? '',
      );
}
