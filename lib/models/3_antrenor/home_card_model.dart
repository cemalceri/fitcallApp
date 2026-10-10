// lib/screens/3_antrenor/home/models/home_card_model.dart

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
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
  // Üye "yapılacaklar" kart tipleri (getUyeHomeOzet)
  teyitBekleyen, // Cevaplanmamış ders teyidi
  borc, // Ödenmemiş borç
  paketBitiyor, // Kalan hakkı azalan paket
  telafiSureYaklasan, // Süresi dolmak üzere olan telafi
  degerlendirmeBekleyen, // Değerlendirilmemiş ders
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
      createdAt: parseApiTarih(
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
      case 'teyit_bekleyen':
        return HomeCardType.teyitBekleyen;
      case 'borc':
        return HomeCardType.borc;
      case 'paket_bitiyor':
        return HomeCardType.paketBitiyor;
      case 'telafi_sure_yaklasan':
        return HomeCardType.telafiSureYaklasan;
      case 'degerlendirme_bekleyen':
        return HomeCardType.degerlendirmeBekleyen;
      default:
        return HomeCardType.info;
    }
  }

  /// Kart türünün anlamı. Renk değil: ekran bunu temaya çevirir
  /// (`ton.on(context)`). Eskiden her tür ayrı bir gömülü renkti (turuncu,
  /// mor, indigo, mavi…) ve kartlar rengarenk görünüyordu; artık yalnız durum
  /// bildiren türler durum rengi alır, gerisi temanın ana rengi.
  ListeTonu get ton {
    switch (type) {
      case HomeCardType.pendingApproval:
      case HomeCardType.warning:
      case HomeCardType.teyitBekleyen:
      case HomeCardType.paketBitiyor:
      case HomeCardType.telafiSureYaklasan:
        return ListeTonu.uyari;
      case HomeCardType.weeklySummary:
      case HomeCardType.success:
        return ListeTonu.basari;
      case HomeCardType.cancelled:
      case HomeCardType.borc:
        return ListeTonu.hata;
      case HomeCardType.info:
        return ListeTonu.notr;
      case HomeCardType.earnings:
      case HomeCardType.studentCount:
      case HomeCardType.upcomingLessons:
      case HomeCardType.degerlendirmeBekleyen:
        return ListeTonu.vurgu;
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
      case HomeCardType.teyitBekleyen:
        return Icons.how_to_reg_rounded;
      case HomeCardType.borc:
        return Icons.account_balance_wallet_rounded;
      case HomeCardType.paketBitiyor:
        return Icons.inventory_2_rounded;
      case HomeCardType.telafiSureYaklasan:
        return Icons.event_repeat_rounded;
      case HomeCardType.degerlendirmeBekleyen:
        return Icons.star_rounded;
    }
  }

}
