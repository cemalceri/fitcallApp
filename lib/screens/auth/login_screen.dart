// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    checkLoginStatus(context);
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
          width: 200, // Resmin genişliği
          height: 200, // Resmin yüksekliği
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
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
            fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
            loginUser(
              context,
              _usernameController.text,
              _passwordController.text,
            ).then((value) {
              LoadingSpinner.hide(context);
              if (value) {
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

  Future<bool> kullaniciBilgileriniGetir(String token) async {
    try {
      var response = await http.post(
        Uri.parse(getSporcu),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        savePrefs("kullanici", utf8.decode(response.bodyBytes));
        return true;
      } else {
        print('Kullanıcı bilgileri getirilemedi');
        return false;
      }
    } catch (e) {
      print("Kullanıcı bilgileri getirilirken bir hata oluştu: $e");
      return false;
    }
  }

  void checkLoginStatus(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.anasayfa]!);
    }
  }
}
