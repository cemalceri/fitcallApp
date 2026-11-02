// lib/services/uye/uye_talep_service.dart
//
// Üye ders / kort kiralama talebi ve antrenörün "Ofis soruyor" cevabı.
// Backend: api/uye_talep/metots.py; kurallar
// calendarapp/services/uye_talep_service.py (burada tekrar edilmez).

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/services/api_client.dart';

Map<String, dynamic> _harita(dynamic json) =>
    (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

List<Map<String, dynamic>> _liste(dynamic json) => (json as List? ?? const [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

class UyeTalepService {
  UyeTalepService._();

  /// 1. adım: dört seçenek ve kurallar. [uyeId] veli çocuğu için açarken.
  static Future<TalepBaslangic> baslangic({int? uyeId}) async {
    final sonuc = await ApiClient.postParsed<TalepBaslangic>(
      uyeTalepBaslangicUrl,
      {'uye_id': uyeId},
      (json) => TalepBaslangic.fromJson(_harita(json)),
    );
    return sonuc.data!;
  }

  /// 2. adım: haftalık uygunluk haritası.
  static Future<TalepHarita> harita({
    required int uyeId,
    required String tur,
    required int sureDk,
    int? antrenorId,
    DateTime? hafta,
  }) async {
    final sonuc = await ApiClient.postParsed<TalepHarita>(
      uyeTalepHaritaUrl,
      {
        'uye_id': uyeId,
        'tur': tur,
        'sure_dk': sureDk,
        'antrenor_id': antrenorId,
        if (hafta != null) 'hafta': formatApiGun(hafta),
      },
      (json) => TalepHarita.fromJson(_harita(json)),
    );
    return sonuc.data!;
  }

  /// 3. adım: seçilen saatte boş hoca/kort ve tahmini düşüm/ücret.
  static Future<TalepSecenekleri> secenekler({
    required int uyeId,
    required String tur,
    required DateTime baslangic,
    required int sureDk,
    int? degistirilenTalepId,
  }) async {
    final sonuc = await ApiClient.postParsed<TalepSecenekleri>(
      uyeTalepSecenekleriUrl,
      {
        'uye_id': uyeId,
        'tur': tur,
        'baslangic_tarih_saat': formatApiTarih(baslangic),
        'sure_dk': sureDk,
        if (degistirilenTalepId != null)
          'degistirilen_talep_id': degistirilenTalepId,
      },
      (json) => TalepSecenekleri.fromJson(_harita(json)),
    );
    return sonuc.data!;
  }

  /// Talebi gönderir; sunucu mesajını döner.
  static Future<String> olustur(TalepTaslagi taslak) async {
    final sonuc = await ApiClient.postParsed<void>(
      uyeTalepOlusturUrl,
      taslak.govde(),
      (_) {},
    );
    return sonuc.mesaj;
  }

  static Future<List<UyeTalep>> taleplerim() async {
    final sonuc = await ApiClient.postParsed<List<UyeTalep>>(
      uyeTaleplerimUrl,
      const {},
      (json) => _liste(json).map(UyeTalep.fromJson).toList(),
    );
    return sonuc.data ?? const [];
  }

  static Future<String> oneriyeCevap(int talepId, {required bool kabul}) async {
    final sonuc = await ApiClient.postParsed<void>(
      uyeTalepOneriCevapUrl,
      {'talep_id': talepId, 'kabul': kabul},
      (_) {},
    );
    return sonuc.mesaj;
  }

  static Future<String> geriCek(int talepId) async {
    final sonuc = await ApiClient.postParsed<void>(
      dersKayitTalebiGeriCekUrl,
      {'talep_id': talepId},
      (_) {},
    );
    return sonuc.mesaj;
  }

  /* ------------------------------- antrenör ------------------------------- */

  static Future<List<HocaTalepSorusu>> hocaSorulari() async {
    final sonuc = await ApiClient.postParsed<List<HocaTalepSorusu>>(
      antrenorTalepSorulariUrl,
      const {},
      (json) => _liste(json).map(HocaTalepSorusu.fromJson).toList(),
    );
    return sonuc.data ?? const [];
  }

  static Future<String> hocaCevapla(int talepId,
      {required bool evet, String not = ''}) async {
    final sonuc = await ApiClient.postParsed<void>(
      antrenorTalepCevapUrl,
      {'talep_id': talepId, 'evet': evet, 'not': not},
      (_) {},
    );
    return sonuc.mesaj;
  }
}
