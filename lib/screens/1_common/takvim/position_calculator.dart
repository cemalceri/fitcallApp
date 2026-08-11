// lib/screens/1_common/takvim/position_calculator.dart
// Üye ve antrenör takvimlerinin ORTAK çakışma/pozisyon hesabı.
// İki tarafta satır kaydırma dışında birebir aynı kopyalardı.

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'takvim_zaman.dart';

/// Pozisyonlanmış ders bilgisi
class PositionedLesson {
  final EtkinlikModel ders;
  final int column;
  final int totalColumns;
  final double top;
  final double height;

  PositionedLesson({
    required this.ders,
    required this.column,
    required this.totalColumns,
    required this.top,
    required this.height,
  });

  /// Sol pozisyon hesapla (timeline genişliğine göre)
  double getLeft(double availableWidth) {
    return (availableWidth / totalColumns) * column;
  }

  /// Genişlik hesapla
  double getWidth(double availableWidth) {
    return availableWidth / totalColumns;
  }
}

/// Fazla ders bilgisi (3+ çakışma durumunda)
class OverflowInfo {
  final DateTime startTime;
  final DateTime endTime;
  final List<EtkinlikModel> extraLessons;
  final double top;
  final double height;

  OverflowInfo({
    required this.startTime,
    required this.endTime,
    required this.extraLessons,
    required this.top,
    required this.height,
  });
}

/// Pozisyon hesaplama sonucu
class PositionCalculationResult {
  final List<PositionedLesson> positionedLessons;
  final List<OverflowInfo> overflows;

  PositionCalculationResult({
    required this.positionedLessons,
    required this.overflows,
  });
}

/// Ders pozisyonlarını hesaplayan sınıf
class PositionCalculator {
  /// Derslerin pozisyonlarını hesapla
  static PositionCalculationResult calculate(List<EtkinlikModel> dersler) {
    if (dersler.isEmpty) {
      return PositionCalculationResult(
        positionedLessons: [],
        overflows: [],
      );
    }

    // Başlangıç saatine göre sırala
    final sortedDersler = List<EtkinlikModel>.from(dersler)
      ..sort((a, b) => a.baslangicTarihSaat.compareTo(b.baslangicTarihSaat));

    // Her ders için kolon ataması
    final Map<EtkinlikModel, int> columnAssignments = {};
    final List<PositionedLesson> positionedLessons = [];
    final List<OverflowInfo> overflows = [];

    // Çakışma gruplarını bul
    final groups = _findOverlapGroups(sortedDersler);

    for (final group in groups) {
      if (group.length <= TakvimSizes.maxColumns) {
        // Normal durum: 3 veya daha az ders
        _assignColumns(group, columnAssignments);

        for (final ders in group) {
          final column = columnAssignments[ders]!;
          final totalColumns =
              _getMaxColumnInGroup(group, columnAssignments) + 1;

          positionedLessons.add(PositionedLesson(
            ders: ders,
            column: column,
            totalColumns: totalColumns,
            top: TimeUtils.timeToPixel(ders.baslangicTarihSaat),
            height: _calculateHeight(ders),
          ));
        }
      } else {
        // Overflow durumu: 3'ten fazla ders
        // İlk 3'ü göster, kalanları overflow'a ekle
        final visibleDersler = group.take(TakvimSizes.maxColumns).toList();
        final extraDersler = group.skip(TakvimSizes.maxColumns).toList();

        _assignColumns(visibleDersler, columnAssignments);

        for (final ders in visibleDersler) {
          final column = columnAssignments[ders]!;

          positionedLessons.add(PositionedLesson(
            ders: ders,
            column: column,
            totalColumns: TakvimSizes.maxColumns,
            top: TimeUtils.timeToPixel(ders.baslangicTarihSaat),
            height: _calculateHeight(ders),
          ));
        }

        // Overflow bilgisi ekle
        final earliestStart = group
            .map((d) => d.baslangicTarihSaat)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final latestEnd = group
            .map((d) => d.bitisTarihSaat)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        overflows.add(OverflowInfo(
          startTime: earliestStart,
          endTime: latestEnd,
          extraLessons: extraDersler,
          top: TimeUtils.timeToPixel(earliestStart),
          height: TimeUtils.timeToPixel(latestEnd) -
              TimeUtils.timeToPixel(earliestStart),
        ));
      }
    }

    return PositionCalculationResult(
      positionedLessons: positionedLessons,
      overflows: overflows,
    );
  }

  /// Çakışan dersleri gruplara ayır
  static List<List<EtkinlikModel>> _findOverlapGroups(
      List<EtkinlikModel> dersler) {
    if (dersler.isEmpty) return [];

    final List<List<EtkinlikModel>> groups = [];
    final Set<EtkinlikModel> processed = {};

    for (final ders in dersler) {
      if (processed.contains(ders)) continue;

      // Bu dersle çakışan tüm dersleri bul (transitif)
      final group = <EtkinlikModel>[ders];
      processed.add(ders);

      bool found = true;
      while (found) {
        found = false;
        for (final other in dersler) {
          if (processed.contains(other)) continue;

          // Gruptaki herhangi bir dersle çakışıyor mu?
          final overlapsWithGroup = group.any((g) => TimeUtils.overlaps(
                g.baslangicTarihSaat,
                g.bitisTarihSaat,
                other.baslangicTarihSaat,
                other.bitisTarihSaat,
              ));

          if (overlapsWithGroup) {
            group.add(other);
            processed.add(other);
            found = true;
          }
        }
      }

      groups.add(group);
    }

    return groups;
  }

  /// Gruba kolon ata (greedy algoritma)
  static void _assignColumns(
    List<EtkinlikModel> group,
    Map<EtkinlikModel, int> assignments,
  ) {
    // Başlangıç saatine göre sırala
    final sorted = List<EtkinlikModel>.from(group)
      ..sort((a, b) => a.baslangicTarihSaat.compareTo(b.baslangicTarihSaat));

    for (final ders in sorted) {
      // Bu dersle çakışan ve zaten atanmış derslerin kolonlarını bul
      final usedColumns = <int>{};

      for (final other in sorted) {
        if (other == ders) continue;
        if (!assignments.containsKey(other)) continue;

        if (TimeUtils.overlaps(
          ders.baslangicTarihSaat,
          ders.bitisTarihSaat,
          other.baslangicTarihSaat,
          other.bitisTarihSaat,
        )) {
          usedColumns.add(assignments[other]!);
        }
      }

      // İlk boş kolonu bul
      int column = 0;
      while (usedColumns.contains(column)) {
        column++;
      }

      assignments[ders] = column;
    }
  }

  /// Gruptaki maksimum kolon numarasını bul
  static int _getMaxColumnInGroup(
    List<EtkinlikModel> group,
    Map<EtkinlikModel, int> assignments,
  ) {
    int max = 0;
    for (final ders in group) {
      final col = assignments[ders];
      if (col != null && col > max) {
        max = col;
      }
    }
    return max;
  }

  /// Ders yüksekliğini hesapla
  static double _calculateHeight(EtkinlikModel ders) {
    final duration =
        ders.bitisTarihSaat.difference(ders.baslangicTarihSaat).inMinutes;
    return TimeUtils.durationToHeight(duration);
  }
}
