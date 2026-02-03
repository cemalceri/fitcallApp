// lib/screens/5_etkinlik/takvim/widgets/lesson_block.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'takvim_constants.dart';

class LessonBlock extends StatelessWidget {
  final EtkinlikModel ders;
  final VoidCallback onTap;

  const LessonBlock({
    super.key,
    required this.ders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = ders.bitisTarihSaat.isBefore(DateTime.now());
    final isIptal = ders.iptalMi;

    // Durum rengini belirle
    Color statusColor;
    Color backgroundColor;
    Color borderColor;
    IconData statusIcon;

    if (isIptal) {
      // İPTAL EDİLDİ - Kırmızı tema
      statusColor = const Color(0xFFEF4444); // Kırmızı
      backgroundColor = const Color(0xFFFEE2E2); // Açık kırmızımsı
      borderColor = const Color(0xFFFCA5A5); // Kırmızı border
      statusIcon = Icons.cancel_rounded;
    } else if (isPast) {
      statusColor = TakvimColors.completed;
      backgroundColor = statusColor.withValues(alpha: 0.12);
      borderColor = statusColor;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = TakvimColors.future;
      backgroundColor = statusColor.withValues(alpha: 0.12);
      borderColor = statusColor;
      statusIcon = Icons.schedule_rounded;
    }

    return GestureDetector(
      onTap: onTap, // İptal edilen derslere de tıklanabilir
      child: Container(
        margin: const EdgeInsets.only(right: 2, bottom: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(TakvimSizes.lessonCardRadius),
          border: Border.all(
            color: borderColor,
            width: isIptal ? 1.5 : 1.0, // İptal edildiyse daha kalın border
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TakvimSizes.lessonCardRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(TakvimSizes.lessonCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst satır: Saat ve durum
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(ders.bitisTarihSaat)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // İPTAL BADGE (sağ üstte)
                        if (isIptal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'İPTAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Kort adı
                    Expanded(
                      child: Text(
                        ders.kortAdi,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isIptal
                              ? Colors.grey.shade600
                              : TakvimColors.textPrimary,
                          decoration:
                              isIptal ? TextDecoration.lineThrough : null,
                          decorationColor: statusColor,
                          decorationThickness: 2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Antrenör adı (varsa)
                    if (ders.antrenorAdi != null &&
                        ders.antrenorAdi!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: isIptal
                                ? Colors.grey.shade400
                                : TakvimColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ders.antrenorAdi!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isIptal
                                    ? Colors.grey.shade500
                                    : TakvimColors.textSecondary,
                                decoration:
                                    isIptal ? TextDecoration.lineThrough : null,
                                decorationColor:
                                    statusColor.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
