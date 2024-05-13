import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'widgets/register_input_widget.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {
  bool _isAgree = false;
  Map<String, dynamic>? formData;

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
                _checkAgreement(context),
                _signin(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _header(context) {
    return const Column(
      children: [
        Text(
          "Hoşgeldiniz",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Giriş için lütfen bilgilerinizi giriniz."),
      ],
    );
  }

  _inputField(context) {
    return RegisterInputWidget(
        key: UniqueKey(),
        formVerileriGetir: (gelenVeri) => {
              setState(() {
                formData = gelenVeri;
              })
            });
  }

  _checkAgreement(context) {
    return Column(
      children: <Widget>[
        CheckboxListTile(
          title: const Text('Kullanıcı Sözleşmesini Kabul Ediyorum'),
          value: _isAgree,
          onChanged: (bool? newValue) {
            setState(() {
              _isAgree = newValue!;
            });
          },
          subtitle: InkWell(
            onTap: _showTermsDialog,
            child: const Text(
              'Kullanıcı Sözleşmesini Oku',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isAgree ? () => _kayitOl(context) : null,
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "Kayıt Ol",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  _showTermsDialog() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Kullanıcı Sözleşmesi'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Burada kullanıcı sözleşmesinin metni yer alacak.'),
                    // Uzun metinler için daha fazla Text widget'ı ekleyebilirsiniz.
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Kapat'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  _signin(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Hesabın var mı? "),
        TextButton(
            onPressed: () {
              Navigator.pushNamed(context, routeEnums[SayfaAdi.login]!);
            },
            child: const Text("Giriş yap"))
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

  void _kayitOl(BuildContext? context) async {
    if (formData == null) {
      return;
    }
  }
}
