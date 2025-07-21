// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:fitcall/common/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:fitcall/services/fcm_service.dart';
import 'profil_sec.dart';

class LoginPage extends StatefulWidget {
  final String? logindenSonraGit;
  const LoginPage({super.key, this.logindenSonraGit});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _beniHatirla = false;

  @override
  void initState() {
    super.initState();
    _loadRememberFlag();
    _checkAutoLogin();
  }

  Future<void> _loadRememberFlag() async {
    final remember = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (remember != null) setState(() => _beniHatirla = remember);
  }

/* -------------------------------------------------------------
   _checkAutoLogin  (Beni Hatırla senaryosunu tek/multi profil için yönetir)
------------------------------------------------------------- */
  Future<void> _checkAutoLogin() async {
    final remember = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (remember != true) return;

// Saklanan profil(ler)i oku → hem tek obje hem liste senaryosunu destekle
    final listJson =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (listJson == null) return;

    final dynamic decoded = jsonDecode(listJson);
    final List<KullaniciProfilModel> members = (decoded is List
            ? decoded
            : [decoded])
        .map((e) => KullaniciProfilModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final bool multiple = members.length > 1;
    final rel = multiple
        ? members.firstWhere((m) => m.anaHesap, orElse: () => members.first)
        : members.first;

    LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
    final role = await AuthService.loginUser(context, rel);
    LoadingSpinner.hide(context);
    if (role == null) return;

    if (multiple) {
      // FCM cihaz kaydı
      final token = await SecureStorageService.getValue<String>('token');
      if (token != null) {
        await sendFCMDevice(token, isMainAccount: rel.anaHesap);
      }

      // Profil Seç ekranına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilSecPage(
            kullaniciProfilList: members,
            logindenSonraGit: widget.logindenSonraGit,
          ),
        ),
      );
    } else {
      _navigateAfterLogin(role);
    }
  }

/* -------------------------------------------------------------
   _onLoginPressed  (Manuel giriş butonu)
------------------------------------------------------------- */
  Future<void> _onLoginPressed() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
    final members =
        await AuthService.fetchMyMembers(context, username, password);
    LoadingSpinner.hide(context);

    if (members == null) {
      ShowMessage.error(
          context, 'Kullanıcı adı veya şifre hatalı. Lütfen tekrar deneyin.');
      return;
    }
    if (members.isEmpty) {
      ShowMessage.error(
          context, 'Profil bulunamadı. Lütfen yönetici ile iletişime geçin.');
      return;
    }
    if (members.any((m) => m.gruplar.isEmpty)) {
      ShowMessage.error(context,
          'Kullanıcınız henüz yetkilendirilmemiş. Lütfen yönetici ile iletişime geçin.');
      return;
    }

    /* Her durumda: profil listesini ve flag’i sakla */
    await SecureStorageService.setValue<String>('kullanici_profiller',
        jsonEncode(members.map((e) => e.toJson()).toList()));

    /* ---------- TEK PROFİL ---------- */
    if (members.length == 1) {
      final rel = members.first;

      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final role = await AuthService.loginUser(context, rel);
      LoadingSpinner.hide(context);

      if (role != null) _navigateAfterLogin(role);
      return;
    }

    /* ---------- BİRDEN FAZLA PROFİL ---------- */
    if (_beniHatirla) {
      final rel =
          members.firstWhere((m) => m.anaHesap, orElse: () => members.first);

      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      await AuthService.loginUser(context, rel);
      LoadingSpinner.hide(context);

      final token = await SecureStorageService.getValue<String>('token');
      if (token != null) {
        await sendFCMDevice(token, isMainAccount: rel.anaHesap);
      }
    }

    // Profil Seç ekranına geç
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilSecPage(
          kullaniciProfilList: members,
          logindenSonraGit: widget.logindenSonraGit,
        ),
      ),
    );
  }

  void _navigateAfterLogin(Roller role) {
    if (widget.logindenSonraGit != null) {
      Navigator.pushNamedAndRemoveUntil(
          context, widget.logindenSonraGit!, (route) => false);
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
    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _header(),
                _inputField(),
                _rememberMeCheckbox(),
                _forgotPassword(),
                _signup(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Column(
        children: [
          Image.asset('assets/images/logo.png', width: 200, height: 200),
          const Text("Hoşgeldiniz",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const Text("Giriş için lütfen bilgilerinizi giriniz."),
        ],
      );

  Widget _inputField() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: "Kullanıcı Adı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor:
                  Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: "Şifre",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor:
                  Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
              filled: true,
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _onLoginPressed,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Giriş", style: TextStyle(fontSize: 20)),
          ),
        ],
      );

  Widget _rememberMeCheckbox() => Row(
        children: [
          Checkbox(
            value: _beniHatirla,
            onChanged: (value) {
              setState(() {
                _beniHatirla = value!;
                SecureStorageService.setValue<bool>(
                    'beni_hatirla', _beniHatirla);
              });
            },
          ),
          const Text("Beni Hatırla"),
        ],
      );

  Widget _forgotPassword() => TextButton(
        onPressed: () {},
        child: const Text("Şifremi unuttum!"),
      );

  Widget _signup() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Hesabın yok mu? "),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, routeEnums[SayfaAdi.kayitol]!);
            },
            child: const Text("Kayıt ol"),
          ),
        ],
      );
}
