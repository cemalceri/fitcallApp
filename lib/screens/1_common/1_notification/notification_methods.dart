import 'dart:convert';

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<List<NotificationModel>> fetchNotifications(BuildContext context) async {
  try {
    String? token = await getPrefs("token");
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: Bildirimler alınamadı')),
      );
      return [];
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata: Bildirimler alınamadı')),
    );
    return [];
  }
}
