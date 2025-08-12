import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class UyeUrunApiService {
  static Future<ApiResult<List<UyeUrunModel>>> fetchList() {
    return ApiClient.postParsed<List<UyeUrunModel>>(
      getUyeUrunList,
      const {},
      (json) => ApiParsing.parseList<UyeUrunModel>(
        json,
        (m) => UyeUrunModel.fromJson(m),
      ),
    );
  }
}
