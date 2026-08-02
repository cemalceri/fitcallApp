// lib/screens/3_antrenor/takvim/widgets/lesson_block.dart

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/material.dart';
import 'takvim_constants.dart';
import 'package:fitcall/common/tarih_util.dart';

/// Ders durumu enum
enum LessonStatus {
  future, // Gelecek ders - Mavi
  completed, // Yapıldı (Antrenör + Yönetici onayladı) - Yeşil
  antrenorApproved, // Sadece antrenör onayladı, yönetici bekliyor - Açık yeşil/Turuncu
  pending, // Onay bekliyor (antrenör henüz onaylamadı) - Turuncu
  notDone, // Yapılmadı - Gri
  cancelled, // İptal - Kırmızı
}

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
    final status = _getStatus();
    final colors = _getColors(status);
    final katilimcilar = ders.uyeList.map((u) => u.adSoyad).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TakvimSizes.lessonCardRadius),
            child: Container(
              // Minimum yükseklik - çok kısa dersler için
              constraints: const BoxConstraints(minHeight: 45),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.background, colors.backgroundEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(TakvimSizes.lessonCardRadius),
                border: Border(
                  left: BorderSide(
                    color: colors.border,
                    width: TakvimSizes.lessonCardBorderWidth,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(TakvimSizes.lessonCardPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Kart yüksekliğine göre içerik ayarla
                  final isCompact = constraints.maxHeight < 60;
                  final isVeryCompact = constraints.maxHeight < 50;

                  if (isVeryCompact) {
                    // Çok kompakt mod - sadece saat ve isim
                    return Row(
                      children: [
                        Text(
                          TimeUtils.formatTime(ders.baslangicTarihSaat),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: colors.border,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            katilimcilar.isNotEmpty ? katilimcilar.first : '-',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TakvimColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != LessonStatus.future)
                          _buildCompactStatusIcon(status, colors),
                      ],
                    );
                  }

                  if (isCompact) {
                    // Kompakt mod - tek satır
                    return Row(
                      children: [
                        Text(
                          TimeUtils.formatTime(ders.baslangicTarihSaat),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.border,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            katilimcilar.isNotEmpty ? katilimcilar.first : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TakvimColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != LessonStatus.future)
                          _buildCompactStatusIcon(status, colors),
                      ],
                    );
                  }

                  // Normal mod
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst satır: Saat + Durum badge
                      Row(
                        children: [
                          Text(
                            '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(ders.bitisTarihSaat)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.border,
                            ),
                          ),
                          const Spacer(),
                          if (status != LessonStatus.future)
                            Flexible(
                              child: _buildStatusBadge(status, colors),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Katılımcı adı
                      Expanded(
                        child: Text(
                          katilimcilar.isNotEmpty
                              ? katilimcilar.first
                              : 'Katılımcı yok',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TakvimColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Kort bilgisi
                      Text(
                        [ders.kortAdi, ders.seviye]
                            .where((s) => s.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: TakvimColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Katılımcı sayısı (birden fazla ise)
                      if (katilimcilar.length > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+${katilimcilar.length - 1} kişi daha',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.border,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Aktif devir talebi rozeti
        if (ders.aktifDevirTalebi != null)
          Positioned(
            top: -4,
            right: -4,
            child: _DevirBadge(
              benTalepEden: ders.aktifDevirTalebi!.benTalepEdenim,
            ),
          ),
      ],
    );
  }

  LessonStatus _getStatus() {
    // İptal mi? - En önce kontrol et
    if (ders.iptalMi) return LessonStatus.cancelled;

    // Geçmiş mi gelecek mi?
    final now = simdiKulup();
    final isPast = ders.bitisTarihSaat.isBefore(now);

    if (!isPast) return LessonStatus.future;

    // Geçmiş ders - onay durumlarını kontrol et
    final antrenorOnayi = ders.antrenorOnayi;
    final yoneticiOnayi = ders.yoneticiOnayi;

    // Antrenör onayı var mı?
    if (antrenorOnayi != null) {
      // Antrenör "yapılmadı" dediyse
      if (!antrenorOnayi.tamamlandi) {
        return LessonStatus.notDone;
      }

      // Antrenör "yapıldı" dedi, yönetici onayı var mı?
      if (yoneticiOnayi != null && yoneticiOnayi.tamamlandi) {
        // Her ikisi de onayladı
        return LessonStatus.completed;
      }

      // Sadece antrenör onayladı, yönetici henüz onaylamadı
      return LessonStatus.antrenorApproved;
    }

    // Antrenör henüz onay vermemiş
    return LessonStatus.pending;
  }

  _LessonColors _getColors(LessonStatus status) {
    switch (status) {
      case LessonStatus.future:
        return _LessonColors(
          background: const Color(0xFFDBEAFE),
          backgroundEnd: const Color(0xFFBFDBFE),
          border: TakvimColors.future,
        );
      case LessonStatus.completed:
        return _LessonColors(
          background: const Color(0xFFDCFCE7),
          backgroundEnd: const Color(0xFFBBF7D0),
          border: TakvimColors.completed,
        );
      case LessonStatus.antrenorApproved:
        // Antrenör onayladı ama yönetici bekliyor - açık yeşil/sarımsı
        return _LessonColors(
          background: const Color(0xFFE8F5E9),
          backgroundEnd: const Color(0xFFFFF8E1),
          border: const Color(0xFF8BC34A), // Açık yeşil
        );
      case LessonStatus.pending:
        return _LessonColors(
          background: const Color(0xFFFEF3C7),
          backgroundEnd: const Color(0xFFFDE68A),
          border: TakvimColors.pending,
        );
      case LessonStatus.notDone:
        return _LessonColors(
          background: const Color(0xFFF1F5F9),
          backgroundEnd: const Color(0xFFE2E8F0),
          border: TakvimColors.notDone,
        );
      case LessonStatus.cancelled:
        return _LessonColors(
          background: const Color(0xFFFEE2E2),
          backgroundEnd: const Color(0xFFFECACA),
          border: TakvimColors.cancelled,
        );
    }
  }

  /// Kompakt modda sadece ikon göster
  Widget _buildCompactStatusIcon(LessonStatus status, _LessonColors colors) {
    IconData icon;
    switch (status) {
      case LessonStatus.completed:
        icon = Icons.check_circle;
        break;
      case LessonStatus.antrenorApproved:
        icon = Icons.hourglass_empty;
        break;
      case LessonStatus.pending:
        icon = Icons.schedule;
        break;
      case LessonStatus.notDone:
        icon = Icons.cancel_outlined;
        break;
      case LessonStatus.cancelled:
        icon = Icons.close;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: colors.border),
    );
  }

  Widget _buildStatusBadge(LessonStatus status, _LessonColors colors) {
    String text;
    IconData? icon;

    switch (status) {
      case LessonStatus.completed:
        text = 'Tamamlandı';
        icon = Icons.check_circle;
        break;
      case LessonStatus.antrenorApproved:
        text = 'Yön. Onayı Bekliyor';
        icon = Icons.hourglass_empty;
        break;
      case LessonStatus.pending:
        text = 'Onay Bekliyor';
        icon = Icons.schedule;
        break;
      case LessonStatus.notDone:
        text = 'Yapılmadı';
        icon = Icons.cancel_outlined;
        break;
      case LessonStatus.cancelled:
        text = 'İptal Edildi';
        icon = Icons.close;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
            Icon(icon, size: 10, color: colors.border),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colors.border,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonColors {
  final Color background;
  final Color backgroundEnd;
  final Color border;

  _LessonColors({
    required this.background,
    required this.backgroundEnd,
    required this.border,
  });
}

/// Aktif devir talebi rozeti
class _DevirBadge extends StatelessWidget {
  final bool benTalepEden;
  const _DevirBadge({required this.benTalepEden});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: benTalepEden
          ? 'Devir talebiniz cevap bekliyor'
          : 'Size devir teklifi geldi',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: TakvimColors.pending,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.swap_horiz_rounded,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
