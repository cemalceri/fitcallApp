// lib/screens/2_uye/home/widgets/uye_next_lesson_card.dart

import 'package:fitcall/common/cihaz_takvimi.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/common/tarih_util.dart';

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

        // Kart: ders varsa ekranın kimlik yüzeyi; yüklenirken ve boşken nötr.
        if (!isLoading && nextLesson != null)
          _LessonContent(lesson: nextLesson!)
        else
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: isLoading
                ? _buildLoadingState(colorScheme)
                : _buildEmptyState(colorScheme),
          ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.all(Bosluk.l),
      child: Parilti(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IskeletKutu(genislik: 140, yukseklik: 16),
            SizedBox(height: Bosluk.m),
            IskeletKutu(genislik: 200, yukseklik: 13),
            SizedBox(height: Bosluk.s),
            IskeletKutu(genislik: 120, yukseklik: 13),
          ],
        ),
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

/// Ders içeriği: ekranın tek kimlik yüzeyi. Yazılar temanın kimlik yazı
/// rengini alır; geri sayım ve tarih kapsülde, bilgiler çerçeveli hapta.
class _LessonContent extends StatelessWidget {
  final EtkinlikModel lesson;

  const _LessonContent({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM EEEE', 'tr_TR');
    final yazi = context.gecis.onKimlik;
    final countdown =
        _geriSayim(lesson.baslangicTarihSaat.difference(simdiKulup()));

    return KimlikYuzeyi(
      onTap: () => _showLessonDetails(context),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateBox(date: lesson.baslangicTarihSaat),
              const SizedBox(width: Bosluk.m),
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
                              fontWeight: FontWeight.w700,
                              color: yazi,
                            ),
                          ),
                        ),
                        const SizedBox(width: Bosluk.s),
                        Flexible(child: KimlikKapsulu(countdown)),
                      ],
                    ),
                    const SizedBox(height: Bosluk.s),
                    // Haplar sarılır: uzun antrenör adı + büyük yazıda taşma
                    // yerine alt satıra iner.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          icon: Icons.access_time_rounded,
                          text:
                              '${tf.format(lesson.baslangicTarihSaat)} - ${tf.format(lesson.bitisTarihSaat)}',
                        ),
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          // Kort adı zaten "Merkez Kort" gibi geliyor; önüne
                          // "Kort " eklemek "Kort Merkez Kort" yazıyordu.
                          text: lesson.kortAdi,
                        ),
                        if (lesson.antrenorAdi != null)
                          _InfoPill(
                            icon: Icons.person_outline_rounded,
                            text: lesson.antrenorAdi!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          Container(
            padding: const EdgeInsets.only(top: Bosluk.s),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: yazi.withValues(alpha: 0.22)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ders detayı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: yazi,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: yazi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Geri sayım metni. Renk yok: kapsül her temada aynı biçimde okunur.
  String _geriSayim(Duration diff) {
    if (diff.inDays > 0) return '${diff.inDays} gün sonra';
    if (diff.inHours > 0) return '${diff.inHours} saat sonra';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dk sonra';
    return 'Şimdi';
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

/// Tarih kutusu (kimlik yüzeyinin üstünde, koyulaştırılmış kapsül zemininde).
class _DateBox extends StatelessWidget {
  final DateTime date;

  const _DateBox({required this.date});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
      decoration: BoxDecoration(
        color: TemaGecisleri.kapsulZemini,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Column(
        children: [
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: yazi,
            ),
          ),
          Text(
            DateFormat('MMM', 'tr_TR').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: yazi,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilgi hapı: kimlik yüzeyinin üstünde ince çerçeveli.
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Yaricap.s),
        border: Border.all(color: yazi.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: yazi),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: yazi),
            ),
          ),
        ],
      ),
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                          dersiCihazTakvimineEkle(lesson);
                        },
                        icon: const Icon(Icons.event_available_outlined,
                            size: 18),
                        label: const Text('Takvime Ekle'),
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
