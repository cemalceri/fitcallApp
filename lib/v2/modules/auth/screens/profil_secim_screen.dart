// lib/screens/profil_secim_screen.dart
import 'dart:ui';
import 'package:fitcall/v2/modules/auth/models/kullanici_profil_model.dart';
import 'package:flutter/material.dart';

class ProfilSecimScreen extends StatelessWidget {
  const ProfilSecimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginResp =
        ModalRoute.of(context)!.settings.arguments as LoginResponse;
    final uyeler = loginResp.uyeler;
    final antrenorler = loginResp.antrenorler;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hesap Seçimi',
          style: TextStyle(color: Colors.black), // başlık siyah
        ),
        backgroundColor: Colors.teal.withAlpha((0.8 * 255).toInt()),
        iconTheme: const IconThemeData(color: Colors.black),
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

          // Hesap listesi
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (uyeler.isNotEmpty) ...[
                  const Text(
                    'Üye Hesapları',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...uyeler.map((uye) => _buildProfileCard(
                        context: context,
                        adi: uye.adi,
                        soyadi: uye.soyadi,
                        label: 'Üye Hesabı',
                        onSelect: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/home',
                            arguments: uye,
                          );
                        },
                      )),
                  const SizedBox(height: 24),
                ],
                if (antrenorler.isNotEmpty) ...[
                  const Text(
                    'Antrenör Hesapları',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...antrenorler.map((ant) => _buildProfileCard(
                        context: context,
                        adi: ant.adi,
                        soyadi: ant.soyadi,
                        label: 'Antrenör Hesabı',
                        onSelect: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/home',
                            arguments: ant,
                          );
                        },
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String adi,
    required String soyadi,
    required String label,
    required VoidCallback onSelect,
  }) {
    final adSoyad = '$adi $soyadi';
    final initials = adSoyad
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                  backgroundColor: Colors.teal.withAlpha((0.8 * 255).toInt()),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.black, // avatar içi metin siyah
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adSoyad,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.black.withAlpha(
                              (0.7 * 255).toInt()), // alt etiket siyahımsı
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Seç butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.withAlpha((0.8 * 255).toInt()),
                  ),
                  onPressed: onSelect,
                  child: const Text(
                    'Seç',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
