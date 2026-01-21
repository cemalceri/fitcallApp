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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final resimler = widget.duyuru.tumResimUrlleri;

    return Container(
      height: screenHeight * 0.92, // Ekranın %92'si
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

          // İçerik (scrollable)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resim Galerisi
                  if (resimler.isNotEmpty) ...[
                    SizedBox(
                      height: 280,
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
                              return _buildImage(resimler[index]);
                            },
                          ),

                          // Sayfa göstergesi (birden fazla resim varsa)
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: isActive ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),

                          // Resim sayısı badge
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
                        ],
                      ),
                    ),
                  ] else ...[
                    // Resim yoksa gradient header
                    _buildGradientHeader(),
                  ],

                  // İçerik
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                                color: const Color(0xFFF59E0B),
                              ),
                            _buildBadge(
                              icon: Icons.calendar_today_rounded,
                              text: _formatDate(widget.duyuru.yayinBaslangic),
                              color: const Color(0xFF2563EB),
                            ),
                            if (widget.duyuru.hedefKitleDisplay != null &&
                                widget.duyuru.hedefKitle != 'herkes')
                              _buildBadge(
                                icon: Icons.people_rounded,
                                text: widget.duyuru.hedefKitleDisplay!,
                                color: const Color(0xFF10B981),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Başlık
                        Text(
                          widget.duyuru.baslik,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),

                        // Alt başlık
                        if (widget.duyuru.altBaslik.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.duyuru.altBaslik,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Divider
                        if (widget.duyuru.icerik.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // İçerik
                        if (widget.duyuru.icerik.isNotEmpty)
                          Text(
                            widget.duyuru.icerik,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),

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

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
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
      height: 160,
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
          size: 64,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
