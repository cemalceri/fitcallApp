// lib/models/1_common/degerlendirme_models.dart
//
// Bir antrenörün ders değerlendirmeleri (yalnız yönetici).
// Backend: api/etkinlik/degerlendirmeler.py — `degerlendirmeListesi`.

import 'package:fitcall/common/tarih_util.dart';

/// Puanı veren üye. Bir hesapta birden fazla üye profili olabilir: hesabın
/// derste iki üyesi varsa ad virgülle birleşik gelir ve [uyeId] boştur.
class DegerlendirenKisi {
  final int? uyeId;
  final String adSoyad;
  final String? profilFotografi;

  const DegerlendirenKisi({
    this.uyeId,
    required this.adSoyad,
    this.profilFotografi,
  });

  factory DegerlendirenKisi.fromJson(Map<String, dynamic> json) {
    return DegerlendirenKisi(
      uyeId: json['uye_id'],
      adSoyad: json['ad_soyad'] ?? '',
      profilFotografi: json['profil_fotografi'],
    );
  }
}

/// Dersteki bir katılımcı ve (verdiyse) kendi puanı.
class DegerlendirmeKatilimcisi {
  final int? uyeId;
  final String adSoyad;
  final String? profilFotografi;
  final int? puan;

  /// Yoklama: true geldi, false gelmedi, null girilmedi.
  final bool? katildi;
  final bool misafir;

  /// Satırdaki değerlendirmeyi bu katılımcı vermiş.
  final bool degerlendirenMi;

  const DegerlendirmeKatilimcisi({
    this.uyeId,
    required this.adSoyad,
    this.profilFotografi,
    this.puan,
    this.katildi,
    this.misafir = false,
    this.degerlendirenMi = false,
  });

  factory DegerlendirmeKatilimcisi.fromJson(Map<String, dynamic> json) {
    return DegerlendirmeKatilimcisi(
      uyeId: json['uye_id'],
      adSoyad: json['ad_soyad'] ?? '',
      profilFotografi: json['profil_fotografi'],
      puan: json['puan'],
      katildi: json['katildi'],
      misafir: json['misafir'] ?? false,
      degerlendirenMi: json['degerlendiren_mi'] ?? false,
    );
  }
}

/// Değerlendirilen dersin bilgisi.
class DegerlendirilenDers {
  final int id;
  final DateTime baslangic;
  final DateTime bitis;
  final String kortAdi;
  final String antrenorAdi;
  final String? yardimciAntrenorAdi;
  final String urunAdi;
  final String seviye;
  final bool iptalMi;
  final List<DegerlendirmeKatilimcisi> katilimcilar;

  const DegerlendirilenDers({
    required this.id,
    required this.baslangic,
    required this.bitis,
    required this.kortAdi,
    required this.antrenorAdi,
    this.yardimciAntrenorAdi,
    required this.urunAdi,
    required this.seviye,
    this.iptalMi = false,
    this.katilimcilar = const [],
  });

  /// Puanı verenin dışındaki katılımcılar.
  List<DegerlendirmeKatilimcisi> get digerKatilimcilar =>
      katilimcilar.where((k) => !k.degerlendirenMi).toList();

  factory DegerlendirilenDers.fromJson(Map<String, dynamic> json) {
    return DegerlendirilenDers(
      id: json['id'] ?? 0,
      baslangic: parseApiTarihOrNow(json['baslangic_tarih_saat']),
      bitis: parseApiTarihOrNow(json['bitis_tarih_saat']),
      kortAdi: json['kort_adi'] ?? '',
      antrenorAdi: json['antrenor_adi'] ?? '',
      yardimciAntrenorAdi: json['yardimci_antrenor_adi'],
      urunAdi: json['urun_adi'] ?? '',
      seviye: json['seviye'] ?? '',
      iptalMi: json['iptal_mi'] ?? false,
      katilimcilar: ((json['katilimcilar'] as List?) ?? const [])
          .map((e) => DegerlendirmeKatilimcisi.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Bir üyenin derse verdiği puan.
class DersDegerlendirmesi {
  final int id;

  /// 1-5.
  final int puan;

  /// Boş yorum null gelir.
  final String? yorum;
  final DateTime? tarih;
  final DegerlendirenKisi degerlendiren;
  final DegerlendirilenDers ders;

  const DersDegerlendirmesi({
    required this.id,
    required this.puan,
    this.yorum,
    this.tarih,
    required this.degerlendiren,
    required this.ders,
  });

  factory DersDegerlendirmesi.fromJson(Map<String, dynamic> json) {
    return DersDegerlendirmesi(
      id: json['id'] ?? 0,
      puan: json['puan'] ?? 0,
      yorum: json['yorum'],
      tarih: parseApiTarih(json['tarih']),
      degerlendiren: DegerlendirenKisi.fromJson(
          ((json['degerlendiren'] as Map?) ?? const {}).cast<String, dynamic>()),
      ders: DegerlendirilenDers.fromJson(
          ((json['ders'] as Map?) ?? const {}).cast<String, dynamic>()),
    );
  }
}

/// Listenin üstündeki özet: süzgeçten bağımsız ortalama ve adet.
class DegerlendirmeOzeti {
  final double? ortalama;
  final int adet;

  const DegerlendirmeOzeti({this.ortalama, required this.adet});

  factory DegerlendirmeOzeti.fromJson(Map<String, dynamic> json) {
    final o = json['ortalama'];
    return DegerlendirmeOzeti(
      ortalama: o == null ? null : double.tryParse(o.toString()),
      adet: json['adet'] ?? 0,
    );
  }
}

/// Tek sayfa. [ozet] yalnız ilk sayfada gelir.
class DegerlendirmeSayfasi {
  final List<DersDegerlendirmesi> degerlendirmeler;
  final int toplam;
  final int toplamSayfa;
  final DegerlendirmeOzeti? ozet;

  const DegerlendirmeSayfasi({
    required this.degerlendirmeler,
    required this.toplam,
    required this.toplamSayfa,
    this.ozet,
  });

  factory DegerlendirmeSayfasi.fromJson(Map<String, dynamic> json) {
    return DegerlendirmeSayfasi(
      degerlendirmeler: ((json['degerlendirmeler'] as List?) ?? const [])
          .map((e) =>
              DersDegerlendirmesi.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      toplam: json['toplam'] ?? 0,
      toplamSayfa: json['toplam_sayfa'] ?? 1,
      ozet: json['ozet'] is Map
          ? DegerlendirmeOzeti.fromJson(
              (json['ozet'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}
