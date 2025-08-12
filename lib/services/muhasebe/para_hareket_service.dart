import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class ParaHareketService {
  static Future<ApiResult<List<ParaHareketModel>>> fetchForPeriod(
      int yil, int ay) {
    return ApiClient.postParsed<List<ParaHareketModel>>(
      getParaHareketi,
      {'yil': yil, 'ay': ay},
      (json) => ApiParsing.parseList<ParaHareketModel>(
        json,
        (m) => ParaHareketModel.fromJson(m),
      ),
    );
  }
}
