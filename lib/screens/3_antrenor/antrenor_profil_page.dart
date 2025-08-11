import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';

class AntrenorProfilPage extends StatelessWidget {
  const AntrenorProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AntrenorModel?>(
      future: AuthService.antrenorBilgileriniGetir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else {
          if (snapshot.data != null) {
            AntrenorModel antrenor = snapshot.data!;
            return AntrenorProfilWidget(antrenor: antrenor);
          } else {
            return const LoginPage();
          }
        }
      },
    );
  }
}

class AntrenorProfilWidget extends StatelessWidget {
  const AntrenorProfilWidget({super.key, required this.antrenor});

  final AntrenorModel antrenor;

  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('0xFF$hexColor'));
    } else if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrenör Profili')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
              '${antrenor.adi} ${antrenor.soyadi}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ProfileInfoRow(
                label: 'Telefon', value: antrenor.telefon ?? 'Bilinmiyor'),
            ProfileInfoRow(
                label: 'Mail Adresi', value: antrenor.ePosta ?? 'Bilinmiyor'),
            ProfileInfoRow(
              label: 'Renk',
              value: '',
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorFromHex(antrenor.renk),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? child;

  const ProfileInfoRow(
      {super.key, required this.label, required this.value, this.child});

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
            child: child ??
                Container(
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
