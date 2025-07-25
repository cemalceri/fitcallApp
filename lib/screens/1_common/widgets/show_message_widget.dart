import 'dart:async';
import 'package:flutter/material.dart';

enum NotificationType { success, error }

class ShowMessage {
  /// Başarı bildirimi (yeşil, başparmak ikonu)
  static Future<void> success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!Navigator.of(context).mounted) return;
    return _showOverlay(
      context: context,
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.thumb_up,
      duration: duration,
    );
  }

  /// Hata bildirimi (kırmızı, çarpı ikonu)
  static Future<void> error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!Navigator.of(context).mounted) return;
    return _showOverlay(
      context: context,
      message: message,
      backgroundColor: Colors.redAccent,
      icon: Icons.close,
      duration: duration,
    );
  }

  /// Ortak Overlay fonksiyonu
  static Future<void> _showOverlay({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) async {
    // Eğer context artık geçerli değilse çık
    if (!context.mounted) return;
    final overlay = Overlay.of(context);

    // Positioned kullanarak overlay'i ekranın üstünde sabit bir konuma yerleştiriyoruz.
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).toInt()),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Overlay'e ekle (bu işlem sayfanın layout'unu değiştirmez)
    overlay.insert(overlayEntry);

    // Belirli süre bekle
    await Future.delayed(duration);

    // Süre dolduktan sonra context hala geçerliyse overlay'i kaldır
    if (context.mounted) {
      overlayEntry.remove();
    }
  }
}
