// lib/screens/7_yonetici/dashboard/widgets/dashboard_header.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_ad.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';

class DashboardHeader extends StatefulWidget {
  /// Sol üstteki menü (hamburger) butonuna dokununca çağrılır. null ise buton
  /// gizlenir.
  final VoidCallback? onMenuTap;

  const DashboardHeader({super.key, this.onMenuTap});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _hasMultipleProfiles = false;
  String _yoneticiAdi = '';

  @override
  void initState() {
    super.initState();
    _checkProfiles();
    _adYukle();
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

  Future<void> _adYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _yoneticiAdi = yoneticiGorunenAd(profil.user));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Future<void> _switchProfile() async {
    HapticFeedback.lightImpact();
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null) return;
    final profiles = (jsonDecode(jsonStr) as List)
        .map((e) => KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilSecPage(profiles)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Sol üst: Menü (hamburger)
        if (widget.onMenuTap != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onMenuTap!.call();
            },
            tooltip: 'Menü',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
          ),

        // Karşılama + kullanıcı adı
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
                  Flexible(
                    child: Text(
                      _yoneticiAdi.isNotEmpty ? _yoneticiAdi : 'Hoş geldiniz',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎾', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),

        // Sağ: Aksiyonlar (QR alt bara taşındı)
        Row(
          children: [
            const NotificationsBell(),
            if (_hasMultipleProfiles)
              _HeaderActionButton(
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Profil değiştir',
                color: const Color(0xFF8B5CF6),
                onTap: _switchProfile,
              ),
            _HeaderActionButton(
              icon: Icons.logout_rounded,
              tooltip: 'Çıkış yap',
              color: colorScheme.error,
              onTap: () {
                HapticFeedback.lightImpact();
                AuthService.logout(context);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Header'daki yuvarlak köşeli aksiyon butonu — bildirim ziliyle aynı 42×42
/// kutu ve 22px ikon ölçüsünde durur.
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
