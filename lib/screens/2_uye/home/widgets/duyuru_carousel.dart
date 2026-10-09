// lib/screens/2_uye/home/widgets/duyuru_carousel.dart

import 'dart:async';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_detay_sheet.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_gorseli.dart';
import 'package:fitcall/services/core/acilis_popup_service.dart';
import 'package:flutter/material.dart';

/// Instagram Stories tarzı duyuru carousel
/// - Progress bar ile otomatik geçiş (5 saniye)
/// - Dokunulduğunda durur
/// - Swipe ile manuel geçiş
/// - Kart: üstte kapak görseli (yoksa varsayılan poster), altta başlık —
///   metin görselin üstüne yazılmaz (açık renkli afişte okunmuyordu)
class DuyuruCarousel extends StatefulWidget {
  final List<DuyuruModel> duyurular;
  final double height;
  final Duration autoPlayDuration;

  const DuyuruCarousel({
    super.key,
    required this.duyurular,
    this.height = 210,
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
    DuyuruDetaySheet.ac(context, duyuru);
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
    final dolgu = context.cs.primary;
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: isCompleted
            ? ColoredBox(color: dolgu)
            : isActive && animation != null
                ? AnimatedBuilder(
                    animation: animation!,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animation!.value,
                        child: ColoredBox(color: dolgu),
                      );
                    },
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}

/// Tek duyuru kartı: üstte kapak görseli, altta düz zeminde başlık.
///
/// Başlık eskiden görselin (ya da renkli gradyanın) üstüne beyaz yazılıyordu;
/// açık renkli bir afişte okunmuyordu. Artık görselin üstünde yalnız kendi
/// zemini olan rozetler var, metin görselin dışında.
class _DuyuruKart extends StatelessWidget {
  final DuyuruModel duyuru;
  final VoidCallback onTap;

  const _DuyuruKart({required this.duyuru, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    final renkler = context.renkler;
    final ozet = duyuruPopupOzeti(duyuru);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Bosluk.l),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Yaricap.l),
          border: Border.all(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DuyuruGorseli(url: duyuru.ilkResim),
                  if (duyuru.onemliMi)
                    Positioned(
                      top: Bosluk.s,
                      left: Bosluk.s,
                      child: _GorselRozeti(
                        ikon: Icons.star_rounded,
                        metin: 'Önemli',
                        renk: renkler.uyari,
                        zemin: renkler.uyariZemin,
                      ),
                    ),
                  if (duyuru.resimSayisi > 1)
                    Positioned(
                      top: Bosluk.s,
                      right: Bosluk.s,
                      child: _GorselRozeti(
                        ikon: Icons.photo_library_rounded,
                        metin: '${duyuru.resimSayisi}',
                        renk: Colors.white,
                        zemin: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.m, Bosluk.s, Bosluk.m, Bosluk.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    duyuru.baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metin.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ozet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: metin.bodySmall,
                        ),
                      ),
                      const SizedBox(width: Bosluk.s),
                      Text(
                        'Detaylar',
                        style: metin.labelMedium?.copyWith(color: cs.primary),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görselin üstündeki küçük rozet; kendi zemini olduğu için görselin
/// renginden bağımsız okunur.
class _GorselRozeti extends StatelessWidget {
  final IconData ikon;
  final String metin;
  final Color renk;
  final Color zemin;

  const _GorselRozeti({
    required this.ikon,
    required this.metin,
    required this.renk,
    required this.zemin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 3),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renk),
          const SizedBox(width: Bosluk.xs),
          Text(
            metin,
            style: context.metin.labelSmall?.copyWith(color: renk),
          ),
        ],
      ),
    );
  }
}
