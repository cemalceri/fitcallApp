// lib/models/5_etkinlik/ders_katilim_data.dart

import 'package:fitcall/models/5_etkinlik/katilim_model.dart';

/// getDersKatilimlari endpoint'inden dönen veri
class DersKatilimDto {
  final int dersId;
  final bool kilitliMi;
  final AntrenorOnayBilgisi? antrenorOnayi;
  final List<KatilimModel> katilimlar;

  const DersKatilimDto({
    required this.dersId,
    required this.kilitliMi,
    this.antrenorOnayi,
    required this.katilimlar,
  });

  factory DersKatilimDto.fromMap(Map<String, dynamic> m) {
    final katilimlarRaw = (m['katilimlar'] as List?) ?? const [];
    return DersKatilimDto(
      dersId: m['ders_id'] as int,
      kilitliMi: m['kilitli_mi'] == true,
      antrenorOnayi: m['antrenor_onayi'] == null
          ? null
          : AntrenorOnayBilgisi.fromMap(
              (m['antrenor_onayi'] as Map).cast<String, dynamic>(),
            ),
      katilimlar: katilimlarRaw
          .map((e) => KatilimModel.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class AntrenorOnayBilgisi {
  final bool? tamamlandi;
  final String? aciklama;
  final String? onayRedIptalNedeni;

  const AntrenorOnayBilgisi({
    this.tamamlandi,
    this.aciklama,
    this.onayRedIptalNedeni,
  });

  factory AntrenorOnayBilgisi.fromMap(Map<String, dynamic> m) {
    return AntrenorOnayBilgisi(
      tamamlandi: m['tamamlandi'] as bool?,
      aciklama: m['aciklama']?.toString(),
      onayRedIptalNedeni: m['onay_red_iptal_nedeni']?.toString(),
    );
  }
}
