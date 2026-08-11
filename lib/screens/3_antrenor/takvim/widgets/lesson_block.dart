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
    final colors = _getColors(context, status);
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
                  // Kart yüksekliği ders süresinden gelir, içerik yüksekliği
                  // ise yazı ölçeğiyle büyür; bu yüzden eşikler de ölçeklenir.
                  // Sabit piksel eşiği büyük yazıda kartı aşağı taşırıyordu.
                  final olcek = MediaQuery.textScalerOf(context);
                  final isCompact = constraints.maxHeight < olcek.scale(60);
                  final isVeryCompact = constraints.maxHeight < olcek.scale(50);

                  // Saat metni doğal genişliğinde kalsın ama kartın yarısını
                  // aşmasın; aşarsa kısalır, yanındaki isim hep yer bulur.
                  final saatMaksGenislik = constraints.maxWidth * 0.5;

                  if (isVeryCompact) {
                    // Çok kompakt mod - sadece saat ve isim
                    return Row(
                      children: [
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: saatMaksGenislik),
                          child: Text(
                            TimeUtils.formatTime(ders.baslangicTarihSaat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colors.border,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            katilimcilar.isNotEmpty ? katilimcilar.first : '-',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.takvim.textPrimary,
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
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: saatMaksGenislik),
                          child: Text(
                            TimeUtils.formatTime(ders.baslangicTarihSaat),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.border,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            katilimcilar.isNotEmpty ? katilimcilar.first : '-',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.takvim.textPrimary,
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

                  // Çakışan dersler yan yana dizilince kart daralır ve saat +
                  // rozet metni aynı satıra sığmaz. Sığmıyorsa rozet metnini
                  // düşürüp yalnızca ikon gösteriyoruz; eşik yazı ölçeğiyle
                  // büyür, çünkü iki metin de ölçekle büyüyor.
                  final rozetMetniSigar =
                      constraints.maxWidth >= olcek.scale(150);

                  // Normal mod
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst satır: Saat + Durum badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(ders.bitisTarihSaat)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.border,
                              ),
                            ),
                          ),
                          if (status != LessonStatus.future) ...[
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.55,
                              ),
                              child: rozetMetniSigar
                                  ? _buildStatusBadge(status, colors)
                                  : _buildCompactStatusIcon(status, colors),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Katılımcı adı
                      Expanded(
                        child: Text(
                          katilimcilar.isNotEmpty
                              ? katilimcilar.first
                              : 'Katılımcı yok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.takvim.textPrimary,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: context.takvim.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Katılımcı sayısı (birden fazla ise)
                      if (katilimcilar.length > 1) ...[
                        const SizedBox(height: 2),
                        // maxLines yoksa dar kartta alt satıra sarıp kartı
                        // aşağı taşırıyor.
                        Text(
                          '+${katilimcilar.length - 1} kişi daha',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  /// Blok renkleri durum renginden türetilir: sabit pastel zeminler koyu
  /// temada beyaz lekeler bırakıyordu.
  _LessonColors _getColors(BuildContext context, LessonStatus status) {
    final t = context.takvim;
    final ana = switch (status) {
      LessonStatus.future => t.future,
      LessonStatus.completed => t.completed,
      LessonStatus.antrenorApproved => t.completed,
      LessonStatus.pending => t.pending,
      LessonStatus.notDone => t.notDone,
      LessonStatus.cancelled => t.cancelled,
    };
    return _LessonColors(
      background: ana.withValues(alpha: 0.16),
      backgroundEnd: ana.withValues(alpha: 0.09),
      border: ana,
    );
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
          color: context.takvim.pending,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.swap_horiz_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
