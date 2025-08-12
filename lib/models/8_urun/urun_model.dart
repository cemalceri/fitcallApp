// lib/models/urun/urun_model.dart
class UrunModel {
  final int id;
  final String adi;
  final int ucret; // Decimal(0) kullandığınız için tam sayı tl
  final int adet;
  final bool mobilAlimaUygunMu;
  final String urunTipi;
  final String? aciklama;

  UrunModel({
    required this.id,
    required this.adi,
    required this.ucret,
    required this.adet,
    required this.mobilAlimaUygunMu,
    required this.urunTipi,
    this.aciklama,
  });

  factory UrunModel.fromJson(Map<String, dynamic> j) => UrunModel(
        id: j['id'],
        adi: j['adi'] ?? '',
        ucret: (j['ucret'] ?? 0) is int
            ? j['ucret']
            : int.tryParse('${j['ucret'] ?? 0}') ?? 0,
        adet: j['adet'] ?? 1,
        mobilAlimaUygunMu: j['mobil_alima_uygun_mu'] ?? false,
        urunTipi: j['urun_tipi'] ?? '',
        aciklama: j['aciklama'],
      );
}
