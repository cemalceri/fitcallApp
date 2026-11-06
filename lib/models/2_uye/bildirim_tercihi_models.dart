// lib/models/2_uye/bildirim_tercihi_models.dart
//
// Üye bildirim tercihleri. Backend: api/uye/bildirim_tercihi.py; gruplar ve
// metinleri sunucuda (calendarapp/models/concrete/notification.py
// UYE_BILDIRIM_GRUPLARI), yeni grup mobil sürüm gerektirmez.

/// Telefona push olarak gelip gelmeyeceği seçilen bildirim grubu.
class BildirimTercihGrubu {
  final String kod;
  final String baslik;
  final String aciklama;

  /// false: grup kapalı, push gelmez (Bildirimlerim'de yine görünür).
  final bool acik;

  /// Doluysa kapatmadan önce gösterilen uyarı (ör. ders teyidi).
  final String? kapatmaUyarisi;

  const BildirimTercihGrubu({
    required this.kod,
    required this.baslik,
    this.aciklama = '',
    this.acik = true,
    this.kapatmaUyarisi,
  });

  BildirimTercihGrubu acikIle(bool deger) => BildirimTercihGrubu(
        kod: kod,
        baslik: baslik,
        aciklama: aciklama,
        acik: deger,
        kapatmaUyarisi: kapatmaUyarisi,
      );

  factory BildirimTercihGrubu.fromJson(Map<String, dynamic> j) {
    final uyari = (j['kapatma_uyarisi'] as String?)?.trim();
    return BildirimTercihGrubu(
      kod: j['kod']?.toString() ?? '',
      baslik: j['baslik']?.toString() ?? '',
      aciklama: j['aciklama']?.toString() ?? '',
      acik: j['acik'] != false,
      kapatmaUyarisi: (uyari == null || uyari.isEmpty) ? null : uyari,
    );
  }
}

class BildirimTercihleri {
  final List<BildirimTercihGrubu> gruplar;

  /// Hesaptaki üye profili sayısı; 1'den büyükse ayarın hepsine geçtiği yazılır.
  final int uyeProfilSayisi;

  const BildirimTercihleri({
    this.gruplar = const [],
    this.uyeProfilSayisi = 1,
  });

  /// Tek grubu değiştirilmiş kopya (iyimser güncelleme).
  BildirimTercihleri ileGuncelle(String kod, bool acik) => BildirimTercihleri(
        gruplar: [
          for (final g in gruplar) g.kod == kod ? g.acikIle(acik) : g,
        ],
        uyeProfilSayisi: uyeProfilSayisi,
      );

  factory BildirimTercihleri.fromJson(Map<String, dynamic> j) =>
      BildirimTercihleri(
        gruplar: ((j['gruplar'] as List?) ?? const [])
            .map((e) => BildirimTercihGrubu.fromJson(
                (e as Map).cast<String, dynamic>()))
            .where((g) => g.kod.isNotEmpty)
            .toList(),
        uyeProfilSayisi: (j['uye_profil_sayisi'] as num?)?.toInt() ?? 1,
      );
}
