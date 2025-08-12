import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:flutter/material.dart';

class NotificationService {
  /// Tüm app’te dinlenebilen canlı okunmamış sayaç
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Sunucudan okunmamış bildirim sayısını çeker ve ValueNotifier'ı günceller.
  /// Hata durumunda ApiException yukarıya fırlar (sayfada yakalayın).
  static Future<ApiResult<int>> refreshUnreadCount() async {
    final res = await ApiClient.postParsed<int>(
      getUnreadNotificationCount,
      const {},
      (json) {
        if (json is Map) {
          final v = json['unread'];
          if (v is int) return v;
          if (v is num) return v.toInt();
        }
        if (json is int) return json;
        return 0;
      },
    );
    unreadCount.value = res.data ?? 0;
    return res;
  }

  /// Bildirim listesini getirir.
  static Future<ApiResult<List<NotificationModel>>> fetchNotifications(
      BuildContext context) {
    return ApiClient.postParsed<List<NotificationModel>>(
      getNotifications,
      const {},
      (json) => ApiParsing.parseList<NotificationModel>(
        json,
        (m) => NotificationModel.fromJson(m),
      ),
    );
  }

  /// Bildirimleri okundu olarak işaretler.
  static Future<ApiResult<bool>> markNotificationsRead(
      BuildContext context, List<int> ids) {
    if (ids.isEmpty) {
      // Boş listeyi başarılı kabul eden tutarlı bir ApiResult döndürüyoruz.
      return Future.value(ApiResult<bool>(mesaj: 'İşlem başarılı', data: true));
    }

    return ApiClient.postParsed<bool>(
      setNotificationsRead,
      {'ids': ids},
      (_) => true, // 2xx ise başarılı kabul
    );
  }
}
