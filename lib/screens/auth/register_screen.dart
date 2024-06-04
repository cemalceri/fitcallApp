// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/regex.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/screens/auth/widgets/register/kullanici_sozlesmesi_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
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
  String _selectedRole = 'Yetişkin';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _isletmeController = TextEditingController();
  final TextEditingController _adiController = TextEditingController();
  final TextEditingController _soyadiController = TextEditingController();
  final TextEditingController _kullaniciAdiController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _sifreTekrarController = TextEditingController();
  final TextEditingController _kimlikNoController = TextEditingController();
  final TextEditingController _cinsiyetController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresController = TextEditingController();
  final TextEditingController _seviyeRengiController = TextEditingController();
  final TextEditingController _uyeTipiController = TextEditingController();
  final TextEditingController _dogumTarihiController = TextEditingController();
  final TextEditingController _tenisGecmisiVarMiController =
      TextEditingController();
  final TextEditingController _dogumYeriController = TextEditingController();
  final TextEditingController _meslekController = TextEditingController();
  final TextEditingController _anneAdiSoyadiController =
      TextEditingController();
  final TextEditingController _anneTelefonController = TextEditingController();
  final TextEditingController _anneMailController = TextEditingController();
  final TextEditingController _anneMeslekController = TextEditingController();
  final TextEditingController _babaAdiSoyadiController =
      TextEditingController();
  final TextEditingController _babaTelefonController = TextEditingController();
  final TextEditingController _babaMailController = TextEditingController();

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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _isletmeController.text.isEmpty
                ? null
                : _isletmeController.text,
            decoration: InputDecoration(
              labelText: 'Kulüp',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.home_max),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _isletmeController.text = newValue ?? '';
              });
            },
            items: <String>['Binay Tenis Akademisi', 'Datça Tenis Akademisi']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen kayıt olmak istediğiniz kulübü seçiniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adiController,
            decoration: InputDecoration(
              labelText: "Adı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen adınızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _soyadiController,
            decoration: InputDecoration(
              labelText: "Soyadı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen soyadınızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _kullaniciAdiController,
            decoration: InputDecoration(
              labelText: "Kullanıcı Adı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person_add),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen kullanıcı adı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _sifreController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Şifre",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen şifrenizi giriniz.";
              } else if (value.length < 6) {
                return "Şifreniz en az 6 karakter olmalıdır.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _sifreTekrarController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Şifre Tekrar",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen şifrenizi tekrar giriniz.";
              } else if (value != _sifreController.text) {
                return "Şifreler uyuşmuyor.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
              controller: _kimlikNoController,
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: "Kimlik No",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.confirmation_number),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                } else if (value.length != 11) {
                  return "Kimlik numarası 11 haneli olmalıdır.";
                }
                return null;
              }),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _cinsiyetController.text.isEmpty
                ? null
                : _cinsiyetController.text,
            decoration: InputDecoration(
              labelText: 'Cinsiyet',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.wc),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _cinsiyetController.text = newValue ?? '';
              });
            },
            items: <String>['Erkek', 'Kadın']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen cinsiyetinizi seçiniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _telefonController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            decoration: InputDecoration(
              labelText: "Telefon",
              hintText: "05551114455",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen telefon numaranızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen bir e-posta adresi girin';
              } else if (!emailValidatorRegExp.hasMatch(value)) {
                return 'Geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adresController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: "Adres",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen adresinizi giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _seviyeRengiController.text.isEmpty
                ? null
                : _seviyeRengiController.text,
            decoration: InputDecoration(
              labelText: 'Seviye Rengi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.palette),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _seviyeRengiController.text = newValue ?? '';
              });
            },
            items: <String>[
              'Kırmızı',
              'Turuncu',
              'Sarı',
              'Yeşil',
              'Yetişkin',
              'Tenis Okulu'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen cinsiyetinizi seçiniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _uyeTipiController.text.isEmpty
                ? null
                : _uyeTipiController.text,
            decoration: InputDecoration(
              labelText: "Üye Tipi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.format_list_numbered),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _uyeTipiController.text = newValue ?? '';
                _selectedRole = newValue!;
              });
            },
            items: <String>['Yetişkin', 'Sporcu']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen üye tipinizi seçiniz';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dogumTarihiController,
            decoration: InputDecoration(
              labelText: "Doğum Tarihi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly:
                true, // Kullanıcı doğrudan tarihi giremesin, tarih seçici kullanmalı.
            onTap: () {
              _selectDate(context);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tenisGecmisiVarMiController,
            decoration: InputDecoration(
              labelText: "Tenis Geçmişi Var Mı?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.sports_tennis),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dogumYeriController,
            decoration: InputDecoration(
              labelText: "Doğum Yeri",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.place),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Yetişkin',
            child: TextFormField(
              controller: _meslekController,
              decoration: InputDecoration(
                labelText: "Meslek",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.work),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _anneAdiSoyadiController,
              decoration: InputDecoration(
                labelText: "Anne Adı Soyadı",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _anneTelefonController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: "Anne Telefon",
                hintText: "05551114455",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _anneMailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Anne Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Eğer değer null veya boş ise geçerli kabul edilir.
                } else if (!emailValidatorRegExp.hasMatch(value)) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null; // Tüm kontrol koşulları sağlandığında null döndürülür ve geçerli kabul edilir.
              },
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _anneMeslekController,
              decoration: InputDecoration(
                labelText: "Anne Meslek",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.work),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _babaAdiSoyadiController,
              decoration: InputDecoration(
                labelText: "Baba Adı Soyadı",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _babaTelefonController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              decoration: InputDecoration(
                labelText: "Baba Telefon",
                hintText: "05551114455",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: _selectedRole == 'Sporcu',
            child: TextFormField(
              controller: _babaMailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Baba Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Eğer değer null veya boş ise geçerli kabul edilir.
                } else if (!emailValidatorRegExp.hasMatch(value)) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null; // Tüm kontrol koşulları sağlandığında null döndürülür ve geçerli kabul edilir.
              },
            ),
          ),
        ],
      ),
    );
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
          onPressed: _isAgree
              ? () {
                  _kayitOl(context).then((value) {
                    if (value) {
                      //7 saniye bekle
                      Future.delayed(const Duration(seconds: 7), () {
                        Navigator.pushNamed(
                            context, routeEnums[SayfaAdi.login]!);
                      });
                    }
                  }).timeout(const Duration(seconds: 3), onTimeout: () {
                    LoadingSpinner.hide(context);
                    uyariGoster(context, 'Hata',
                        'İşlem süresi aşıldı. Lütfen tekrar deneyiniz.');
                  });
                }
              : null,
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
                    UserAgreementWidget(),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  Theme.of(context).primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dogumTarihiController.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  void checkLoginStatus(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      Navigator.pushReplacementNamed(context, routeEnums[SayfaAdi.anasayfa]!);
    }
  }

  Future<bool> _kayitOl(BuildContext context) async {
    LoadingSpinner.show(context, message: 'Kayıt yapılıyor...');
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> formData = formDataOlustur();
      var url = Uri.parse(uyeKaydet);
      var response = await http.post(
        url,
        body: json.encode(formData),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        LoadingSpinner.hide(context);
        uyariGoster(context, 'Kayıt Başarılı',
            'Kayıt işlemi başarıyla tamamlandı. Yönetici onayından sonra giriş yapabilirsiniz.');
        return true;
      } else {
        LoadingSpinner.hide(context);
        // Hata mesajını kullanıcıya göster
        uyariGoster(context, 'Hata',
            'Kayıt işlemi sırasında bir hata oluştu.${response.body}');
      }
    } else {
      LoadingSpinner.hide(context);
      // Form geçerli değilse bir hata mesajı göster
      uyariGoster(context, 'Uyarı', 'Lütfen tüm alanları doldurunuz.');
    }
    return false;
  }

  void uyariGoster(BuildContext context, String baslik, String icerik) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(baslik),
          content: Text(icerik),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> formDataOlustur() {
    Map<String, dynamic> formData = {
      'isletme_id': _isletmeController.text == 'Binay Tenis Akademisi' ? 1 : 2,
      'adi': _adiController.text,
      'soyadi': _soyadiController.text,
      'kullanici_adi': _kullaniciAdiController.text,
      'sifre': _sifreController.text,
      'sifre_tekrar': _sifreTekrarController.text,
      'kimlik_no': _kimlikNoController.text,
      'cinsiyet': _cinsiyetController.text,
      'telefon': _telefonController.text,
      'email': _emailController.text,
      'adres': _adresController.text,
      'seviye_rengi': _seviyeRengiController.text,
      'uye_tipi': _uyeTipiController.text,
      'dogum_tarihi': _dogumTarihiController.text,
      'tenis_gecmisi_var_mi': _tenisGecmisiVarMiController.text,
      'dogum_yeri': _dogumYeriController.text,
      'meslek': _meslekController.text,
      'anne_adi_soyadi': _anneAdiSoyadiController.text,
      'anne_telefon': _anneTelefonController.text,
      'anne_mail': _anneMailController.text,
      'anne_meslek': _anneMeslekController.text,
      'baba_adi_soyadi': _babaAdiSoyadiController.text,
      'baba_telefon': _babaTelefonController.text,
      'baba_mail': _babaMailController.text,
    };
    return formData;
  }
}
