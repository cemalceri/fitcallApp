// lib/models/5_etkinlik/misafir_model.dart

/// Derse plan dışı katılan, sistemde kayıtlı olmayan kişi.
///
/// Katılımlardan ayrı bir liste olarak taşınır: misafirin üye kimliği yoktur,
/// mevcut katılım sözleşmesi ise `uye_id` anahtarlıdır. Ayrı dizi sayesinde
/// eski uygulama sürümleri kırılmadan çalışmaya devam eder.
///
/// [id] yalnız sunucuda kayıtlı misafirlerde doludur; antrenör yeni bir misafir
/// eklediğinde null gider ve backend kaydı açar.
class MisafirModel {
  final int? id;
  final String adSoyad;
  final String? notMetni;

  /// Yönetici parasal kararı verdiyse antrenör bu kaydı silemez/değiştiremez:
  /// arkasında borç ya da paket düşümü vardır.
  final bool kararVerildiMi;

  const MisafirModel({
    this.id,
    required this.adSoyad,
    this.notMetni,
    this.kararVerildiMi = false,
  });

  factory MisafirModel.fromMap(Map<String, dynamic> m) {
    return MisafirModel(
      id: m['id'] as int?,
      adSoyad: m['ad_soyad']?.toString() ?? '',
      notMetni: m['not_metni']?.toString(),
      kararVerildiMi: m['karar_verildi_mi'] == true,
    );
  }

  Map<String, dynamic> toRequestMap() {
    return {
      if (id != null) 'id': id,
      'ad_soyad': adSoyad,
      if (notMetni != null && notMetni!.isNotEmpty) 'not_metni': notMetni,
    };
  }

  MisafirModel copyWith({String? adSoyad, String? notMetni}) {
    return MisafirModel(
      id: id,
      adSoyad: adSoyad ?? this.adSoyad,
      notMetni: notMetni ?? this.notMetni,
      kararVerildiMi: kararVerildiMi,
    );
  }

  /// Kaydedilmemiş misafirleri listede ayırt etmek için geçici anahtar.
  String get anahtar => id?.toString() ?? 'yeni-$adSoyad-$notMetni';
}
