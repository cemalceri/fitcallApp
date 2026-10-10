// lib/screens/3_antrenor/home/widgets/info_card_item.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yapılacaklar/özet kartının yüksekliği. Taban 172px; erişilebilirlik yazı
/// ölçeğiyle (uygulama clamp'i [1.0, 1.3]) büyür ki 1.3x'te değer+başlık+alt
/// başlık+aksiyon dizisi taşmasın. Kart ve carousel aynı değeri kullanır.
double infoCardYuksekligi(BuildContext context) {
  final olcek = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.3);
  return 172.0 * olcek;
}

class InfoCardItem extends StatelessWidget {
  final HomeCardModel card;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InfoCardItem({
    super.key,
    required this.card,
    this.onTap,
    this.onDismiss,
  });

  /// Nötr kart; anlam yalnız ikon kutusunda ve değerde (`card.ton`). Eskiden
  /// her tür kendi renginde gradyanlı bir karttı ve kaydırılan şerit
  /// rengarenk görünüyordu.
  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final ton = card.ton;
    final cardHeight = infoCardYuksekligi(context);
    final kenar = BorderRadius.circular(20);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: kenar,
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          // Kart yüksekliği yazı ölçeğiyle büyür (bkz. infoCardYuksekligi)
          // → 1.3x erişilebilirlik ayarında içerik taşmaz.
          child: SizedBox(
            height: cardHeight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ton.zemin(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(card.icon, color: ton.on(context), size: 20),
                      ),
                      const Spacer(),
                      if (card.dismissible && onDismiss != null)
                        IconButton(
                          tooltip: 'Kapat',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onDismiss!();
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 32, height: 32),
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (card.value != null)
                          SizedBox(
                            width: 200,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                card.value.toString(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: ton.on(context),
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        if (card.value != null) const SizedBox(height: 2),
                        SizedBox(
                          width: 220,
                          child: Text(
                            card.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 220,
                          child: Text(
                            card.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (card.actionText != null)
                    SizedBox(
                      width: 220,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              card.actionText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              color: cs.primary, size: 14),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yükleniyor durumu için placeholder kart
class InfoCardItemSkeleton extends StatelessWidget {
  const InfoCardItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      height: infoCardYuksekligi(context),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Spacer(),
            Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
