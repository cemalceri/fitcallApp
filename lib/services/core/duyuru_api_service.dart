// lib/services/core/duyuru_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DuyuruService {
  /// Aktif duyuruları getir
  ///
  /// [hedefKitle] - Opsiyonel: 'uyeler', 'antrenorler', 'yoneticiler'
  /// Belirtilmezse 'herkes' ve kullanıcının rolüne uygun duyurular gelir
  static Future<ApiResult<List<DuyuruModel>>> getAktifDuyurular({
    String? hedefKitle,
  }) {
    return ApiClient.postParsed<List<DuyuruModel>>(
      getAktifDuyurularUrl,
      {
        if (hedefKitle != null) 'hedef_kitle': hedefKitle,
      },
      (json) => ApiParsing.parseList<DuyuruModel>(
        json,
        (m) => DuyuruModel.fromMap(m),
      ),
    );
  }

  /// Duyuru detayını getir
  static Future<ApiResult<DuyuruModel>> getDuyuruDetay({
    required int duyuruId,
  }) {
    return ApiClient.postParsed<DuyuruModel>(
      getDuyuruDetayUrl,
      {
        'duyuru_id': duyuruId,
      },
      (json) => DuyuruModel.fromMap(json),
    );
  }

  /// Açılış popup'ı: kullanıcının henüz görmediği ilk popup duyurusu.
  /// Yoksa `data` null. Rol (üye/antrenör) ve "görüldü" süzmesi sunucuda.
  static Future<ApiResult<DuyuruModel?>> getPopupDuyuru() {
    return ApiClient.postParsed<DuyuruModel?>(
      getPopupDuyuruUrl,
      const {},
      (json) => DuyuruModel.fromMap((json as Map).cast<String, dynamic>()),
    );
  }

  /// Duyuruyu okundu olarak işaretle (fire-and-forget kullanımı uygun)
  ///
  /// [kaynak] ('carousel' | 'popup') ve [detayAcildi] ölçüm içindir; ikisi de
  /// verilmezse sunucu "ana sayfadan açılan detay" sayar.
  static Future<ApiResult<Map<String, dynamic>>> setDuyuruOkundu({
    required int duyuruId,
    String? kaynak,
    bool? detayAcildi,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDuyuruOkunduUrl,
      {
        'duyuru_id': duyuruId,
        if (kaynak != null) 'kaynak': kaynak,
        if (detayAcildi != null) 'detay_acildi': detayAcildi,
      },
      (json) => (json as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
