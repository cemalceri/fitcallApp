// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/screens/1_common/3_mobil_app/app_update_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _kullaniciAdiCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  bool _beniHatirla = false;
  bool _yukleniyor = false;

  String? _surumYazi; // vX.Y.Z (build)

  // Güvenli depoda saklanacak anahtarlar
  static const _kRememberUser = 'remember_username';
  static const _kRememberPass = 'remember_password';

  @override
  void initState() {
    super.initState();
    _beniHatirlaYukle();
    _surumYukle();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Sadece zorunlu güncelleme kontrolü
      await GuncellemeKoordinatoru.kontrolVeUygula(context);
      // Güncelleme sonrası otomatik login dene (API'den profil çek)
      await _tryAutoLoginFromApi();
    });
  }

  @override
  void dispose() {
    _kullaniciAdiCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _surumYukle() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final yazi = 'v${info.version} (${info.buildNumber})';
      if (mounted) setState(() => _surumYazi = yazi);
    } catch (_) {
      // Sessiz geç: sürüm okunamazsa gösterme
    }
  }

  Future<void> _beniHatirlaYukle() async {
    // ❗️Tek yerden oku
    final r = await StorageService.beniHatirlaIsaretlenmisMi();
    if (mounted) setState(() => _beniHatirla = r);
  }

  /// Beni hatırla açık ve kayıtlı krediler varsa profilleri **API'den** çeker ve yönlendirir.
  Future<void> _tryAutoLoginFromApi() async {
    final remember = await StorageService.beniHatirlaIsaretlenmisMi();
    if (remember != true) return;

    final u = await SecureStorageService.getValue<String>(_kRememberUser);
    final p = await SecureStorageService.getValue<String>(_kRememberPass);
    if (u == null || u.isEmpty || p == null || p.isEmpty) return;

    setState(() => _yukleniyor = true);
    try {
      final result = await AuthService.fetchMyMembers(u, p);
      final profiller = result.profiller;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
      );
    } catch (_) {
      // oto login sessiz düşsün; kullanıcı manuel giriş yapabilir
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _girisButonunaBasildi() async {
    if (_yukleniyor) return;
    final u = _kullaniciAdiCtrl.text.trim();
    final p = _sifreCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      ShowMessage.error(context, 'Kullanıcı adı / şifre boş olamaz');
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      final result = await AuthService.fetchMyMembers(u, p);
      final profiller = result.profiller;

      // Profilleri lokal saklamak zorunlu değil; istersen referans için tut
      await SecureStorageService.setValue<String>(
        'kullanici_profiller',
        jsonEncode(profiller.map((e) => e.toJson()).toList()),
      );

      // Beni hatırla tercihini ve kredileri yönet
      StorageService.setBeniHatirla(_beniHatirla);
      if (_beniHatirla) {
        await SecureStorageService.setValue<String>(_kRememberUser, u);
        await SecureStorageService.setValue<String>(_kRememberPass, p);
      } else {
        await SecureStorageService.remove(_kRememberUser);
        await SecureStorageService.remove(_kRememberPass);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
      );
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Giriş işlemi başarısız: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _baslik(),
                _girdiAlani(),
                _beniHatirlaKutusu(),
                _sifremiUnuttum(),
                _kayitOl(),
                const SizedBox(height: 8),
                _versiyonBilgisi(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _baslik() => Column(
        children: [
          Image.asset('assets/images/logo.png', width: 200, height: 200),
          const Text("Hoşgeldiniz",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const Text("Giriş için lütfen bilgilerinizi giriniz."),
        ],
      );

  Widget _girdiAlani() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _kullaniciAdiCtrl,
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
            controller: _sifreCtrl,
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
            onPressed: _yukleniyor ? null : _girisButonunaBasildi,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _yukleniyor ? "Bekleyin..." : "Giriş",
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      );

  Widget _beniHatirlaKutusu() => Row(
        children: [
          Checkbox(
            value: _beniHatirla,
            onChanged: (value) async {
              final v = value ?? false;
              setState(() => _beniHatirla = v);
              StorageService.setBeniHatirla(v);
              if (!v) {
                // kapatılırsa kredileri temizle
                await SecureStorageService.remove(_kRememberUser);
                await SecureStorageService.remove(_kRememberPass);
              }
            },
          ),
          const Text("Beni Hatırla"),
        ],
      );

  Widget _sifremiUnuttum() => TextButton(
        onPressed: () {},
        child: const Text("Şifremi Unuttum"),
      );

  Widget _kayitOl() => Row(
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

  Widget _versiyonBilgisi() => Opacity(
        opacity: 0.7,
        child: Text(
          _surumYazi ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      );
}
