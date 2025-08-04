// lib/models/notification_model.dart
// ignore_for_file: constant_identifier_names, unnecessary_this, use_if_null_to_convert_nulls_to_bools

import 'package:flutter/material.dart';

/// Django’daki `NotificationType` enum’unun Dart eşleniği.
enum NotificationType {
  DO, // Ders Onayı
  GO, // Geciken Ödeme
  PB, // Paket Bitiyor
  PS, // Paket Süresi Doluyor
  PBT, // Paket Bitti
  TK, // Telafi Kullanıldı
  THI, // Telafi Hakkı İade Edildi
  DI, // Ders İptal Edildi
  PSA, // Paket Satın Alındı
  PHG, // Paket Hak Güncelleme
  UT, // Üyelik Tanımlandı
}

extension _NotificationTypeExt on NotificationType {
  String get code {
    switch (this) {
      case NotificationType.DO:
        return 'DO';
      case NotificationType.GO:
        return 'GO';
      case NotificationType.PB:
        return 'PB';
      case NotificationType.PS:
        return 'PS';
      case NotificationType.PBT:
        return 'PBT';
      case NotificationType.TK:
        return 'TK';
      case NotificationType.THI:
        return 'THI';
      case NotificationType.DI:
        return 'DI';
      case NotificationType.PSA:
        return 'PSA';
      case NotificationType.PHG:
        return 'PHG';
      case NotificationType.UT:
        return 'UT';
    }
  }

  static NotificationType fromCode(String code) {
    switch (code) {
      case 'DO':
        return NotificationType.DO;
      case 'GO':
        return NotificationType.GO;
      case 'PB':
        return NotificationType.PB;
      case 'PS':
        return NotificationType.PS;
      case 'PBT':
        return NotificationType.PBT;
      case 'TK':
        return NotificationType.TK;
      case 'THI':
        return NotificationType.THI;
      case 'DI':
        return NotificationType.DI;
      case 'PSA':
        return NotificationType.PSA;
      case 'PHG':
        return NotificationType.PHG;
      case 'UT':
        return NotificationType.UT;
      default:
        throw ArgumentError('Unknown notification type code: $code');
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

  // ───── Yeni alanlar ─────
  final String? modelName; // model_name
  final String? modelOwnId; // model_own_id
  final int? genericId; // generic_id
  // ─────────────────────────

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
    this.modelName,
    this.modelOwnId,
    this.genericId,
  });

  /* ----------------------------- JSON ----------------------------- */

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int? tryParseInt(dynamic value) {
      if (value == null || (value is String && value.isEmpty)) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return NotificationModel(
      id: json['id'] as int,
      recipient: json['recipient'] as int,
      actor: tryParseInt(json['actor']),
      title: json['title'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String? ?? '',
      type: _NotificationTypeExt.fromCode(json['notification_type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool? ?? false,
      modelName: json['model_name'] as String?,
      modelOwnId: json['model_own_id']?.toString(),
      genericId: tryParseInt(json['generic_id']),
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
        'model_name': modelName,
        'model_own_id': modelOwnId,
        'generic_id': genericId,
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
    String? modelName,
    String? modelOwnId,
    int? genericId,
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
      modelName: modelName ?? this.modelName,
      modelOwnId: modelOwnId ?? this.modelOwnId,
      genericId: genericId ?? this.genericId,
    );
  }
}
