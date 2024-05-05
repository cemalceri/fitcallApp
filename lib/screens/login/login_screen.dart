import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: EdgeInsets.all(24),
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
        Text(
          "Hoşgeldiniz",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Giriş için lütfen bilgilerinizi giriniz."),
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
              prefixIcon: Icon(Icons.person)),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
            filled: true,
            prefixIcon: Icon(Icons.person),
          ),
          obscureText: true,
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            loginUser(
              context,
              _usernameController,
              _passwordController,
            );
          },
          style: ElevatedButton.styleFrom(
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            "Login",
            style: TextStyle(fontSize: 20),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(onPressed: () {}, child: Text("Forgot password?"));
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Dont have an account? "),
        TextButton(onPressed: () {}, child: Text("Sign Up"))
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
        usernameController.clear();
        passwordController.clear();
        savePrefs("token", jsonResponse);
        if (await kullaniciBilgileriniGetir(jsonResponse)) {
          Navigator.pushNamed(context, routeEnums[SayfaAdi.anasayfa]!);
        }
      } else {
        print("Hata: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("İstek yapılırken bir hata oluştu: $e");
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
      savePrefs("kullanici", response.body);
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
