// lib/screens/2_uye/profile_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/menu_section.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profile_header.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/quick_info_section.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Seviye renk haritası
  static const Map<String, Color> seviyeRenkleri = {
    'Kirmizi': Color(0xFFE53935),
    'Turuncu': Color(0xFFFF9800),
    'Sari': Color(0xFFFFEB3B),
    'Yesil': Color(0xFF4CAF50),
    'Mavi': Color(0xFF2196F3),
  };

  Color _getSeviyeColor(String seviye) {
    return seviyeRenkleri[seviye] ?? Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: StorageService.uyeBilgileriniGetir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.data == null) {
          return const LoginPage();
        }

        return _ProfileContent(
          uye: snapshot.data!,
          getSeviyeColor: _getSeviyeColor,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UyeModel uye;
  final Color Function(String) getSeviyeColor;

  const _ProfileContent({
    required this.uye,
    required this.getSeviyeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final seviyeRenk = getSeviyeColor(uye.seviyeRengi);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              seviyeRenk.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: ProfileHeader(
                  uye: uye,
                  seviyeRenk: seviyeRenk,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // İçerik
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Hızlı Bilgi Kartları
                    QuickInfoSection(uye: uye, seviyeRenk: seviyeRenk),

                    const SizedBox(height: 24),

                    // Menü Bölümü
                    MenuSection(uye: uye, seviyeRenk: seviyeRenk),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
