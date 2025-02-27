// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/windgets/spinner_widgets.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:flutter/material.dart';

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

  Future<void> _checkAutoLogin() async {
    bool? remember = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (remember == true) {
      String? savedUsername =
          await SecureStorageService.getValue<String>('username');
      String? savedPassword =
          await SecureStorageService.getValue<String>('password');
      if (savedUsername != null && savedPassword != null) {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        setState(() {
          _beniHatirla = true;
        });
        LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
        AuthService.loginUser(context, savedUsername, savedPassword)
            .then((role) async {
          LoadingSpinner.hide(context);
          _navigateAfterLogin(role);
        });
      }
    }
  }

  void _navigateAfterLogin(String? role) async {
    // Eğer pendingTarget belirlenmişse, login işleminden sonra o sayfaya yönlendir.
    if (widget.logindenSonraGit != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.logindenSonraGit!,
        (route) => true,
      );
    } else if (role == "antrenor") {
      Navigator.pushReplacementNamed(
          context, routeEnums[SayfaAdi.antrenorAnasayfa]!);
    } else if (role == "uye") {
      Navigator.pushReplacementNamed(
          context, routeEnums[SayfaAdi.uyeAnasayfa]!);
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
                _header(context),
                _inputField(context),
                _rememberMeCheckbox(),
                _forgotPassword(context),
                _signup(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 200,
          height: 200,
        ),
        const Text(
          "Hoşgeldiniz",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        const Text("Giriş için lütfen bilgilerinizi giriniz."),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
              hintText: "Kullanıcı Adı",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              fillColor:
                  Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
              filled: true,
              prefixIcon: const Icon(Icons.person)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: "Şifre",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor:
                Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
            filled: true,
            prefixIcon: const Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
            AuthService.loginUser(
                    context, _usernameController.text, _passwordController.text)
                .then((role) async {
              LoadingSpinner.hide(context);
              _navigateAfterLogin(role);
            });
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "Giriş",
            style: TextStyle(fontSize: 20),
          ),
        )
      ],
    );
  }

  _rememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _beniHatirla,
          onChanged: (value) {
            setState(() {
              _beniHatirla = value!;
              SecureStorageService.setValue<bool>('beni_hatirla', _beniHatirla);
            });
          },
        ),
        const Text("Beni Hatırla"),
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(onPressed: () {}, child: const Text("Şifremi unuttum!"));
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Hesabın yok mu? "),
        TextButton(
            onPressed: () {
              Navigator.pushNamed(context, routeEnums[SayfaAdi.kayitol]!);
            },
            child: const Text("Kayıt ol"))
      ],
    );
  }
}
