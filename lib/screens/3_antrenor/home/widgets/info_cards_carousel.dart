// lib/screens/3_antrenor/home/widgets/info_cards_carousel.dart

import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:flutter/material.dart';
import 'info_card_item.dart';

class InfoCardsCarousel extends StatelessWidget {
  final List<HomeCardModel> cards;
  final bool isLoading;
  final Function(HomeCardModel card)? onCardTap;
  final Function(HomeCardModel card)? onCardDismiss;

  /// Bölüm başlığı (antrenör: 'Özet', üye: 'Yapılacaklar')
  final String title;

  /// true ise kart yokken bölüm tamamen gizlenir (boş durum kartı yerine)
  final bool hideWhenEmpty;

  const InfoCardsCarousel({
    super.key,
    required this.cards,
    this.isLoading = false,
    this.onCardTap,
    this.onCardDismiss,
    this.title = 'Özet',
    this.hideWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (hideWhenEmpty && !isLoading && cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              // Flexible: dar ekran + büyük yazı ölçeğinde başlık taşmasın,
              // sayaç rozetini itmeden kısalsın.
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (cards.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: infoCardYuksekligi(context),
          child: isLoading
              ? _buildLoadingState()
              : cards.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildCarousel(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, __) => const InfoCardItemSkeleton(),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Her şey yolunda!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Şu an için bildirim yok',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return InfoCardItem(
          card: card,
          onTap: onCardTap != null ? () => onCardTap!(card) : null,
          onDismiss: card.dismissible && onCardDismiss != null
              ? () => onCardDismiss!(card)
              : null,
        );
      },
    );
  }
}

/// Sayfa indikatörü (opsiyonel kullanım için)
class CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color? activeColor;
  final Color? inactiveColor;

  const CarouselIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? (activeColor ?? colorScheme.primary)
                : (inactiveColor ?? colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
