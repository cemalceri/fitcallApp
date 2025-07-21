import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: AuthService.uyeBilgileriniGetir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else {
          if (snapshot.data != null) {
            UyeModel uye = snapshot.data!;
            return KullaniciProfilWidget(uye: uye);
          } else {
            return const LoginPage();
          }
        }
      },
    );
  }
}

class KullaniciProfilWidget extends StatelessWidget {
  const KullaniciProfilWidget({super.key, required this.uye});

  final UyeModel uye;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Bilgileri')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileInfoRow(
                label: 'Adı Soyadı', value: '${uye.adi} ${uye.soyadi}'),
            ProfileInfoRow(label: 'Telefon', value: uye.telefon ?? ''),
            ProfileInfoRow(label: 'Mail Adresi', value: uye.email ?? ''),
            ProfileInfoRow(label: 'Adres', value: uye.adres),
            ProfileInfoRow(label: 'Üye Numarası', value: uye.uyeNo.toString()),
            ProfileInfoRow(
                label: 'Aktiflik Durumu',
                value: uye.aktifMi ? 'Aktif' : 'Pasif'),
            ProfileInfoRow(label: 'Seviye', value: uye.seviyeRengi),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }
}
