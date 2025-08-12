import 'package:fitcall/models/8_urun/urun_model.dart';
import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/models/dtos/paket_secim_item.dart';

class PaketVeriResponse {
  final List<UyeUrunModel> mevcutlar;
  final List<UrunModel> urunler;
  final List<PaketSecimItem> secenekler;
  final double katsayi;

  PaketVeriResponse({
    required this.mevcutlar,
    required this.urunler,
    required this.secenekler,
    required this.katsayi,
  });

  factory PaketVeriResponse.fromJson(Map<String, dynamic> j) {
    final mevcutlarJson = (j['mevcutlar'] as List? ?? [])
        .map((e) => UyeUrunModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final urunlerJson = (j['urunler'] as List? ?? [])
        .map((e) => UrunModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final seceneklerJson = (j['secenekler'] as List? ?? [])
        .map((e) => PaketSecimItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final katsayi = (j['katsayi'] is num)
        ? (j['katsayi'] as num).toDouble()
        : double.tryParse('${j['katsayi'] ?? 1}') ?? 1.0;

    return PaketVeriResponse(
      mevcutlar: mevcutlarJson,
      urunler: urunlerJson,
      secenekler: seceneklerJson,
      katsayi: katsayi,
    );
  }
}
