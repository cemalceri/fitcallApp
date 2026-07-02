// lib/screens/7_yonetici/widgets/skeleton.dart
//
// Harici paket bağımlılığı olmadan shimmer/skeleton yükleme placeholder'ları.
// Kullanım: içeriğin iskeletini gri kutularla kur, Shimmer ile sar.

import 'package:flutter/material.dart';

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Alt ağaçtaki [SkeletonBox]'ların üzerinden kayan bir parıltı geçirir.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6);
    final highlight =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              transform:
                  _SlidingGradientTransform(_controller.value * 3 - 1.5),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Shimmer içinde kullanılacak opak gri placeholder kutu.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Üye/borçlu liste sayfaları için satır iskeleti.
class UyeListeSkeleton extends StatelessWidget {
  final int itemCount;

  const UyeListeSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _UyeRowSkeleton(),
        ),
      ),
    );
  }
}

class _UyeRowSkeleton extends StatelessWidget {
  const _UyeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 60, height: 14),
        ],
      ),
    );
  }
}

/// Dashboard için istatistik kartları + grafik iskeleti.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 22),
            const SizedBox(height: 20),
            const SkeletonBox(width: double.infinity, height: 42, radius: 12),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: List.generate(
                6,
                (_) => const SkeletonBox(
                    width: double.infinity, height: 120, radius: 16),
              ),
            ),
            const SizedBox(height: 16),
            const SkeletonBox(
                width: double.infinity, height: 200, radius: 16),
          ],
        ),
      ),
    );
  }
}
