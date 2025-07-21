// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:fitcall/services/fcm_service.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';

class ProfilSecPage extends StatelessWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  final String? logindenSonraGit;

  const ProfilSecPage({
    super.key,
    required this.kullaniciProfilList,
    this.logindenSonraGit,
  });

  Future<void> _onMemberTap(
      BuildContext context, KullaniciProfilModel rel) async {
    // 4) Login metodu ile token al ve rolü belirle
    LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
    final role = await AuthService.loginUser(context, rel);
    LoadingSpinner.hide(context);
    if (role == null) return;

    // 3) Cihaz kaydı (ana hesap bilgisine göre)
    final token = await SecureStorageService.getValue<String>('token');
    if (token != null) {
      await sendFCMDevice(token, isMainAccount: rel.anaHesap);
    }
    // 5) Yönlendirme
    if (logindenSonraGit != null) {
      Navigator.pushNamedAndRemoveUntil(
          context, logindenSonraGit!, (route) => false);
    } else if (role == Roller.antrenor) {
      Navigator.pushReplacementNamed(
          context, routeEnums[SayfaAdi.antrenorAnasayfa]!);
    } else if (role == Roller.uye) {
      Navigator.pushReplacementNamed(
          context, routeEnums[SayfaAdi.uyeAnasayfa]!);
    } else if (role == Roller.yonetici) {
      Navigator.pushReplacementNamed(
          context, routeEnums[SayfaAdi.yoneticiAnasayfa]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Seç")),
      body: ListView.builder(
        itemCount: kullaniciProfilList.length,
        itemBuilder: (ctx, i) {
          final rel = kullaniciProfilList[i];
          final adi = rel.uye?.adi ?? rel.antrenor?.adi ?? rel.user.firstName;
          final soyadi =
              rel.uye?.soyadi ?? rel.antrenor?.soyadi ?? rel.user.lastName;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text("$adi $soyadi"),
              onTap: () => _onMemberTap(context, rel),
            ),
          );
        },
      ),
    );
  }
}
