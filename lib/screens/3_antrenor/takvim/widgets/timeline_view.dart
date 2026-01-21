// lib/screens/3_antrenor/takvim/widgets/timeline_view.dart

import 'dart:async';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'takvim_constants.dart';
import 'position_calculator.dart';
import 'lesson_block.dart';

class TimelineView extends StatefulWidget {
  final List<EtkinlikModel> dersler;
  final DateTime selectedDay;
  final ValueChanged<EtkinlikModel> onLessonTap;

  const TimelineView({
    super.key,
    required this.dersler,
    required this.selectedDay,
    required this.onLessonTap,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Her dakika güncelle
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = PositionCalculator.calculate(widget.dersler);
    final isToday = _isSameDay(widget.selectedDay, DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth -
            TakvimSizes.timeColumnWidth -
            TakvimSizes.timelineRightPadding;

        return SingleChildScrollView(
          child: SizedBox(
            height: TakvimSizes.totalTimelineHeight + 40, // Alt boşluk
            child: Stack(
              children: [
                // Saat çizgileri
                ..._buildHourLines(),

                // Ders blokları
                ...result.positionedLessons.map((pl) => Positioned(
                      top: pl.top,
                      left: TakvimSizes.timeColumnWidth +
                          pl.getLeft(availableWidth),
                      width: pl.getWidth(availableWidth) - 4, // Gap için
                      height: pl.height,
                      child: LessonBlock(
                        ders: pl.ders,
                        onTap: () => widget.onLessonTap(pl.ders),
                      ),
                    )),

                // Overflow badge'leri
                ...result.overflows.map((overflow) => Positioned(
                      top: overflow.top + overflow.height - 24,
                      right: TakvimSizes.timelineRightPadding,
                      child: _OverflowBadge(
                        count: overflow.extraLessons.length,
                        lessons: overflow.extraLessons,
                        onTap: () => _showOverflowDialog(context, overflow),
                      ),
                    )),

                // Şu anki saat çizgisi (sadece bugün için)
                if (isToday) _buildCurrentTimeLine(),

                // Boş gün mesajı
                if (widget.dersler.isEmpty) _buildEmptyState(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildHourLines() {
    final lines = <Widget>[];

    for (int hour = TakvimSizes.dayStartHour;
        hour <= TakvimSizes.dayEndHour;
        hour++) {
      final top = (hour - TakvimSizes.dayStartHour) * TakvimSizes.hourHeight;

      // Tam saat çizgisi
      lines.add(_HourLine(
        top: top,
        hour: hour,
        isHalfHour: false,
      ));

      // Yarım saat çizgisi (son saat hariç)
      if (hour < TakvimSizes.dayEndHour) {
        lines.add(_HourLine(
          top: top + TakvimSizes.hourHeight / 2,
          hour: hour,
          isHalfHour: true,
        ));
      }
    }

    return lines;
  }

  Widget _buildCurrentTimeLine() {
    final now = _currentTime;
    final top = TimeUtils.timeToPixel(now);

    // Görünür aralıkta mı kontrol et
    if (top < 0 || top > TakvimSizes.totalTimelineHeight) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Saat badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: TakvimColors.currentTimeLine,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              TimeUtils.formatTime(now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Çizgi
          Expanded(
            child: Container(
              height: TakvimSizes.currentTimeLineThickness,
              color: TakvimColors.currentTimeLine,
            ),
          ),
          // Nokta
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: TakvimColors.currentTimeLine,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TakvimSizes.timelineRightPadding),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TakvimColors.hourLine,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: TakvimColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ders Yok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TakvimColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu gün için planlanmış ders bulunmuyor.',
              style: TextStyle(
                fontSize: 14,
                color: TakvimColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverflowDialog(BuildContext context, OverflowInfo overflow) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '+${overflow.extraLessons.length} Ders Daha',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: overflow.extraLessons.map((ders) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sports_tennis_rounded),
              title: Text(ders.uyeList.map((u) => u.adSoyad).join(', ')),
              subtitle: Text(
                '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(ders.bitisTarihSaat)} • ${ders.kortAdi}',
              ),
              onTap: () {
                Navigator.pop(ctx);
                widget.onLessonTap(ders);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Saat çizgisi widget'ı
class _HourLine extends StatelessWidget {
  final double top;
  final int hour;
  final bool isHalfHour;

  const _HourLine({
    required this.top,
    required this.hour,
    required this.isHalfHour,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Saat etiketi
          SizedBox(
            width: TakvimSizes.timeColumnWidth - 8,
            child: isHalfHour
                ? const SizedBox.shrink()
                : Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: TakvimColors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Çizgi
          Expanded(
            child: Container(
              height: isHalfHour
                  ? TakvimSizes.halfHourLineThickness
                  : TakvimSizes.hourLineThickness,
              color: isHalfHour
                  ? TakvimColors.halfHourLine
                  : TakvimColors.hourLine,
            ),
          ),
          const SizedBox(width: TakvimSizes.timelineRightPadding),
        ],
      ),
    );
  }
}

/// Overflow badge widget'ı
class _OverflowBadge extends StatelessWidget {
  final int count;
  final List<EtkinlikModel> lessons;
  final VoidCallback onTap;

  const _OverflowBadge({
    required this.count,
    required this.lessons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TakvimColors.pending,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '+$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
