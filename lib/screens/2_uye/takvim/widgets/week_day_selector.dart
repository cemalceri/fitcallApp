// lib/screens/5_etkinlik/takvim/widgets/week_day_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';
import 'package:fitcall/common/tarih_util.dart';

class WeekDaySelector extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Map<DateTime, int> lessonCounts;
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
    final weekStart = TimeUtils.getWeekStart(focusedDay);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ay navigasyonu
          _buildMonthNav(context, theme),
          const SizedBox(height: 16),
          // Gün seçici
          Row(
            children: weekDays
                .map((day) => _buildDayItem(context, theme, day))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav(BuildContext context, ThemeData theme) {
    final monthName = TimeUtils.getMonthName(focusedDay.month);
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
        // Ay etiketi esnek: uzun ay adı + büyük yazıda taşmasın
        Flexible(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              // Bugüne git
              final today = simdiKulup();
              onPageChanged(today);
              onDaySelected(today);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: TakvimColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$monthName $year',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
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
    final isSelected = TimeUtils.isSameDay(day, selectedDay);
    final isToday = TimeUtils.isSameDay(day, simdiKulup());
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
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [TakvimColors.primary, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : isToday
                    ? TakvimColors.primaryLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TakvimSizes.dayItemRadius),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: TakvimColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gün adı — dar hücrede büyük yazıda taşmasın
              Text(
                TimeUtils.shortDayName(day.weekday),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
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
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? TakvimColors.primary
                          : TakvimColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
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
                            ? Colors.white.withValues(alpha: 0.8)
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
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TakvimColors.primaryLight.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: TakvimColors.primary),
        ),
      ),
    );
  }
}
