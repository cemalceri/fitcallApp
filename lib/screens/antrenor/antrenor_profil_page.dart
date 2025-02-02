import 'package:flutter/material.dart';

// Antrenör Modeli
class TrainerModel {
  final String adi;
  final String soyadi;
  final String telefon;
  final String email;
  final String adres;
  final String uzmanlik;
  final bool aktifMi;
  final String seviye;

  TrainerModel({
    required this.adi,
    required this.soyadi,
    required this.telefon,
    required this.email,
    required this.adres,
    required this.uzmanlik,
    required this.aktifMi,
    required this.seviye,
  });
}

class AntrenorProfilPage extends StatelessWidget {
  AntrenorProfilPage({super.key});

  // Örnek Antrenör Bilgileri
  final TrainerModel trainer = TrainerModel(
    adi: 'Ahmet',
    soyadi: 'Yılmaz',
    telefon: '+90 555 123 45 67',
    email: 'ahmet.yilmaz@example.com',
    adres: 'İstanbul, Türkiye',
    uzmanlik: 'Fitness ve Vücut Geliştirme',
    aktifMi: true,
    seviye: 'İleri Düzey',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenör Profili'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profil Resmi (Şimdilik İkon Kullanıldı)
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${trainer.adi} ${trainer.soyadi}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              trainer.uzmanlik,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // Profil Bilgileri
            ProfileInfoRow(label: 'Telefon', value: trainer.telefon),
            ProfileInfoRow(label: 'Mail Adresi', value: trainer.email),
            ProfileInfoRow(label: 'Adres', value: trainer.adres),
            ProfileInfoRow(label: 'Seviye', value: trainer.seviye),
            ProfileInfoRow(
              label: 'Aktiflik Durumu',
              value: trainer.aktifMi ? 'Aktif' : 'Pasif',
            ),
          ],
        ),
      ),
    );
  }
}

// **Profil Satırı Bileşeni**
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
