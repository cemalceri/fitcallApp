// lib/screens/3_antrenor/takvim/widgets/week_day_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class WeekDaySelector extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Map<DateTime, int> lessonCounts; // Gün -> ders sayısı
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const WeekDaySelector({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.lessonCounts,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = _getWeekStart(focusedDay);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ay navigasyonu
          _buildMonthNav(context, theme),
          const SizedBox(height: 12),
          // Gün seçici
          Row(
            children: weekDays.map((day) => _buildDayItem(context, theme, day)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav(BuildContext context, ThemeData theme) {
    final monthName = _getMonthName(focusedDay.month);
    final year = focusedDay.year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            onPageChanged(focusedDay.subtract(const Duration(days: 7)));
          },
        ),
        const SizedBox(width: 16),
        Text(
          '$monthName $year',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            onPageChanged(focusedDay.add(const Duration(days: 7)));
          },
        ),
      ],
    );
  }

  Widget _buildDayItem(BuildContext context, ThemeData theme, DateTime day) {
    final isSelected = _isSameDay(day, selectedDay);
    final isToday = _isSameDay(day, DateTime.now());
    final normalizedDay = TimeUtils.normalizeDate(day);
    final lessonCount = lessonCounts[normalizedDay] ?? 0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onDaySelected(day);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TakvimColors.primary
                : isToday
                    ? TakvimColors.primaryLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TakvimSizes.dayItemRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gün adı
              Text(
                TimeUtils.shortDayName(day.weekday),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : TakvimColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              // Gün numarası
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? TakvimColors.primary
                          : TakvimColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Ders noktaları
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    lessonCount.clamp(0, 4),
                    (i) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : TakvimColors.pending,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TakvimColors.primaryLight.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: TakvimColors.primary),
        ),
      ),
    );
  }
}
