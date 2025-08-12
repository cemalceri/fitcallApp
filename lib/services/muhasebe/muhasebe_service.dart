import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class MuhasebeService {
  static Future<ApiResult<List<MuhasebeOzetModel>>> fetch() {
    return ApiClient.postParsed<List<MuhasebeOzetModel>>(
      getMuhasebeOzet,
      const {}, // parametre yok
      (json) => MuhasebeOzetModel.listFromJson(json),
    );
  }
}
