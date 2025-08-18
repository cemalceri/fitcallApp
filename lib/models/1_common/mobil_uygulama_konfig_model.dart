// lib/models/ayarlar/mobil_uygulama_konfig_model.dart

class MobilUygulamaKonfigModel {
  // Model alanlari (DJANGO ILE BIREBIR)
  final int id;
  final String platform;
  final String minDestekli;
  final String onerilen;
  final String enSon;
  final String? magazaUrl;
  final String? playPaket;
  final String? mesajBaslik;
  final String? mesaj;
  final bool bakimAktif;
  final DateTime? bakimBitis;
  final List<int> engelliBuildler;
  final int rolloutYuzde;
  final List<String> rolloutUlkeler;
  final String androidGuncellemeTipi;
  final String iosAksiyon;
  final Map<String, dynamic> bayraklar;
  final bool aktifMi;

  // BaseAbstract
  final bool isActive;
  final bool isDeleted;
  final DateTime olusturulmaZamani;
  final DateTime guncellenmeZamani;

  // SerializerMethodField
  final String? direktif;

  MobilUygulamaKonfigModel({
    required this.id,
    required this.platform,
    required this.minDestekli,
    required this.onerilen,
    required this.enSon,
    required this.magazaUrl,
    required this.playPaket,
    required this.mesajBaslik,
    required this.mesaj,
    required this.bakimAktif,
    required this.bakimBitis,
    required this.engelliBuildler,
    required this.rolloutYuzde,
    required this.rolloutUlkeler,
    required this.androidGuncellemeTipi,
    required this.iosAksiyon,
    required this.bayraklar,
    required this.aktifMi,
    required this.isActive,
    required this.isDeleted,
    required this.olusturulmaZamani,
    required this.guncellenmeZamani,
    required this.direktif,
  });

  factory MobilUygulamaKonfigModel.fromMap(Map<String, dynamic> j) {
    DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
        ? null
        : DateTime.parse(v.toString());

    return MobilUygulamaKonfigModel(
      id: j['id'] as int,
      platform: j['platform'] ?? '',
      minDestekli: j['min_destekli'] ?? '0.0.0',
      onerilen: j['onerilen'] ?? '0.0.0',
      enSon: j['en_son'] ?? '0.0.0',
      magazaUrl: j['magaza_url'],
      playPaket: j['play_paket'],
      mesajBaslik: j['mesaj_baslik'],
      mesaj: j['mesaj'],
      bakimAktif: j['bakim_aktif'] ?? false,
      bakimBitis: dt(j['bakim_bitis']),
      engelliBuildler: (j['engelli_buildler'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[],
      rolloutYuzde: (j['rollout_yuzde'] as num?)?.toInt() ?? 100,
      rolloutUlkeler:
          (j['rollout_ulkeler'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[],
      androidGuncellemeTipi: j['android_guncelleme_tipi'] ?? 'none',
      iosAksiyon: j['ios_aksiyon'] ?? 'none',
      bayraklar: (j['bayraklar'] ?? {}) as Map<String, dynamic>,
      aktifMi: j['aktif_mi'] ?? true,
      isActive: j['is_active'] ?? true,
      isDeleted: j['is_deleted'] ?? false,
      olusturulmaZamani: DateTime.parse(j['olusturulma_zamani']),
      guncellenmeZamani: DateTime.parse(j['guncellenme_zamani']),
      direktif: j['direktif'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'min_destekli': minDestekli,
        'onerilen': onerilen,
        'en_son': enSon,
        'magaza_url': magazaUrl,
        'play_paket': playPaket,
        'mesaj_baslik': mesajBaslik,
        'mesaj': mesaj,
        'bakim_aktif': bakimAktif,
        'bakim_bitis': bakimBitis?.toIso8601String(),
        'engelli_buildler': engelliBuildler,
        'rollout_yuzde': rolloutYuzde,
        'rollout_ulkeler': rolloutUlkeler,
        'android_guncelleme_tipi': androidGuncellemeTipi,
        'ios_aksiyon': iosAksiyon,
        'bayraklar': bayraklar,
        'aktif_mi': aktifMi,
        'is_active': isActive,
        'is_deleted': isDeleted,
        'olusturulma_zamani': olusturulmaZamani.toIso8601String(),
        'guncellenme_zamani': guncellenmeZamani.toIso8601String(),
        'direktif': direktif,
      };
}
