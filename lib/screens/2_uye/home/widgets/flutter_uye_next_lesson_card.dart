// lib/screens/2_uye/home/widgets/uye_next_lesson_card.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Sonraki ders kartı widget'ı
class UyeNextLessonCard extends StatelessWidget {
  final EtkinlikModel? nextLesson;
  final bool isLoading;

  const UyeNextLessonCard({
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
        // Başlık
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

        // Kart
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
                  ? _buildEmptyState(colorScheme)
                  : _LessonContent(lesson: nextLesson!),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
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
}

/// Ders içerik widget'ı
class _LessonContent extends StatelessWidget {
  final EtkinlikModel lesson;

  const _LessonContent({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM EEEE', 'tr_TR');

    // Geri sayım hesapla
    final now = DateTime.now();
    final diff = lesson.baslangicTarihSaat.difference(now);
    final (countdown, countdownColor) = _getCountdown(diff);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLessonDetails(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // Tarih kutusu
                  _DateBox(date: lesson.baslangicTarihSaat),
                  const SizedBox(width: 16),

                  // Ders bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarih ve geri sayım
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: countdownColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                countdown,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: countdownColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Saat
                        Row(
                          children: [
                            Flexible(
                              child: _InfoPill(
                                icon: Icons.access_time_rounded,
                                text:
                                    '${tf.format(lesson.baslangicTarihSaat)} - ${tf.format(lesson.bitisTarihSaat)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Kort ve Antrenör — her pill esnek (bounded) genişlikte:
                        // uzun antrenör adı + büyük yazıda taşma yerine ellipsis.
                        Row(
                          children: [
                            Flexible(
                              child: _InfoPill(
                                icon: Icons.location_on_outlined,
                                text: 'Kort ${lesson.kortAdi}',
                              ),
                            ),
                            if (lesson.antrenorAdi != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: _InfoPill(
                                  icon: Icons.person_outline_rounded,
                                  text: lesson.antrenorAdi!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Detay butonu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    // Büyük yazıda taşmasın diye esnek + tek satır
                    Flexible(
                      child: Text(
                        'Detayları görmek için dokunun',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
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

  (String, Color) _getCountdown(Duration diff) {
    if (diff.inDays > 0) {
      return ('${diff.inDays} gün sonra', Colors.blue);
    } else if (diff.inHours > 0) {
      return ('${diff.inHours} saat sonra', Colors.orange);
    } else if (diff.inMinutes > 0) {
      return ('${diff.inMinutes} dk sonra', Colors.green);
    } else {
      return ('Şimdi!', Colors.red);
    }
  }

  void _showLessonDetails(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LessonDetailSheet(lesson: lesson),
    );
  }
}

/// Tarih kutusu
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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

/// Bilgi pill'i
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

/// Ders detay sheet'i
class _LessonDetailSheet extends StatelessWidget {
  final EtkinlikModel lesson;

  const _LessonDetailSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.sports_tennis_rounded,
                    size: 40,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ders Detayları',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // Bilgiler
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tarih',
                        value: df.format(lesson.baslangicTarihSaat),
                      ),
                      _divider(colorScheme),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Saat',
                        value:
                            '${tf.format(lesson.baslangicTarihSaat)} - ${tf.format(lesson.bitisTarihSaat)}',
                      ),
                      _divider(colorScheme),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Kort',
                        value: lesson.kortAdi,
                      ),
                      if (lesson.antrenorAdi != null) ...[
                        _divider(colorScheme),
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Antrenör',
                          value: lesson.antrenorAdi!,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            routeEnums[SayfaAdi.dersler]!,
                          );
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: const Text('Takvime Git'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

/// Detay satırı
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
