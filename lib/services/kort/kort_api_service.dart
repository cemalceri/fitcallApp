import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class KortApiService {
  /// Kort ve Antrenör listesi getirir
  static Future<ApiResult<Map<String, dynamic>>> getKortVeAntrenorList() {
    return ApiClient.postParsed<Map<String, dynamic>>(
      getKortveAntrenorList,
      const {},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
