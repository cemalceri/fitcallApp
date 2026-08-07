// lib/services/antrenor/antrenor_hakedis_service.dart
//
// Antrenörün KENDİ hakediş saatleri uçları.
// Backend: api/yonetici/hakedis_metots.py (AntrenorHakedis*ApiView)
//
// Bu uçlar antrenör id'si KABUL ETMEZ — kimlik backend'de token'dan
// (`request.antrenor`) çözülür, böylece antrenör başkasının hakedişini
// isteyemez. Yanıt gövdesi yönetici uçlarıyla birebir aynı, o yüzden aynı
// modeller (models/1_common/hakedis_models.dart) kullanılıyor.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class AntrenorHakedisService {
  /// Kendi son 12 ayı — ay × rol × durum kırılımı, tamamı tek istekte.
  static Future<ApiResult<HakedisOzet>> ozet() {
    return ApiClient.postParsed<HakedisOzet>(
      antrenorHakedisOzetUrl,
      const {},
      (json) => ApiParsing.parseObject(json, HakedisOzet.fromJson),
      auth: true,
    );
  }

  /// Kendi bir grubunun (ay + rol + durum) ders listesi.
  static Future<ApiResult<HakedisDersListesi>> dersler({
    required int yil,
    required int ay,
    required String rol,
    required String durum,
  }) {
    return ApiClient.postParsed<HakedisDersListesi>(
      antrenorHakedisDerslerUrl,
      {'yil': yil, 'ay': ay, 'rol': rol, 'durum': durum},
      (json) => ApiParsing.parseObject(json, HakedisDersListesi.fromJson),
      auth: true,
    );
  }
}
