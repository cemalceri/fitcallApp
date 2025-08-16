// services/etkinlik/etkinlik_service.dart
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class EtkinlikService {
  static Future<ApiResult<List<EtkinlikModel>>> getirHaftalikDersBilgilerim() {
    return ApiClient.postParsed<List<EtkinlikModel>>(
      getHaftalikDersBilgilerim,
      const {},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );
  }
}
