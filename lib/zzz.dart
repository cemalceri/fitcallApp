import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileInfoRow(label: 'Adı Soyadı', value: 'John Doe'),
            ProfileInfoRow(label: 'Telefon', value: '555 123 4567'),
            ProfileInfoRow(label: 'Mail Adresi', value: 'john.doe@example.com'),
            ProfileInfoRow(
                label: 'Adres', value: '123 Main Street, City, Country'),
            ProfileInfoRow(label: 'Üye Numarası', value: '123456789'),
            ProfileInfoRow(label: 'Aktiflik Durumu', value: 'Aktif'),
            ProfileInfoRow(label: 'Seviye', value: 'Gold'),
          ],
        ),
      ),
    );
  }
}

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
