// lib/screens/3_antrenor/home/models/home_card_model.dart

import 'package:flutter/material.dart';

/// Bilgi kartı türleri
enum HomeCardType {
  pendingApproval, // Onay bekleyen dersler
  weeklySummary, // Haftalık özet
  cancelled, // İptal edilen dersler
  earnings, // Kazanç bilgisi
  studentCount, // Öğrenci sayısı
  upcomingLessons, // Yaklaşan dersler
  info, // Genel bilgilendirme
  warning, // Uyarı
  success, // Başarı mesajı
}

/// Backend'den gelen bilgi kartı modeli
class HomeCardModel {
  final int id;
  final HomeCardType type;
  final String title;
  final String subtitle;
  final String? actionText;
  final String? actionRoute;
  final Map<String, dynamic>? actionParams;
  final int? value;
  final DateTime? createdAt;
  final bool dismissible;

  HomeCardModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.actionRoute,
    this.actionParams,
    this.value,
    this.createdAt,
    this.dismissible = false,
  });

  factory HomeCardModel.fromJson(Map<String, dynamic> json) {
    return HomeCardModel(
      id: json['id'] ?? 0,
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      actionText: json['action_text'],
      actionRoute: json['action_route'],
      actionParams: json['action_params'],
      value: json['value'],
      createdAt: DateTime.tryParse(
          (json['olusturulma_zamani'] ?? json['created_at'] ?? '').toString()),
      dismissible: json['dismissible'] ?? false,
    );
  }

  static HomeCardType _parseType(String? type) {
    switch (type) {
      case 'pending_approval':
        return HomeCardType.pendingApproval;
      case 'weekly_summary':
        return HomeCardType.weeklySummary;
      case 'cancelled':
        return HomeCardType.cancelled;
      case 'earnings':
        return HomeCardType.earnings;
      case 'student_count':
        return HomeCardType.studentCount;
      case 'upcoming_lessons':
        return HomeCardType.upcomingLessons;
      case 'warning':
        return HomeCardType.warning;
      case 'success':
        return HomeCardType.success;
      default:
        return HomeCardType.info;
    }
  }

  /// Kart türüne göre renk
  Color get color {
    switch (type) {
      case HomeCardType.pendingApproval:
        return const Color(0xFFF59E0B); // Turuncu
      case HomeCardType.weeklySummary:
        return const Color(0xFF10B981); // Yeşil
      case HomeCardType.cancelled:
        return const Color(0xFFEF4444); // Kırmızı
      case HomeCardType.earnings:
        return const Color(0xFF8B5CF6); // Mor
      case HomeCardType.studentCount:
        return const Color(0xFF3B82F6); // Mavi
      case HomeCardType.upcomingLessons:
        return const Color(0xFF6366F1); // İndigo
      case HomeCardType.warning:
        return const Color(0xFFF59E0B); // Turuncu
      case HomeCardType.success:
        return const Color(0xFF10B981); // Yeşil
      case HomeCardType.info:
        return const Color(0xFF64748B); // Gri
    }
  }

  /// Kart türüne göre ikon
  IconData get icon {
    switch (type) {
      case HomeCardType.pendingApproval:
        return Icons.schedule_rounded;
      case HomeCardType.weeklySummary:
        return Icons.check_circle_rounded;
      case HomeCardType.cancelled:
        return Icons.cancel_rounded;
      case HomeCardType.earnings:
        return Icons.payments_rounded;
      case HomeCardType.studentCount:
        return Icons.groups_rounded;
      case HomeCardType.upcomingLessons:
        return Icons.event_rounded;
      case HomeCardType.warning:
        return Icons.warning_rounded;
      case HomeCardType.success:
        return Icons.celebration_rounded;
      case HomeCardType.info:
        return Icons.info_rounded;
    }
  }

  /// Kart türüne göre gradient renkleri
  List<Color> get gradientColors {
    return [
      color,
      color.withValues(alpha: 0.8),
    ];
  }
}
