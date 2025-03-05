// lib/pages/login_page.dart
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
    _checkAutoLogin();
  }

  /// Eğer daha önce bir üye seçilmiş ve "Beni Hatırla" işaretliyse,
  /// doğrudan o relation ile loginUser çağırır.
  Future<void> _checkAutoLogin() async {
    bool? remember = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (remember == true) {
      String? relJson =
          await SecureStorageService.getValue<String>('uye_kullanici_relation');
      if (relJson != null) {
        final rel = KullaniciProfilModel.fromJson(jsonDecode(relJson));

        LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
        final role = await AuthService.loginUser(context, rel);
        LoadingSpinner.hide(context);

        if (role != null) {
          _navigateAfterLogin(role);
        }
      }
    }
  }

  /// Login butonuna basıldığında; önce üyeleri fetch eder,
  /// birden çok üyeyse seçim sayfasına, tek üyeyse direkt loginUser ile ilerler.
  Future<void> _onLoginPressed() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
    final members = await AuthService.fetchMyMembers(
      context,
      username,
      password,
    );
    LoadingSpinner.hide(context);

    if (members == null) {
      // Kullanıcı adı veya şifre hatalı
      ShowMessage.error(
        context,
        'Kullanıcı adı veya şifre hatalı. Lütfen tekrar deneyin.',
      );
      return;
    }
    if (members.any((m) => m.gruplar.isEmpty)) {
      // Kullanıcı adı veya şifre hatalı
      ShowMessage.error(
        context,
        'Kullanıcınız henüz yetkilendirilmemiş. Lütfen yönetici ile iletişime geçin.',
      );
      return;
    }
    if (members.any((m) => m.uye == null && m.antrenor == null)) {
      ShowMessage.error(
        context,
        'Kullanıcınıza bağlı herhangi bir profil bulunamadı. Lütfen yönetici ile iletişime geçin.',
      );
      return;
    }
    if (members.length == 1) {
      // Tek bir üye varsa, direkt loginUser ile ilerle
      final rel = members.first;
      // Seçilen relation'ı kaydet (auto-login için)
      await SecureStorageService.setValue<String>(
        'uye_kullanici_relation',
        jsonEncode(rel.toJson()),
      );
    }

    if (members.length > 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilSecPage(
            relations: members,
            logindenSonraGit: widget.logindenSonraGit,
          ),
        ),
      );
    } else if (members.isNotEmpty) {
      final rel = members.first;
      // Seçilen relation'ı kaydet (auto-login için)
      await SecureStorageService.setValue<String>(
        'uye_kullanici_relation',
        jsonEncode(rel.toJson()),
      );

      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final role = await AuthService.loginUser(context, rel);
      LoadingSpinner.hide(context);

      if (role != null) {
        _navigateAfterLogin(role);
      }
    }
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
