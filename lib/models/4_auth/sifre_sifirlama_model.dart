// lib/models/4_auth/sifre_sifirlama_model.dart
//
// "Şifremi unuttum" ucunun cevabı (sifremiUnuttum / sifreSifirlamaGonder).
//
// Tek bir cep numarası birden çok hesaba bağlanabildiği için akış iki adımlı
// olabiliyor: uç `secim_gerekli` derse kullanıcıya maskeli hesap listesi
// gösterilir, seçilen hesapla ikinci istek atılır.

/// Seçim ekranındaki bir hesap — kimlik doğrulaması öncesi görüldüğü için
/// ad ve e-posta maskeli gelir.
class SifirlamaHesabi {
  final int userId;
  final String maskeliAd;
  final String maskeliEposta;
  final bool epostaVarMi;

  const SifirlamaHesabi({
    required this.userId,
    required this.maskeliAd,
    required this.maskeliEposta,
    required this.epostaVarMi,
  });

  factory SifirlamaHesabi.fromJson(Map<String, dynamic> j) => SifirlamaHesabi(
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        maskeliAd: (j['maskeli_ad'] ?? '').toString().trim(),
        maskeliEposta: (j['maskeli_eposta'] ?? '').toString(),
        epostaVarMi: j['eposta_var_mi'] == true,
      );
}

enum SifirlamaDurumu {
  /// Bağlantı e-postaya gönderildi.
  gonderildi,

  /// Numara birden çok hesaba bağlı; kullanıcı seçmeli.
  secimGerekli,

  /// Hesap bulundu ama kayıtlı e-posta adresi yok.
  epostasiz,
}

class SifreSifirlamaSonucu {
  final SifirlamaDurumu durum;

  /// `gonderildi` durumunda linkin gittiği maskeli adres.
  final String? maskeliEposta;

  /// `secimGerekli` durumundaki hesaplar.
  final List<SifirlamaHesabi> hesaplar;

  const SifreSifirlamaSonucu({
    required this.durum,
    this.maskeliEposta,
    this.hesaplar = const [],
  });

  factory SifreSifirlamaSonucu.fromJson(Map<String, dynamic> j) {
    final durum = switch ((j['durum'] ?? '').toString()) {
      'secim_gerekli' => SifirlamaDurumu.secimGerekli,
      'epostasiz' => SifirlamaDurumu.epostasiz,
      _ => SifirlamaDurumu.gonderildi,
    };

    return SifreSifirlamaSonucu(
      durum: durum,
      maskeliEposta: j['maskeli_eposta']?.toString(),
      hesaplar: (j['kullanicilar'] as List? ?? const [])
          .map((e) => SifirlamaHesabi.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
