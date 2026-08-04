// lib/models/5_etkinlik/katilim_model.dart

class KatilimModel {
  final int uyeId;
  final String adSoyad;
  final bool planliMi;
  final bool? katildi; // null = henüz işaretlenmemiş
  final bool planDisiMi;
  final String? notMetni;

  /// Yönetici parasal kararı verdiyse (borç yazıldı / paketten düşüldü /
  /// ücretsiz denildi) antrenör bu satırı listeden çıkaramaz.
  final bool kararVerildiMi;

  const KatilimModel({
    required this.uyeId,
    required this.adSoyad,
    required this.planliMi,
    this.katildi,
    this.planDisiMi = false,
    this.notMetni,
    this.kararVerildiMi = false,
  });

  factory KatilimModel.fromMap(Map<String, dynamic> m) {
    return KatilimModel(
      uyeId: m['uye_id'] as int,
      adSoyad: m['ad_soyad']?.toString() ?? '',
      planliMi: m['planli_mi'] == true,
      katildi: m['katildi'] as bool?,
      planDisiMi: m['plan_disi_mi'] == true,
      notMetni: m['not_metni']?.toString(),
      kararVerildiMi: m['karar_verildi_mi'] == true,
    );
  }

  Map<String, dynamic> toRequestMap() {
    return {
      'uye_id': uyeId,
      'katildi': katildi ?? false,
      'plan_disi_mi': planDisiMi,
      if (notMetni != null && notMetni!.isNotEmpty) 'not_metni': notMetni,
    };
  }

  KatilimModel copyWith({
    bool? katildi,
    String? notMetni,
    bool clearNot = false,
  }) {
    return KatilimModel(
      uyeId: uyeId,
      adSoyad: adSoyad,
      planliMi: planliMi,
      katildi: katildi ?? this.katildi,
      planDisiMi: planDisiMi,
      notMetni: clearNot ? null : (notMetni ?? this.notMetni),
      kararVerildiMi: kararVerildiMi,
    );
  }
}
