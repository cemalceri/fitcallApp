// lib/screens/1_common/widgets/duyuru_detay_sheet.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_varsayilan_poster.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/duyuru_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-screen duyuru detay bottom sheet
/// - Resim galerisi (swipe ile geçiş)
/// - Başlık, alt başlık, içerik
/// - Scroll edilebilir
class DuyuruDetaySheet extends StatefulWidget {
  final DuyuruModel duyuru;

  /// Okuma kaydının ölçüm kaynağı: ana sayfa carousel'i (varsayılan, sunucuya
  /// parametre gitmez) ya da açılış popup'ındaki "Detaylı bilgi".
  final String? kaynak;

  const DuyuruDetaySheet({
    super.key,
    required this.duyuru,
    this.kaynak,
  });

  /// Sayfayı alttan açar (carousel ve açılış popup'ı aynı yolu kullanır).
  static Future<void> ac(BuildContext context, DuyuruModel duyuru,
      {String? kaynak}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DuyuruDetaySheet(duyuru: duyuru, kaynak: kaynak),
    );
  }

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
    _markAsRead(); // YENİ
  }

  void _markAsRead() {
    if (widget.duyuru.id <= 0) return;
    DuyuruService.setDuyuruOkundu(
      duyuruId: widget.duyuru.id,
      kaynak: widget.kaynak,
      detayAcildi: widget.kaynak == null ? null : true,
    ).catchError(
      (_) => ApiResult<Map<String, dynamic>>(mesaj: ''),
    );
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
    final cs = context.cs;
    final metin = context.metin;
    final renkler = context.renkler;
    final screenHeight = MediaQuery.of(context).size.height;
    final duyuru = widget.duyuru;
    final resimler = duyuru.tumResimUrlleri;
    final hasContent = duyuru.icerik.isNotEmpty;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(Yaricap.sayfa)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: Bosluk.m),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Bosluk.s),

          // Scrollable içerik
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resim galerisi; görsel yoksa popup'la aynı varsayılan poster
                  if (resimler.isNotEmpty)
                    _buildImageGallery(resimler)
                  else
                    const SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: DuyuruVarsayilanPoster(),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(Bosluk.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Bosluk.s,
                          runSpacing: Bosluk.s,
                          children: [
                            if (duyuru.onemliMi)
                              _rozet(
                                ikon: Icons.star_rounded,
                                metin: 'Önemli Duyuru',
                                renk: renkler.uyari,
                                zemin: renkler.uyariZemin,
                              ),
                            _rozet(
                              ikon: Icons.calendar_today_rounded,
                              metin: _formatDate(duyuru.yayinBaslangic),
                              renk: renkler.bilgi,
                              zemin: renkler.bilgiZemin,
                            ),
                            if (duyuru.hedefKitleDisplay != null &&
                                duyuru.hedefKitle != 'herkes')
                              _rozet(
                                ikon: Icons.people_rounded,
                                metin: duyuru.hedefKitleDisplay!,
                                renk: renkler.basari,
                                zemin: renkler.basariZemin,
                              ),
                          ],
                        ),

                        const SizedBox(height: Bosluk.l),

                        Text(duyuru.baslik, style: metin.headlineSmall),

                        if (duyuru.altBaslik.isNotEmpty) ...[
                          const SizedBox(height: Bosluk.s),
                          Text(
                            duyuru.altBaslik,
                            style: metin.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        if (hasContent) ...[
                          const SizedBox(height: Bosluk.xl),
                          const Divider(),
                          const SizedBox(height: Bosluk.xl),
                          Text(
                            duyuru.icerik,
                            style: metin.bodyLarge?.copyWith(height: 1.65),
                          ),
                        ],

                        const SizedBox(height: Bosluk.xxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alt buton — tema birincil rengi (koyu temada yazı rengi de doğru gelir)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.xl, Bosluk.s, Bosluk.xl, Bosluk.m),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
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
    return Image(
      image: CachedNetworkImageProvider(url),
      fit: BoxFit.cover, // contain yerine cover
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.outlineVariant,
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

  /// Durum rozeti. Renkler tema uzantısından: koyu temada açık metin + koyu
  /// zemin, açıkta tersi — sabit hex ikisinden birinde okunmuyordu.
  Widget _rozet({
    required IconData ikon,
    required String metin,
    required Color renk,
    required Color zemin,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Bosluk.m, vertical: Bosluk.xs + 2),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(Yaricap.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: renk),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              metin,
              style: context.metin.labelLarge?.copyWith(color: renk),
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
                  child: Image(
                    image: CachedNetworkImageProvider(widget.resimler[index]),
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
                      tooltip: 'Kapat',
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
