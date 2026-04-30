// lib/models/2_uye/basit_uye_model.dart

class BasitUyeModel {
  final int id;
  final String adSoyad;
  final int uyeNo;
  final String telefon;

  const BasitUyeModel({
    required this.id,
    required this.adSoyad,
    required this.uyeNo,
    required this.telefon,
  });

  factory BasitUyeModel.fromMap(Map<String, dynamic> m) {
    return BasitUyeModel(
      id: m['id'] as int,
      adSoyad: m['ad_soyad']?.toString() ?? '',
      uyeNo: m['uye_no'] as int? ?? 0,
      telefon: m['telefon']?.toString() ?? '',
    );
  }

  /// Arama için: "ahmet yılmaz", "555", "5551234567" hepsi eşleşsin
  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().replaceAll(' ', '');
    final hedef = ('$adSoyad$telefon$uyeNo').toLowerCase().replaceAll(' ', '');
    return hedef.contains(q);
  }
}
