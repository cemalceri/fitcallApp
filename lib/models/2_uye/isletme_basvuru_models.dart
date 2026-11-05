// lib/models/2_uye/isletme_basvuru_models.dart
//
// Başka işletmeye üyelik başvurusu (Ayarlar > "Başka işletmeye üyelik").
// Backend: api/uye/isletme_basvuru.py; kurallar
// calendarapp/services/isletme_basvuru_service.py.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';

/// Sunucudaki durum adları.
class BasvuruDurumu {
  BasvuruDurumu._();
  static const uye = 'uye';
  static const bekliyor = 'bekliyor';
  static const reddedildi = 'reddedildi';
}

List<Map<String, dynamic>> _liste(dynamic json) => (json as List? ?? const [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

class IsletmeSecenegi {
  final int id;
  final String adi;

  /// null: başvurulabilir; 'bekliyor' | 'reddedildi' | 'uye'.
  final String? durum;

  const IsletmeSecenegi({required this.id, required this.adi, this.durum});

  factory IsletmeSecenegi.fromJson(Map<String, dynamic> j) => IsletmeSecenegi(
        id: (j['id'] as num).toInt(),
        adi: (j['adi'] ?? '').toString(),
        durum: j['durum']?.toString(),
      );

  bool get uyeMi => durum == BasvuruDurumu.uye;
  bool get bekliyor => durum == BasvuruDurumu.bekliyor;

  /// Hiç kaydı yoksa ya da reddedildiyse yeniden başvurulabilir.
  bool get secilebilir => durum == null || durum == BasvuruDurumu.reddedildi;
}

class IsletmeBasvurusu {
  final int id;
  final int? isletmeId;
  final String isletmeAdi;
  final String durum;
  final DateTime? tarih;

  /// Onaylananda bağlanan profilin kimliği (SistemKullaniciModel.id).
  final int? profilId;

  const IsletmeBasvurusu({
    required this.id,
    required this.isletmeAdi,
    required this.durum,
    this.isletmeId,
    this.tarih,
    this.profilId,
  });

  factory IsletmeBasvurusu.fromJson(Map<String, dynamic> j) => IsletmeBasvurusu(
        id: (j['id'] as num).toInt(),
        isletmeId: (j['isletme_id'] as num?)?.toInt(),
        isletmeAdi: (j['isletme_adi'] ?? '').toString(),
        durum: (j['durum'] ?? BasvuruDurumu.bekliyor).toString(),
        tarih: parseApiTarih(j['tarih']),
        profilId: (j['profil_id'] as num?)?.toInt(),
      );

  bool get onaylandi => durum == BasvuruDurumu.uye;
  bool get bekliyor => durum == BasvuruDurumu.bekliyor;
  bool get reddedildi => durum == BasvuruDurumu.reddedildi;
}

class AktarilanBilgiler {
  final String adSoyad;
  final String telefon;
  final String email;

  const AktarilanBilgiler({
    this.adSoyad = '',
    this.telefon = '',
    this.email = '',
  });

  factory AktarilanBilgiler.fromJson(Map<String, dynamic> j) =>
      AktarilanBilgiler(
        adSoyad: (j['ad_soyad'] ?? '').toString(),
        telefon: (j['telefon'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
      );
}

class IsletmeBasvuruVerisi {
  final List<IsletmeSecenegi> isletmeler;
  final List<IsletmeBasvurusu> basvurular;
  final AktarilanBilgiler bilgiler;

  /// Hesabın güncel profilleri ("Profil değiştir" önbelleği bununla tazelenir).
  final List<KullaniciProfilModel> profiller;

  const IsletmeBasvuruVerisi({
    this.isletmeler = const [],
    this.basvurular = const [],
    this.bilgiler = const AktarilanBilgiler(),
    this.profiller = const [],
  });

  factory IsletmeBasvuruVerisi.fromJson(Map<String, dynamic> j) =>
      IsletmeBasvuruVerisi(
        isletmeler: _liste(j['isletmeler']).map(IsletmeSecenegi.fromJson).toList(),
        basvurular:
            _liste(j['basvurular']).map(IsletmeBasvurusu.fromJson).toList(),
        bilgiler: AktarilanBilgiler.fromJson(
            (j['bilgiler'] as Map?)?.cast<String, dynamic>() ?? const {}),
        profiller:
            _liste(j['profiller']).map(KullaniciProfilModel.fromJson).toList(),
      );

  /// Formda gösterilen işletmeler: üye olunanlar listede yok.
  List<IsletmeSecenegi> get gosterilecekIsletmeler =>
      isletmeler.where((i) => !i.uyeMi).toList();

  List<IsletmeSecenegi> get secilebilirIsletmeler =>
      isletmeler.where((i) => i.secilebilir).toList();
}
