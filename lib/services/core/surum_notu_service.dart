// lib/services/core/surum_notu_service.dart
//
// "Neler yeni?" sürüm notu uçları. Backend: api/common/surum_notu/metots.py.
//
// Boş durum 200 + `data: null` olarak gelir (4xx değil): `postParsed` null
// data'da parser'ı hiç çağırmıyor, dolayısıyla `data == null` "gösterilecek
// bir şey yok" demek — hata değil.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class SurumNotuService {
  /// Kurulu sürümün, aktif profile ait, henüz görülmemiş notu. Yoksa null.
  ///
  /// [surum] uygulamanın kendi sürümü (`PackageInfo.version`); sunucu bununla
  /// BİREBİR eşleşen bloğu döner.
  static Future<ApiResult<SurumNotuBlogu?>> getYenilikler({
    required String surum,
    String? build,
  }) {
    return ApiClient.postParsed<SurumNotuBlogu?>(
      getSurumYenilikleriUrl,
      {
        'surum': surum,
        if (build != null && build.isNotEmpty) 'build': build,
      },
      (json) => ApiParsing.parseObject(json, SurumNotuBlogu.fromJson),
    );
  }

  /// "Görüldü" + açılan maddeler. Idempotent; ateşle-ve-bırak kullanılabilir.
  static Future<ApiResult<Map<String, dynamic>>> gorunduIsaretle({
    required int rolBloguId,
    String kaynak = 'popup',
    List<int> acilanMaddeler = const [],
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setSurumYenilikGorunduUrl,
      {
        'rol_blogu_id': rolBloguId,
        'kaynak': kaynak,
        'acilan_maddeler': acilanMaddeler,
      },
      (json) => (json as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// Ayarlar > "Neler yeni": kurulu sürüme kadarki notlar (en yeni önce).
  static Future<ApiResult<List<SurumNotuBlogu>>> arsiv({
    required String surum,
  }) {
    return ApiClient.postParsed<List<SurumNotuBlogu>>(
      getSurumNotuArsiviUrl,
      {'surum': surum},
      (json) => ApiParsing.parseList<SurumNotuBlogu>(
        json,
        SurumNotuBlogu.fromJson,
      ),
    );
  }
}
