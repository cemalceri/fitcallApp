// lib/screens/3_antrenor/home/widgets/next_lesson_card.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/common/tarih_util.dart';

class NextLessonCard extends StatelessWidget {
  final EtkinlikModel? nextLesson;
  final bool isLoading;

  const NextLessonCard({
    super.key,
    this.nextLesson,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Sonraki Ders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? _buildLoadingState(colorScheme)
              : nextLesson == null
                  ? _buildNoLessonState(colorScheme)
                  : _buildLessonInfo(context, colorScheme),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNoLessonState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planlanmış ders yok',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yaklaşan dersiniz bulunmuyor',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(BuildContext context, ColorScheme colorScheme) {
    final lesson = nextLesson!;
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM EEEE', 'tr_TR');

    final now = simdiKulup();
    final diff = lesson.baslangicTarihSaat.difference(now);
    final countdown = _getCountdown(diff);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, routeEnums[SayfaAdi.antrenorDersler]!);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Tarih Kutusu
                  _DateBox(date: lesson.baslangicTarihSaat),
                  const SizedBox(width: 16),

                  // Ders Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                df.format(lesson.baslangicTarihSaat),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            _CountdownBadge(
                              text: countdown.text,
                              color: countdown.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _InfoPill(
                          icon: Icons.access_time_rounded,
                          text:
                              '${tf.format(lesson.baslangicTarihSaat)} - ${tf.format(lesson.bitisTarihSaat)}',
                        ),
                        const SizedBox(height: 6),
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          text: lesson.kortAdi,
                        ),
                        if (lesson.uyeList.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _InfoPill(
                            icon: Icons.person_outline_rounded,
                            text:
                                lesson.uyeList.map((u) => u.adSoyad).join(', '),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Detay Butonu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Takvime git',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CountdownInfo _getCountdown(Duration diff) {
    if (diff.inDays > 0) {
      return _CountdownInfo('${diff.inDays} gün sonra', Colors.blue);
    } else if (diff.inHours > 0) {
      return _CountdownInfo('${diff.inHours} saat sonra', Colors.orange);
    } else if (diff.inMinutes > 0) {
      return _CountdownInfo('${diff.inMinutes} dk sonra', Colors.green);
    } else {
      return _CountdownInfo('Şimdi!', Colors.red);
    }
  }
}

class _CountdownInfo {
  final String text;
  final Color color;
  _CountdownInfo(this.text, this.color);
}

class _DateBox extends StatelessWidget {
  final DateTime date;

  const _DateBox({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF6366F1).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Text(
            DateFormat('MMM', 'tr_TR').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CountdownBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
