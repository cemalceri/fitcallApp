import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DersTalepApiService {
  /// Rezervasyon talebi gönderir
  static Future<ApiResult<Map<String, dynamic>>> gonderDersTalep({
    required int kortId,
    required int antrenorId,
    required DateTime baslangic,
    required DateTime bitis,
    String? aciklama,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersTalep,
      {
        'kort_id': kortId,
        'antrenor_id': antrenorId,
        'baslangic_tarih_saat': baslangic.toUtc().toIso8601String(),
        'bitis_tarih_saat': bitis.toUtc().toIso8601String(),
        'aciklama': aciklama ?? '',
      },
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Genel ders talebi gönderir
  static Future<ApiResult<Map<String, dynamic>>> gonderGenelDersTalep({
    required Map<String, List<String>> saatler,
    String? aciklama,
    int? kortId,
    int? antrenorId,
  }) {
    final payload = <String, dynamic>{
      'saatler': saatler,
      'aciklama': aciklama ?? '',
      if (kortId != null) 'kort_id': kortId,
      if (antrenorId != null) 'antrenor_id': antrenorId,
    };

    return ApiClient.postParsed<Map<String, dynamic>>(
      setGenelDersTalep,
      payload,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
