// lib/screens/profil_secim_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/kullanici_profil_model.dart';

class ProfilSecimScreen extends StatelessWidget {
  const ProfilSecimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Login’dan gelen KullaniciProfilModel listesi
    final profiller = ModalRoute.of(context)!.settings.arguments
        as List<KullaniciProfilModel>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Seç'),
        backgroundColor: Colors.teal.withAlpha((0.8 * 255).toInt()),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),

          // Profil listesi
          Center(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: profiller.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final p = profiller[index];
                // Görünecek isim
                final adSoyad = p.kullanici.ad.isNotEmpty
                    ? '${p.kullanici.ad} ${p.kullanici.soyad}'
                    : p.kullanici.ad;
                // Avatar baş harfleri
                final initials = adSoyad
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .map((w) => w[0])
                    .take(2)
                    .join();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).toInt()),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.teal,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Profil adı
                          Expanded(
                            child: Text(
                              adSoyad,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Seç butonu
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.teal.withAlpha((0.8 * 255).toInt()),
                            ),
                            onPressed: () {
                              // Seçilen profile ait ekran veya işlemi burada başlat
                              Navigator.pushReplacementNamed(
                                context,
                                '/home',
                                arguments: p,
                              );
                            },
                            child: const Text('Seç'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
