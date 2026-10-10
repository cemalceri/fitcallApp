// lib/screens/3_antrenor/home/widgets/next_lesson_card.dart

import 'package:fitcall/common/cihaz_takvimi.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/common/tema.dart';
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
        // Ders varsa ekranın kimlik yüzeyi; yüklenirken ve boşken nötr kart.
        if (!isLoading && nextLesson != null)
          _buildLessonInfo(context)
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
                : _buildNoLessonState(colorScheme),
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

  Widget _buildLessonInfo(BuildContext context) {
    final lesson = nextLesson!;
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM EEEE', 'tr_TR');
    final yazi = context.gecis.onKimlik;
    final countdown =
        _geriSayim(lesson.baslangicTarihSaat.difference(simdiKulup()));

    return KimlikYuzeyi(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, routeEnums[SayfaAdi.antrenorDersler]!);
      },
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
                        text: lesson.uyeList.map((u) => u.adSoyad).join(', '),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          // Dersi telefonun takvimine ekler; karta dokunmak zaten
          // uygulamanın takvimini açtığı için şerit "takvime git" demek
          // yerine gerçek bir iş yapıyor.
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => dersiCihazTakvimineEkle(lesson),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: yazi.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available_outlined, size: 16, color: yazi),
                    const SizedBox(width: 6),
                    Text(
                      'Takvime ekle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: yazi,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Geri sayım metni; kapsül her temada aynı biçimde okunur.
  String _geriSayim(Duration diff) {
    if (diff.inDays > 0) return '${diff.inDays} gün sonra';
    if (diff.inHours > 0) return '${diff.inHours} saat sonra';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dk sonra';
    return 'Şimdi';
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: yazi),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(fontSize: 12, color: yazi),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
