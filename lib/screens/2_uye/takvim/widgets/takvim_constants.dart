// lib/screens/2_uye/takvim/widgets/takvim_constants.dart

import 'package:flutter/material.dart';

// Boyut sabitleri ve zaman hesaplamaları iki takvimde birebir aynıydı;
// ortak dosyaya taşındı. Mevcut çağrı yerleri bozulmasın diye buradan
// yeniden dışa aktarılıyor (TakvimSizes / TimeUtils aynı isimle erişilir).
export 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';

/// Takvim renk sabitleri
class TakvimColors {
  TakvimColors._();

  // Ana renkler
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);

  // Durum renkleri
  static const Color future = Color(0xFF2563EB); // Mavi - Gelecek ders
  static const Color completed = Color(0xFF10B981); // Yeşil - Tamamlandı
  static const Color pending = Color(0xFFF59E0B); // Turuncu - Beklemede
  static const Color notAttending = Color(0xFFEF4444); // Kırmızı - Katılmayacak
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
