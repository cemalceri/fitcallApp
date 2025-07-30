// lib/models/notification_model.dart

import 'package:flutter/material.dart';

/// Django tarafındaki `NotificationType` enümlerinin Dart eşleniği.
enum NotificationType {
  doOnay, // Ders Onayı
  gecikenOdeme, // Geciken Ödeme
  paketBitiyor, // Paket Bitiyor
  paketSuresiDoluyor, // Paket Süresi Doluyor
  paketBitti, // Paket Bitti
  telafiKullanildi, // Telafi Kullanıldı
  telafiHakkiIadeEdildi, // Telafi Hakkı İade Edildi
  dersIptalEdildi, // Ders İptal Edildi
}

extension _NotificationTypeExt on NotificationType {
  String get code {
    switch (this) {
      case NotificationType.doOnay:
        return 'DO';
      case NotificationType.gecikenOdeme:
        return 'GO';
      case NotificationType.paketBitiyor:
        return 'PB';
      case NotificationType.paketSuresiDoluyor:
        return 'PS';
      case NotificationType.paketBitti:
        return 'PBT';
      case NotificationType.telafiKullanildi:
        return 'TK';
      case NotificationType.telafiHakkiIadeEdildi:
        return 'THI';
      case NotificationType.dersIptalEdildi:
        return 'DI';
    }
  }

  static NotificationType fromCode(String code) {
    switch (code) {
      case 'DO':
        return NotificationType.doOnay;
      case 'GO':
        return NotificationType.gecikenOdeme;
      case 'PB':
        return NotificationType.paketBitiyor;
      case 'PS':
        return NotificationType.paketSuresiDoluyor;
      case 'PBT':
        return NotificationType.paketBitti;
      case 'TK':
        return NotificationType.telafiKullanildi;
      case 'THI':
        return NotificationType.telafiHakkiIadeEdildi;
      case 'DI':
        return NotificationType.dersIptalEdildi;
      default:
        return NotificationType.doOnay; // varsayılan
    }
  }
}

/// Flutter tarafındaki bildirimin modeli.
@immutable
class NotificationModel {
  final int id;
  final int recipient; // Kullanıcı ID
  final int? actor; // Bildirimi tetikleyen kullanıcı ID (nullable)
  final String title;
  final String subject;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.recipient,
    this.actor,
    required this.title,
    required this.subject,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.read,
  });

  /* ----------------------------- JSON ----------------------------- */

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int? parseActor(dynamic value) {
      if (value == null || (value is String && value.isEmpty)) return null;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value); // "42" → 42, "john" → null
      }
      return null;
    }

    return NotificationModel(
      id: json['id'] as int,
      recipient: json['recipient'] as int,
      actor: parseActor(json['actor']),
      title: json['title'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String? ?? '',
      type: _NotificationTypeExt.fromCode(json['notification_type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient': recipient,
        'actor': actor,
        'title': title,
        'subject': subject,
        'body': body,
        'notification_type': type.code,
        'timestamp': timestamp.toIso8601String(),
        'read': read,
      };

  /* --------------------------- Yardımcı --------------------------- */

  /// Okunmamış bildirim mi?
  bool get isUnread => !read;

  NotificationModel copyWith({
    int? id,
    int? recipient,
    int? actor,
    String? title,
    String? subject,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? read,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      actor: actor ?? this.actor,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}
