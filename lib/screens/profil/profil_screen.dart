import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/uye_model.dart';
import 'package:fitcall/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: uyeBilgileriniGetir(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else {
          if (snapshot.data != null) {
            UyeModel kullanici = snapshot.data!;
            return KullaniciProfilWidget(kullanici: kullanici);
          } else {
            return const LoginPage();
          }
        }
      },
    );
  }
}

class KullaniciProfilWidget extends StatelessWidget {
  const KullaniciProfilWidget({super.key, required this.kullanici});

  final UyeModel kullanici;

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
                label: 'Adı Soyadı',
                value: '${kullanici.adi} ${kullanici.soyadi}'),
            ProfileInfoRow(label: 'Telefon', value: kullanici.telefon ?? ''),
            ProfileInfoRow(label: 'Mail Adresi', value: kullanici.email ?? ''),
            ProfileInfoRow(label: 'Adres', value: kullanici.adres),
            ProfileInfoRow(
                label: 'Üye Numarası', value: kullanici.uyeNo.toString()),
            ProfileInfoRow(
                label: 'Aktiflik Durumu',
                value: kullanici.aktifMi ? 'Aktif' : 'Pasif'),
            ProfileInfoRow(label: 'Seviye', value: kullanici.seviyeRengi),
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
