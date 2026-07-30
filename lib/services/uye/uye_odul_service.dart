// lib/services/uye/uye_odul_service.dart
//
// Turnike geçişlerine dayalı sadakat sayacı uçları.
// İş kuralları backend'de (calendarapp/services/odul_service.py); burada yok.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/uye_odul_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class UyeOdulService {
  /// Sayaç + bekleyen ödül kodu.
  static Future<ApiResult<OdulDurumModel>> getOdulDurumu() {
    return ApiClient.postParsed<OdulDurumModel>(
      getUyeOdulDurumuUrl,
      const {},
      (json) => OdulDurumModel.fromJson(
        (json as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  /// "Ödülü al" — kodu üretir ve güncel durumu döner.
  static Future<ApiResult<OdulDurumModel>> odulTalepEt() {
    return ApiClient.postParsed<OdulDurumModel>(
      odulTalepEtUrl,
      const {},
      (json) => OdulDurumModel.fromJson(
        (json as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
