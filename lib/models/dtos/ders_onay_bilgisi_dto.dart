/* ------------------------------ DTO: Onay --------------------------------- */
class DersOnayBilgisi {
  final bool? tamamlandi;
  final String? nedenKodu; // onay_red_iptal_nedeni
  final String? aciklama;
  final DateTime? onayTarihi;
  final String? rol;
  DersOnayBilgisi(
      {this.tamamlandi,
      this.nedenKodu,
      this.aciklama,
      this.onayTarihi,
      this.rol});
  factory DersOnayBilgisi.fromMap(Map<String, dynamic> m) {
    DateTime? dt;
    final raw = m['onay_tarihi'];
    if (raw is String && raw.isNotEmpty) {
      dt = DateTime.tryParse(raw)?.toLocal();
    }
    return DersOnayBilgisi(
      tamamlandi: m['tamamlandi'] as bool?,
      nedenKodu: (m['onay_red_iptal_nedeni'] ?? m['reason_code']) as String?,
      aciklama: m['aciklama'] as String?,
      onayTarihi: dt,
      rol: m['rol'] as String?,
    );
  }
}
