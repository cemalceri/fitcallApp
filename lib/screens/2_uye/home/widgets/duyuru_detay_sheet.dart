// lib/screens/5_etkinlik/widgets/duyuru_detay_sheet.dart

import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-screen duyuru detay bottom sheet
/// - Resim galerisi (swipe ile geçiş)
/// - Başlık, alt başlık, içerik
/// - Scroll edilebilir
class DuyuruDetaySheet extends StatefulWidget {
  final DuyuruModel duyuru;

  const DuyuruDetaySheet({
    super.key,
    required this.duyuru,
  });

  @override
  State<DuyuruDetaySheet> createState() => _DuyuruDetaySheetState();
}

class _DuyuruDetaySheetState extends State<DuyuruDetaySheet> {
  late PageController _imagePageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
  }

  /// Resmi tam ekran aç
  void _openFullScreenImage(List<String> resimler, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          resimler: resimler,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final resimler = widget.duyuru.tumResimUrlleri;
    final hasContent = widget.duyuru.icerik.isNotEmpty;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable içerik
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resim Galerisi veya Gradient Header
                  if (resimler.isNotEmpty)
                    _buildImageGallery(resimler)
                  else
                    _buildGradientHeader(),

                  // İçerik alanı
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge'ler
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (widget.duyuru.onemliMi)
                              _buildBadge(
                                icon: Icons.star_rounded,
                                text: 'Önemli Duyuru',
                                backgroundColor: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.12),
                                textColor: const Color(0xFFB45309),
                                borderColor: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            _buildBadge(
                              icon: Icons.calendar_today_rounded,
                              text: _formatDate(widget.duyuru.yayinBaslangic),
                              backgroundColor: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.1),
                              textColor: const Color(0xFF1D4ED8),
                              borderColor: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.25),
                            ),
                            if (widget.duyuru.hedefKitleDisplay != null &&
                                widget.duyuru.hedefKitle != 'herkes')
                              _buildBadge(
                                icon: Icons.people_rounded,
                                text: widget.duyuru.hedefKitleDisplay!,
                                backgroundColor: const Color(0xFF10B981)
                                    .withValues(alpha: 0.1),
                                textColor: const Color(0xFF047857),
                                borderColor: const Color(0xFF10B981)
                                    .withValues(alpha: 0.25),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Başlık
                        Text(
                          widget.duyuru.baslik,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: const Color(0xFF111827),
                          ),
                        ),

                        // Alt başlık
                        if (widget.duyuru.altBaslik.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.duyuru.altBaslik,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],

                        // Divider ve İçerik
                        if (hasContent) ...[
                          const SizedBox(height: 24),
                          // Divider
                          Container(
                            height: 1,
                            width: double.infinity,
                            color: const Color(0xFFE5E7EB),
                          ),
                          const SizedBox(height: 24),
                          // İçerik metni
                          Text(
                            widget.duyuru.icerik,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.75,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alt buton
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> resimler) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // Resim PageView
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: resimler.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullScreenImage(resimler, index),
                child: _buildImage(resimler[index]),
              );
            },
          ),

          // Resim sayısı badge (sağ üst)
          if (resimler.length > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${resimler.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Sayfa göstergesi dots (alt orta)
          if (resimler.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(resimler.length, (i) {
                  final isActive = i == _currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover, // contain yerine cover
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: const Color(0xFF2563EB),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientHeader() {
    final colors = widget.duyuru.onemliMi
        ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
        : [const Color(0xFF2563EB), const Color(0xFF7C3AED)];

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Dekoratif daire
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Merkez ikon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.campaign_rounded,
                size: 36,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tam ekran resim görüntüleyici
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> resimler;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.resimler,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Resim galerisi
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.resimler.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.resimler[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.white54,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Üst bar - Kapat butonu ve sayaç
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kapat butonu
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Resim sayacı
                    if (widget.resimler.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.resimler.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Boş alan (simetri için)
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Alt sayfa göstergesi
          if (widget.resimler.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.resimler.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
