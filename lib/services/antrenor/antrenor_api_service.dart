// lib/services/antrenor/antrenor_ogrenciler_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class AntrenorApiService {
  static Future<ApiResult<List<UyeModel>>> getirOgrencilerim() {
    return ApiClient.postParsed<List<UyeModel>>(
      getAntrenorOgrenciler,
      const {},
      (json) => ApiParsing.parseList<UyeModel>(
        json,
        (m) => UyeModel.fromJson(m),
      ),
    );
  }
}
