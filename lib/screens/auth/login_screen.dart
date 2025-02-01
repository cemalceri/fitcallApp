// login_page.dart

// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _beniHatirla = false;

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
            loginUser(
                    context, _usernameController.text, _passwordController.text)
                .then((role) {
              LoadingSpinner.hide(context);
              if (role == "antrenor") {
                // Antrenör ise antrenör ana sayfasına yönlendir:
                Navigator.pushNamed(
                    context, routeEnums[SayfaAdi.antrenorAnasayfa]!);
              } else if (role == "uye") {
                // Üye ise mevcut anasayfaya yönlendir:
                Navigator.pushNamed(context, routeEnums[SayfaAdi.anasayfa]!);
              }
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
          onChanged: (bool? value) {
            setState(() {
              _beniHatirla = value!;
              savePrefsBool('beni_hatirla', _beniHatirla);
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
