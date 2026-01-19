// lib/screens/9_yonetici/dashboard/widgets/dashboard_header.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
