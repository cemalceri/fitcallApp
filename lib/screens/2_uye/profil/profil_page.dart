// lib/screens/2_uye/profile_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/menu_section.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profile_header.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/quick_info_section.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
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
              child: const IskeletKart(),
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

    // Kabuk sekmesi olarak açıldığında geri okunun gideceği yer yok.
    final geriVar = Navigator.of(context).canPop();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Kaydırınca isim başlığa oturur (X/Twitter profil kalıbı):
          // eski 340 px'lik başlık ekranın yarısını yiyordu.
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            automaticallyImplyLeading: geriVar,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text('${uye.adi} ${uye.soyadi}'),
            actions: [
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, routeEnums[SayfaAdi.ayarlar]!),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              // Başlık yalnız kapanınca görünsün: açıkken isim başlıkta da
              // gövdede de yazıyordu.
              titlePadding: EdgeInsets.zero,
              background: ProfileHeader(uye: uye, seviyeRenk: seviyeRenk),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfilDurumRozetleri(uye: uye, seviyeRenk: seviyeRenk),

                  const SizedBox(height: 20),

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
    );
  }
}
