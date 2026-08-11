// lib/screens/5_etkinlik/widgets/duyuru_carousel.dart

import 'dart:async';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/2_uye/home/widgets/duyuru_detay_sheet.dart';
import 'package:flutter/material.dart';

/// Instagram Stories tarzı duyuru carousel
/// - Progress bar ile otomatik geçiş (5 saniye)
/// - Dokunulduğunda durur
/// - Swipe ile manuel geçiş
/// - Her duyuru için farklı renk paleti
class DuyuruCarousel extends StatefulWidget {
  final List<DuyuruModel> duyurular;
  final double height;
  final Duration autoPlayDuration;

  const DuyuruCarousel({
    super.key,
    required this.duyurular,
    this.height = 180,
    this.autoPlayDuration = const Duration(seconds: 5),
  });

  @override
  State<DuyuruCarousel> createState() => _DuyuruCarouselState();
}

class _DuyuruCarouselState extends State<DuyuruCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentPage = 0;
  bool _isPaused = false;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.autoPlayDuration,
    );

    if (widget.duyurular.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _progressController.forward(from: 0);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        _goToNextPage();
      }
    });
  }

  void _goToNextPage() {
    if (!mounted) return;
    final nextPage = (_currentPage + 1) % widget.duyurular.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _progressController.forward(from: 0);
  }

  void _pauseAutoPlay() {
    _isPaused = true;
    _progressController.stop();
  }

  void _resumeAutoPlay() {
    _isPaused = false;
    _progressController.forward();
  }

  void _openDuyuruDetay(DuyuruModel duyuru) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuyuruDetaySheet(duyuru: duyuru),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duyurular.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Bars (Instagram Stories tarzı)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(widget.duyurular.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 2,
                    right: index == widget.duyurular.length - 1 ? 0 : 2,
                  ),
                  child: _ProgressBar(
                    isActive: index == _currentPage,
                    isCompleted: index < _currentPage,
                    animation:
                        index == _currentPage ? _progressController : null,
                  ),
                ),
              );
            }),
          ),
        ),

        // Carousel
        SizedBox(
          height: widget.height,
          child: GestureDetector(
            onTapDown: (_) => _pauseAutoPlay(),
            onTapUp: (_) => _resumeAutoPlay(),
            onTapCancel: () => _resumeAutoPlay(),
            onLongPressStart: (_) => _pauseAutoPlay(),
            onLongPressEnd: (_) => _resumeAutoPlay(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.duyurular.length,
              itemBuilder: (context, index) {
                final duyuru = widget.duyurular[index];
                return _DuyuruKart(
                  duyuru: duyuru,
                  onTap: () => _openDuyuruDetay(duyuru),
                  index: index,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Progress bar widget (tek bar)
class _ProgressBar extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;
  final AnimationController? animation;

  const _ProgressBar({
    required this.isActive,
    required this.isCompleted,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: isCompleted
            ? Container(color: const Color(0xFF2563EB))
            : isActive && animation != null
                ? AnimatedBuilder(
                    animation: animation!,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animation!.value,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}

/// Tek duyuru kartı - Index'e göre farklı renkler
class _DuyuruKart extends StatelessWidget {
  final DuyuruModel duyuru;
  final VoidCallback onTap;
  final int index;

  const _DuyuruKart({
    required this.duyuru,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background
              _buildGradientBackground(),

              // İçerik
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst kısım: Badge'ler
                    Row(
                      children: [
                        if (duyuru.onemliMi)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Önemli',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (duyuru.resimSayisi > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${duyuru.resimSayisi}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Alt kısım: Başlık ve alt başlık
                    Text(
                      duyuru.baslik,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (duyuru.altBaslik.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        duyuru.altBaslik,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // "Detaylar" butonu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detaylar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildGradientBackground() {
    // 10 farklı renk paleti - beyaz yazıya uygun koyu tonlar
    // 15 duyuru olsa bile döngüsel olarak bu renkler tekrar eder (index % 10)
    final List<List<Color>> colorPalettes = [
      // 4. Koyu Mavi
      [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],

      // 5. Koyu Yeşil
      [const Color(0xFF065F46), const Color(0xFF059669)],

      // 6. Koyu Pembe
      [const Color(0xFF9F1239), const Color(0xFFE11D48)],

      // 7. Koyu Cyan
      [const Color(0xFF155E75), const Color(0xFF0891B2)],

      // 8. Koyu İndigo
      [const Color(0xFF3730A3), const Color(0xFF4F46E5)],

      // 9. Koyu Amber
      [const Color(0xFF92400E), const Color(0xFFF59E0B)],

      // 10. Koyu Teal
      [const Color(0xFF134E4A), const Color(0xFF14B8A6)],

      // 1. Koyu Turuncu
      [const Color(0xFFB45309), const Color(0xFFD97706)],

      // 2. Koyu Kırmızı
      [const Color(0xFF991B1B), const Color(0xFFDC2626)],

      // 3. Koyu Mor
      [const Color(0xFF6B21A8), const Color(0xFF9333EA)],
    ];

    // Önemli duyurular için daha dramatik renkler
    final List<List<Color>> importantPalettes = [
      [const Color(0xFF7C2D12), const Color(0xFFDC2626)],
      [const Color(0xFF881337), const Color(0xFFE11D48)],
      [const Color(0xFF581C87), const Color(0xFF9333EA)],
      [const Color(0xFF172554), const Color(0xFF3B82F6)],
      [const Color(0xFF78350F), const Color(0xFFF59E0B)],
    ];

    final List<Color> colors;
    if (duyuru.onemliMi) {
      // Önemli duyurular: 5 palet arasından seç (mod 5)
      colors = importantPalettes[index % importantPalettes.length];
    } else {
      // Normal duyurular: 10 palet arasından seç (mod 10)
      colors = colorPalettes[index % colorPalettes.length];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 60,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
