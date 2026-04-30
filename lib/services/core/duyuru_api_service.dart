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

  /// Duyuruyu okundu olarak işaretle (fire-and-forget kullanımı uygun)
  static Future<ApiResult<Map<String, dynamic>>> setDuyuruOkundu({
    required int duyuruId,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDuyuruOkunduUrl,
      {'duyuru_id': duyuruId},
      (json) => (json as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
