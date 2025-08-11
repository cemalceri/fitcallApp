import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DersTeyitService {
  /// Bildirimi ID ile getirir (ApiResult<NotificationModel>)
  static Future<ApiResult<NotificationModel>> getBildirim(String bildirimId) {
    return ApiClient.postParsed<NotificationModel>(
      getBildirimById,
      {'bildirim_id': bildirimId},
      (json) => ApiParsing.parseObject<NotificationModel>(
        json,
        (m) => NotificationModel.fromJson(m),
      ),
    );
  }

  /// Teyit gönderir. Dönen veri serializer çıktısı olabilir (map).
  /// İstersen EtkinlikTeyitModel.fromJson(...) ile modele de çevirebilirsin.
  static Future<ApiResult<Map<String, dynamic>>> setDersTeyitBilgisi({
    required String uyeId,
    required String etkinlikId,
    required bool durum,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersTeyit,
      {'uye_id': uyeId, 'etkinlik_id': etkinlikId, 'durum': durum},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
