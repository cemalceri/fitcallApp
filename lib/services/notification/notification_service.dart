import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Future<ApiResult<int>> refreshUnreadCount() async {
    final res = await ApiClient.postParsed<int>(
        getUnreadNotificationCount, const {}, (json) {
      if (json is Map) {
        final v = json['unread'];
        if (v is int) return v;
        if (v is num) return v.toInt();
      }
      if (json is int) return json;
      return 0;
    });
    unreadCount.value = res.data ?? 0;
    return res;
  }

  static Future<ApiResult<List<NotificationModel>>> fetchNotifications() {
    return ApiClient.postParsed<List<NotificationModel>>(
      getNotifications,
      const {},
      (json) => ApiParsing.parseList<NotificationModel>(
          json, (m) => NotificationModel.fromJson(m)),
    );
  }

  static Future<ApiResult<bool>> markNotificationsRead(List<int> ids) {
    if (ids.isEmpty) {
      return Future.value(ApiResult<bool>(mesaj: 'İşlem başarılı', data: true));
    }
    return ApiClient.postParsed<bool>(
        setNotificationsRead, {'ids': ids}, (_) => true);
  }

  /// Profilin TÜM okunmamışlarını okundu yapar.
  ///
  /// Liste ucu son 50 kaydı döndüğü için id göndermek yetmiyor; 50'nin dışında
  /// kalan eski okunmamışlar zilde asılı kalıyordu. İşi sunucu tarafında,
  /// sayacın kullandığı kapsamın aynısıyla yapıyoruz.
  static Future<ApiResult<bool>> markAllNotificationsRead() {
    return ApiClient.postParsed<bool>(
        setNotificationsRead, {'tumu': true}, (_) => true);
  }

  /// Profilin tüm bildirimlerini siler (backend'de soft delete).
  static Future<ApiResult<bool>> deleteAllNotifications() {
    return ApiClient.postParsed<bool>(
        setNotificationsDeleted, {'tumu': true}, (_) => true);
  }
}
