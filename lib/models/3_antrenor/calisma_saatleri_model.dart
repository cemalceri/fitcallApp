// lib/models/3_antrenor/calisma_saatleri_model.dart

/// Gün referansı (GunlerModel)
class GunModel {
  final int gunId;
  final String gunAdi;
  final int haftaninGunu; // 0 = Pazartesi

  GunModel({
    required this.gunId,
    required this.gunAdi,
    required this.haftaninGunu,
  });

  factory GunModel.fromJson(Map<String, dynamic> json) {
    return GunModel(
      gunId: (json['gun_id'] as num?)?.toInt() ?? 0,
      gunAdi: json['gun_adi'] ?? '',
      haftaninGunu: (json['haftanin_gunu'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Antrenörün bir güne ait çalışma saati kaydı
class CalismaSaatiModel {
  final int? id;
  final int gunId;
  final String gunAdi;
  final int haftaninGunu;
  final String baslangicSaat; // "09:00"
  final String bitisSaat; // "18:00"

  CalismaSaatiModel({
    this.id,
    required this.gunId,
    required this.gunAdi,
    required this.haftaninGunu,
    required this.baslangicSaat,
    required this.bitisSaat,
  });

  factory CalismaSaatiModel.fromJson(Map<String, dynamic> json) {
    return CalismaSaatiModel(
      id: (json['id'] as num?)?.toInt(),
      gunId: (json['gun_id'] as num?)?.toInt() ?? 0,
      gunAdi: json['gun_adi'] ?? '',
      haftaninGunu: (json['haftanin_gunu'] as num?)?.toInt() ?? 0,
      baslangicSaat: json['baslangic_saat'] ?? '',
      bitisSaat: json['bitis_saat'] ?? '',
    );
  }

  Map<String, dynamic> toSetJson() => {
        'gun_id': gunId,
        'baslangic_saat': baslangicSaat,
        'bitis_saat': bitisSaat,
      };
}

/// getAntrenorCalismaGunleri cevabı
class CalismaGunleriResponse {
  final List<GunModel> gunler;
  final List<CalismaSaatiModel> calismaSaatleri;

  CalismaGunleriResponse({
    required this.gunler,
    required this.calismaSaatleri,
  });

  factory CalismaGunleriResponse.fromJson(Map<String, dynamic> json) {
    return CalismaGunleriResponse(
      gunler: ((json['gunler'] as List?) ?? const [])
          .map((e) => GunModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      calismaSaatleri: ((json['calisma_saatleri'] as List?) ?? const [])
          .map((e) =>
              CalismaSaatiModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
