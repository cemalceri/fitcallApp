import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_exception.dart';

class NotificationActionService {
  /// Token ile bildirim detayını getirir (login gerektirmez)
  static Future<Map<String, dynamic>> getNotificationByToken(
      String token) async {
    final result = await ApiClient.getParsed<Map<String, dynamic>>(
      '$notificationAction$token/',
      (json) => Map<String, dynamic>.from(json as Map),
      auth: false,
    );
    if (result.data == null) {
      throw ApiException('NOT_FOUND', 'Bildirim bulunamadı');
    }
    return result.data!;
  }

  static Future<Map<String, dynamic>> executeAction(String token, String action,
      {String aciklama = ''}) async {
    final body = <String, dynamic>{'action': action};
    if (aciklama.isNotEmpty) {
      body['aciklama'] = aciklama;
    }

    final result = await ApiClient.postParsed<Map<String, dynamic>>(
      '$notificationAction$token/',
      body,
      (json) => Map<String, dynamic>.from(json as Map),
      auth: false,
    );
    if (result.data == null) {
      throw ApiException('ACTION_FAILED', result.mesaj);
    }
    return result.data!;
  }

  static Future<void> markAsRead(String token) async {
    await executeAction(token, 'read');
  }
}
