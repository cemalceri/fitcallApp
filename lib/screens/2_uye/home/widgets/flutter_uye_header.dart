// lib/screens/2_uye/home/widgets/uye_header.dart

import 'dart:convert';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UyeHeader extends StatelessWidget {
  final String uyeAdi;
  final bool hasMultipleProfiles;

  const UyeHeader({
    super.key,
    required this.uyeAdi,
    required this.hasMultipleProfiles,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Future<void> _switchProfile(BuildContext context) async {
    HapticFeedback.lightImpact();
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null) return;

    final profiles = (jsonDecode(jsonStr) as List)
        .map((e) => KullaniciProfilModel.fromJson(e))
        .toList();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilSecPage(profiles)),
    );
  }

  void _logout(BuildContext context) {
    HapticFeedback.lightImpact();
    AuthService.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
      child: Row(
        children: [
          // Sol: Karşılama
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
                        uyeAdi.isNotEmpty ? uyeAdi : 'Hoş geldin',
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

          // Sağ: Aksiyonlar
          Row(
            children: [
              // Bildirim zili
              const NotificationsBell(),

              // Profil değiştir
              if (hasMultipleProfiles)
                IconButton(
                  onPressed: () => _switchProfile(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.onSecondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.switch_account,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              // Çıkış
              IconButton(
                onPressed: () => _logout(context),
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
      ),
    );
  }
}
