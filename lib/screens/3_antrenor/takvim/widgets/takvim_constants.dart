// lib/screens/3_antrenor/takvim/widgets/takvim_constants.dart

import 'package:flutter/material.dart';

/// Takvim renk sabitleri
class TakvimColors {
  TakvimColors._();

  // Ana renkler
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);

  // Durum renkleri
  static const Color future = Color(0xFF2563EB); // Mavi - Gelecek ders
  static const Color completed = Color(0xFF10B981); // Yeşil - Yapıldı
  static const Color pending = Color(0xFFF59E0B); // Turuncu - Onay bekliyor
  static const Color notDone = Color(0xFF64748B); // Gri - Yapılmadı
  static const Color cancelled = Color(0xFFEF4444); // Kırmızı - İptal

  // UI renkleri
  static const Color hourLine = Color(0xFFE2E8F0);
  static const Color halfHourLine = Color(0xFFF1F5F9);
  static const Color currentTimeLine = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}

/// Takvim boyut sabitleri
class TakvimSizes {
  TakvimSizes._();

  // Timeline
  static const double pixelsPerMinute = 1.5;
  static const double hourHeight = pixelsPerMinute * 60; // 90px
  static const double timeColumnWidth = 50.0;
  static const double timelineRightPadding = 8.0;

  // Saat aralığı
  static const int dayStartHour = 7;
  static const int dayEndHour = 23;
  static const int totalHours = dayEndHour - dayStartHour; // 16 saat
  static const double totalTimelineHeight = totalHours * hourHeight; // 1440px

  // Ders kartı
  static const double lessonCardRadius = 10.0;
  static const double lessonCardPadding = 8.0;
  static const double lessonCardBorderWidth = 3.0;
  static const int maxColumns = 3;

  // Hafta şeridi
  static const double weekSelectorHeight = 100.0;
  static const double dayItemRadius = 12.0;

  // Çizgiler
  static const double hourLineThickness = 1.0;
  static const double halfHourLineThickness = 0.5;
  static const double currentTimeLineThickness = 2.0;
}

/// Zaman hesaplama yardımcıları
class TimeUtils {
  TimeUtils._();

  /// DateTime'ı piksel pozisyonuna çevir
  static double timeToPixel(DateTime time) {
    final totalMinutes = time.hour * 60 + time.minute;
    final startMinutes = TakvimSizes.dayStartHour * 60;
    final pixels = (totalMinutes - startMinutes) * TakvimSizes.pixelsPerMinute;
    return pixels.clamp(0, TakvimSizes.totalTimelineHeight);
  }

  /// Süreyi piksel yüksekliğine çevir
  static double durationToHeight(int minutes) {
    return minutes * TakvimSizes.pixelsPerMinute;
  }

  /// İki zaman aralığının çakışıp çakışmadığını kontrol et
  static bool overlaps(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Tarihi normalize et (sadece yıl, ay, gün)
  static DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Saati formatla (HH:mm)
  static String formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Tarihi formatla (21 Ocak Salı)
  static String formatDateFull(DateTime d) {
    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const gunler = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    return '${d.day} ${aylar[d.month - 1]} ${gunler[d.weekday - 1]}';
  }

  /// Kısa gün adı (Pt, Sa, Ça...)
  static String shortDayName(int weekday) {
    const days = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    return days[weekday - 1];
  }
}
