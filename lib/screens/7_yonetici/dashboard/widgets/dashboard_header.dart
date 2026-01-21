// lib/screens/7_yonetici/dashboard/widgets/dashboard_header.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _hasMultipleProfiles = false;

  @override
  void initState() {
    super.initState();
    _checkProfiles();
  }

  Future<void> _checkProfiles() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr != null) {
      final profiles = (jsonDecode(jsonStr) as List)
          .map((e) =>
              KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (profiles.length > 1 && mounted) {
        setState(() => _hasMultipleProfiles = true);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  void _showQrBottomSheet() {
    HapticFeedback.lightImpact();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                      Navigator.pop(context);
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
                      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Yönetici Paneli',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎾', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            // QR Butonu
            IconButton(
              onPressed: _showQrBottomSheet,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const NotificationsBell(),
            if (_hasMultipleProfiles)
              IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final jsonStr = await SecureStorageService.getValue<String>(
                      'kullanici_profiller');
                  if (jsonStr == null) return;
                  final profiles = (jsonDecode(jsonStr) as List)
                      .map((e) => KullaniciProfilModel.fromJson(
                          Map<String, dynamic>.from(e)))
                      .toList();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilSecPage(profiles)),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.switch_account_rounded,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                AuthService.logout(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
