// Dosya: lib/services/api/uye_api_serivce.dart
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/telafi_ders/telafi_response_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class UyeApiService {
  /// Şifre Değiştir
  /// Body: { "eskiSifre": "...", "yeniSifre": "..." }
  static Future<ApiResult<Map<String, dynamic>>> kullaniciSifreDegistir({
    required String eskiSifre,
    required String yeniSifre,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      uyeSifreDegistir,
      {
        "eskiSifre": eskiSifre,
        "yeniSifre": yeniSifre,
      },
      (json) => (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  /// Hesabı Kalıcı Sil
  /// Body: {} – backend kullanıcıyı access token'dan alır
  static Future<ApiResult<Map<String, dynamic>>> kullaniciSil() {
    return ApiClient.postParsed<Map<String, dynamic>>(
      uyeKullaniciSil,
      const {},
      (json) => (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  static Future<ApiResult<TelafiResponseModel>> getTelafiDersBilgileri() {
    return ApiClient.postParsed<TelafiResponseModel>(
      getTelafiDersBilgileriUrl,
      const {},
      (json) => TelafiResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
