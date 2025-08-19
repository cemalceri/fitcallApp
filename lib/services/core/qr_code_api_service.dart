import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/models/1_common/event/gecis_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class QrEventApiService {
  static Future<ApiResult<EventModel?>> getirEventAktifApi(
      {required int userId}) {
    return ApiClient.postParsed<EventModel?>(
      getirEventAktif,
      {'user_id': userId},
      (json) => json == null
          ? null
          : EventModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<GecisModel?>> getirEventSelfPassApi(
      {required int userId}) {
    return ApiClient.postParsed<GecisModel?>(
      getirEventSelfPass,
      {'user_id': userId},
      (json) => json == null
          ? null
          : GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<List<GecisModel>>> listeleEventMisafirPassApi(
      {required int userId}) {
    return ApiClient.postParsed<List<GecisModel>>(
      listeleEventMisafirPass,
      {'user_id': userId},
      (json) {
        // Güçlü parse: list/dict(results)/dict(items)
        if (json is List) {
          return json
              .map((e) => GecisModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (json is Map<String, dynamic>) {
          final dynamic raw =
              json['results'] ?? json['items'] ?? json['data'] ?? [];
          if (raw is List) {
            return raw
                .map((e) => GecisModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        }
        return <GecisModel>[];
      },
    );
  }

  static Future<ApiResult<GecisModel>> olusturEventMisafirPassApi(
      {required int userId, required String label}) {
    return ApiClient.postParsed<GecisModel>(
      olusturEventMisafirPass,
      {'user_id': userId, 'label': label},
      (json) => GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<bool>> silEventMisafirPassApi(
      {required String code}) {
    return ApiClient.postParsed<bool>(
      silEventMisafirPass,
      {'code': code},
      (json) => (json is bool) ? json : false,
    );
  }
}
