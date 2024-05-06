// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginPage({super.key});

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
              hintText: "Username",
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
            hintText: "Password",
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
            loginUser(
              context,
              _usernameController,
              _passwordController,
            );
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 20),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(onPressed: () {}, child: const Text("Forgot password?"));
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Dont have an account? "),
        TextButton(onPressed: () {}, child: const Text("Sign Up"))
      ],
    );
  }

  Future<void> loginUser(
      BuildContext context,
      TextEditingController usernameController,
      TextEditingController passwordController) async {
    Map<String, String> data = {
      'username': usernameController.text,
      'password': passwordController.text
    };

    try {
      var response = await http.post(
        Uri.parse(loginUrl),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        String jsonResponse = json.decode(response.body);
        savePrefs("token", jsonResponse);
        if (await kullaniciBilgileriniGetir(jsonResponse)) {
          Navigator.pushNamed(context, routeEnums[SayfaAdi.anasayfa]!);
        }
        usernameController.clear();
        passwordController.clear();
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı adı veya şifre hatalı'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş yapılırken bir hata oluştu'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yapılırken bir hata oluştu'),
        ),
      );
    }
  }
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

Future<void> savePrefs(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}
