// lib/services/yonetici/yonetici_hakedis_service.dart
//
// Antrenör hakediş saatleri uçları.
// Backend: api/yonetici/hakedis_metots.py
//
// Hakediş kuralı (bayrak ders onayını ezer, yardımcı kendi satırından okunur)
// tamamen backend'de; burada yalnız taşıma var. Kural değişecekse
// api/yonetici/hakedis_servis.py düzenlenir.
//
// Özet uçları backend'de cache'li (5 dk) olduğundan ekranlar arası gidiş
// gelişte tekrar tekrar sorgu çalışmaz; pull-to-refresh yine de yeni istek
// atar, cache dolu olduğu sürece ucuzdur.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class YoneticiHakedisService {
  /// Antrenör seçim ekranı: her antrenörün son 12 aydaki hakediş toplamı.
  /// [filtre]: aktif | pasif | tumu
  static Future<ApiResult<HakedisAntrenorListesi>> antrenorler({
    String filtre = 'aktif',
  }) {
    return ApiClient.postParsed<HakedisAntrenorListesi>(
      yoneticiHakedisAntrenorlerUrl,
      {'filtre': filtre},
      (json) => ApiParsing.parseObject(json, HakedisAntrenorListesi.fromJson),
      auth: true,
    );
  }

  /// Ay panosu: bir antrenörün son 12 ayı, ay × rol × durum kırılımıyla.
  /// 12 ayın tamamı tek istekte gelir; ay değiştirmek yeni istek gerektirmez.
  static Future<ApiResult<HakedisOzet>> ozet({required int antrenorId}) {
    return ApiClient.postParsed<HakedisOzet>(
      yoneticiHakedisOzetUrl,
      {'antrenor_id': antrenorId},
      (json) => ApiParsing.parseObject(json, HakedisOzet.fromJson),
      auth: true,
    );
  }

  /// Grup detayı: seçilen ay + rol + durumdaki dersler ve katılımcıları.
  /// [rol]: ana | yardimci — [durum]: hakedis | bekliyor | disi
  static Future<ApiResult<HakedisDersListesi>> dersler({
    required int antrenorId,
    required int yil,
    required int ay,
    required String rol,
    required String durum,
  }) {
    return ApiClient.postParsed<HakedisDersListesi>(
      yoneticiHakedisDerslerUrl,
      {
        'antrenor_id': antrenorId,
        'yil': yil,
        'ay': ay,
        'rol': rol,
        'durum': durum,
      },
      (json) => ApiParsing.parseObject(json, HakedisDersListesi.fromJson),
      auth: true,
    );
  }
}
