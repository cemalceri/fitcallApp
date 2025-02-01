import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/user_model.dart';
import 'package:fitcall/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'widgets/kullanici_profil_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: kullaniciBilgileriniGetir(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
        } else {
          if (snapshot.data != null) {
            UserModel kullanici = snapshot.data!;
            return KullaniciProfilWidget(kullanici: kullanici);
          } else {
            return const LoginPage();
          }
        }
      },
    );
  }
}
