// lib/screens/3_antrenor/home/widgets/home_header.dart

import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tarih_util.dart';

class HomeHeader extends StatelessWidget {
  final String antrenorAdi;
  final bool hasMultipleProfiles;

  /// Sol üstteki menü (hamburger) butonuna dokununca çağrılır. null ise buton
  /// gizlenir.
  final VoidCallback? onMenuTap;

  const HomeHeader({
    super.key,
    required this.antrenorAdi,
    required this.hasMultipleProfiles,
    this.onMenuTap,
  });

  String _getGreeting() {
    final hour = simdiKulup().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(onMenuTap == null ? 20 : 8, 12, 8, 16),
      child: Row(
        children: [
          // Sol üst: Menü (hamburger)
          if (onMenuTap != null)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onMenuTap!.call();
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
                        antrenorAdi.isNotEmpty ? antrenorAdi : 'Hoş geldin',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🎾', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),

          // Aksiyonlar
          Row(
            children: [
              const NotificationsBell(),
              if (hasMultipleProfiles) const ProfilDegistirButonu(),
              _LogoutButton(colorScheme: colorScheme),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LogoutButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
    );
  }
}
