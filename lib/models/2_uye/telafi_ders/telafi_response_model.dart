import 'package:fitcall/models/2_uye/telafi_ders/telafi_ders_model.dart';
import 'package:fitcall/models/2_uye/telafi_ders/telafi_istatistik_model.dart';

class TelafiResponseModel {
  final List<TelafiDersModel> telafiListesi;
  final TelafiIstatistikModel istatistik;

  TelafiResponseModel({
    required this.telafiListesi,
    required this.istatistik,
  });

  factory TelafiResponseModel.fromJson(Map<String, dynamic> json) {
    return TelafiResponseModel(
      telafiListesi: (json['telafi_listesi'] as List?)
              ?.map((e) => TelafiDersModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      istatistik: TelafiIstatistikModel.fromJson(
          json['istatistik'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telafi_listesi': telafiListesi.map((e) => e.toJson()).toList(),
      'istatistik': istatistik.toJson(),
    };
  }
}
