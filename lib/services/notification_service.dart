import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  /// Tüm app’te dinlenebilen canlı okunmamış sayaç
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Future<void> refreshUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      final resp = await http.post(
        Uri.parse(getUnreadNotificationCount), // ← yeni uç nokta
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body); // {"unread": 5}
        unreadCount.value = data['unread'] as int;
      }
    } catch (_) {
      // sessizce yoksay
    }
  }

  static Future<List<NotificationModel>> fetchNotifications(
      BuildContext context) async {
    try {
      String? token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(
            getNotifications), // API URL'nizde bildirimler için tanımlı olmalı
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return List<NotificationModel>.from(
            decoded.map((e) => NotificationModel.fromJson(e)));
      } else {
        // ignore: use_build_context_synchronously
        ShowMessage.error(context, 'Bildirimler alınamadı.');
        return [];
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ShowMessage.error(context, 'Bildirimler alınamadı.');
      return [];
    }
  }

  static Future<bool> markNotificationsRead(
      BuildContext context, List<int> ids) async {
    if (ids.isEmpty) return true;

    try {
      String? token = await AuthService.getToken();
      final resp = await http
          .post(
            Uri.parse(setNotificationsRead),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'ids': ids}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) return true;
    } catch (_) {/* fallthrough */}

    // ignore: use_build_context_synchronously
    ShowMessage.error(context, 'Bildirim durumu güncellenemedi.');
    return false;
  }
}
