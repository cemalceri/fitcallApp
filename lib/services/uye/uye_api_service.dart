// Dosya: lib/services/api/uye_api_serivce.dart
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/basit_uye_model.dart';
import 'package:fitcall/models/2_uye/telafi_ders/telafi_response_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class UyeApiService {
  static List<BasitUyeModel>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

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

  /// Aktif üyeleri cache'li olarak getirir.
  /// [forceRefresh] true ise cache'i yok sayar.
  static Future<ApiResult<List<BasitUyeModel>>> getAktifUyeler({
    bool forceRefresh = false,
  }) async {
    // Cache geçerli mi?
    if (!forceRefresh && _cache != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!);
      if (age < _cacheDuration) {
        return ApiResult<List<BasitUyeModel>>(
          mesaj: '',
          data: _cache,
        );
      }
    }

    final result = await ApiClient.postParsed<List<BasitUyeModel>>(
      getAktifUyeListesiUrl,
      const {},
      (json) {
        final list = (json as List);
        return list
            .map((e) =>
                BasitUyeModel.fromMap((e as Map).cast<String, dynamic>()))
            .toList();
      },
    );

    if (result.data != null) {
      _cache = result.data;
      _cacheTime = DateTime.now();
    }

    return result;
  }

  /// Cache'i manuel temizle (logout vs.)
  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
