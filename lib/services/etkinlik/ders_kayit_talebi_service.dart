// lib/services/etkinlik/ders_kayit_talebi_service.dart
//
// Ders kayıt talebi + antrenörün salt-okunur tüm programı.
// Backend: api/ders_kayit_talebi/metots.py, kurallar
// calendarapp/services/ders_kayit_talebi_service.py.
//
// Talepten ders KAYDI burada değil: ofis haftalık programın formunu açar ve
// kayıt YoneticiEtkinlikService.kaydet ile `talepId` taşıyarak gider; backend
// dersi aynı servisle kaydedip talebi aynı işlemde kapatır.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DersKayitTalebiService {
  static Map<String, dynamic> _harita(dynamic json) =>
      (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  /* ------------------------------- antrenör ------------------------------- */

  /// Tüm antrenörlerin haftalık programı (ders alanları sunucuda süzülmüş)
  /// ve antrenörün kendi bekleyen talepleri.
  static Future<ApiResult<HaftalikProgram>> antrenorHaftalikProgram({
    required DateTime tarih,
  }) {
    return ApiClient.postParsed<HaftalikProgram>(
      antrenorHaftalikProgramUrl,
      {'tarih': formatApiGun(tarih)},
      (json) => HaftalikProgram.fromJson(_harita(json)),
    );
  }

  /// Talep açar. Sunucu mesajını döndürür.
  static Future<String> olustur({
    required int kortId,
    required DateTime baslangic,
    required DateTime bitis,
    required String aciklama,
  }) async {
    final sonuc = await ApiClient.postParsed<DersKayitTalebi>(
      dersKayitTalebiOlusturUrl,
      {
        'kort_id': kortId,
        'baslangic_tarih_saat': formatApiTarih(baslangic),
        'bitis_tarih_saat': formatApiTarih(bitis),
        'aciklama': aciklama,
      },
      (json) => DersKayitTalebi.fromJson(_harita(json)),
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

  /* --------------------------------- ofis --------------------------------- */

  /// Karar bekleyen talepler, en eski üstte.
  static Future<List<DersKayitTalebi>> bekleyenler() async {
    final sonuc = await ApiClient.postParsed<List<DersKayitTalebi>>(
      ofisDersKayitTalepleriUrl,
      const {},
      (json) => (json as List? ?? const [])
          .map((e) => DersKayitTalebi.fromJson(_harita(e)))
          .toList(),
    );
    return sonuc.data ?? const [];
  }

  /// Gerekçeyle reddeder (gerekçe zorunlu; sunucu da kontrol eder).
  static Future<String> reddet(int talepId, String redNedeni) async {
    final sonuc = await ApiClient.postParsed<void>(
      ofisDersKayitTalebiReddetUrl,
      {'talep_id': talepId, 'red_nedeni': redNedeni},
      (_) {},
    );
    return sonuc.mesaj;
  }
}
