// lib/models/5_etkinlik/ders_katilim_data.dart

import 'package:fitcall/models/5_etkinlik/katilim_model.dart';
import 'package:fitcall/models/5_etkinlik/misafir_model.dart';

/// getDersKatilimlari endpoint'inden dönen veri
class DersKatilimDto {
  final int dersId;
  final bool kilitliMi;
  final AntrenorOnayBilgisi? antrenorOnayi;
  final List<KatilimModel> katilimlar;

  /// Üye olmayan katılımcılar. `katilimlar` uye_id anahtarlı olduğu için
  /// misafirler ayrı dizide taşınır.
  final List<MisafirModel> misafirler;

  const DersKatilimDto({
    required this.dersId,
    required this.kilitliMi,
    this.antrenorOnayi,
    required this.katilimlar,
    this.misafirler = const [],
  });

  factory DersKatilimDto.fromMap(Map<String, dynamic> m) {
    final katilimlarRaw = (m['katilimlar'] as List?) ?? const [];
    final misafirlerRaw = (m['misafirler'] as List?) ?? const [];
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
      misafirler: misafirlerRaw
          .map((e) => MisafirModel.fromMap((e as Map).cast<String, dynamic>()))
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
