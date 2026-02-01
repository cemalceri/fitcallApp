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
    IconData statusIcon;

    if (isIptal) {
      statusColor = TakvimColors.cancelled;
      statusIcon = Icons.cancel_rounded;
    } else if (isPast) {
      statusColor = TakvimColors.completed;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = TakvimColors.future;
      statusIcon = Icons.schedule_rounded;
    }

    return GestureDetector(
      onTap: isIptal ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 2, bottom: 2),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TakvimSizes.lessonCardRadius),
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: TakvimSizes.lessonCardBorderWidth,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TakvimSizes.lessonCardRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isIptal ? null : onTap,
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
                          color: TakvimColors.textPrimary,
                          decoration:
                              isIptal ? TextDecoration.lineThrough : null,
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
                            color: TakvimColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ders.antrenorAdi!,
                              style: TextStyle(
                                fontSize: 11,
                                color: TakvimColors.textSecondary,
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
