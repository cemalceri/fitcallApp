// lib/screens/7_yonetici/widgets/yonetici_qr_sheet.dart

import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yöneticinin QR işlemleri seçim sayfası (QR Oluştur / QR Doğrula).
///
/// Önce dashboard header'ındaki QR butonuna bağlıydı; alt bardaki merkez QR
/// butonuna taşınınca ortak hale getirildi.
Future<void> showYoneticiQrSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  final colorScheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'QR Kod İşlemleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QrOptionCard(
                  icon: Icons.qr_code,
                  title: 'QR Oluştur',
                  subtitle: 'Giriş için kod üret',
                  color: colorScheme.primary,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                        context, routeEnums[SayfaAdi.qrKodKayit]!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QrOptionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'QR Doğrula',
                  subtitle: 'Kodu okut ve doğrula',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                        context, routeEnums[SayfaAdi.qrKodDogrula]!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Bottom sheet içindeki QR seçenek kartı
class _QrOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QrOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
