// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:fitcall/services/fcm_service.dart';
import 'profil_sec.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _beniHatirla = false;

  @override
  void initState() {
    super.initState();
    _loadRememberFlag();
    _checkAutoLogin();
  }

  Future<void> _loadRememberFlag() async {
    final r = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (r != null) setState(() => _beniHatirla = r);
  }

  /* ====================== OTOMATİK GİRİŞ ====================== */
  Future<void> _checkAutoLogin() async {
    if (await SecureStorageService.getValue<bool>('beni_hatirla') != true) {
      return;
    }

    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null) return;

    final profiles = (jsonDecode(jsonStr) as List)
        .map<KullaniciProfilModel>(
            (e) => KullaniciProfilModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (profiles.length > 1) {
      // Çoklu profil --> seçim ekranı
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProfilSecPage(
                  profiles,
                )),
      );
      return;
    }

    // Tek profil --> doğrudan login
    await _loginAndNavigate(profiles.first);
  }

  /* ====================== MANUEL GİRİŞ ====================== */
  Future<void> _onLoginPressed() async {
    final u = _username.text.trim();
    final p = _password.text;
    if (u.isEmpty || p.isEmpty) {
      ShowMessage.error(context, 'Kullanıcı adı / şifre boş olamaz');
      return;
    }

    final profiles =
        await AuthService.fetchMyMembers(u, p).catchError((err) async {
      ShowMessage.error(
          context, err is ApiException ? err.message : 'Bilinmeyen hata: $err');
      return null;
    });
    if (profiles == null || profiles.isEmpty) {
      ShowMessage.error(context, 'Profil bulunamadı.');
      return;
    }

    await SecureStorageService.setValue<String>(
      'kullanici_profiller',
      jsonEncode(
        profiles.map((e) => e.toJson()).toList(), // ← .toList() eklendi
      ),
    );
    if (profiles.length == 1) {
      await _loginAndNavigate(profiles.first);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProfilSecPage(
                  profiles,
                )),
      );
    }
  }

  /* ====================== PROFİL İLE LOGIN ====================== */
  Future<void> _loginAndNavigate(KullaniciProfilModel profil) async {
    Roller role;
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      role = await AuthService.loginUser(profil); // token yazar
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
      return;
    } finally {
      LoadingSpinner.hide(context);
    }

    final tkn = await SecureStorageService.getValue<String>('token');
    if (tkn != null) await sendFCMDevice(tkn, isMainAccount: profil.anaHesap);

    await _navigateAfterLogin(role);
  }

  /* ====================== ORTAK YÖNLENDİRME ====================== */
  Future<void> _navigateAfterLogin(Roller role) async {
    // a) pendingAction
    final p = await PendingActionStore.instance.take();
    if (p != null) {
      switch (p.type) {
        case PendingActionType.dersTeyit:
          Navigator.pushNamedAndRemoveUntil(
              context, routeEnums[SayfaAdi.dersTeyit]!, (_) => false,
              arguments: p.data);
          return;
        case PendingActionType.bildirimListe:
          Navigator.pushNamedAndRemoveUntil(
              context, routeEnums[SayfaAdi.bildirimler]!, (_) => false);
          return;
      }
    }

    // b) rol ana sayfası
    switch (role) {
      case Roller.antrenor:
        Navigator.pushNamedAndRemoveUntil(
            context, routeEnums[SayfaAdi.antrenorAnasayfa]!, (_) => false);
        break;
      case Roller.yonetici:
        Navigator.pushNamedAndRemoveUntil(
            context, routeEnums[SayfaAdi.yoneticiAnasayfa]!, (_) => false);
        break;
      default:
        Navigator.pushNamedAndRemoveUntil(
            context, routeEnums[SayfaAdi.uyeAnasayfa]!, (_) => false);
    }
  }

  /* ------------------ UI (değişmedi) ------------------ */
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

  /* ----- UI bileşenleri (AYNEN KALDI) ----- */
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
            controller: _username,
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
            controller: _password,
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
                _beniHatirla = value ?? false;
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
