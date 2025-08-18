// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/screens/1_common/3_mobil_app/app_update_page.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/fcm_service.dart';

// 👇 EKLENDİ: Event kontrolü için
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';

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

  @override
  void initState() {
    super.initState();
    _beniHatirlaYukle();
    _otomatikGirisKontrol();
    GuncellemeKoordinatoru.kontrolVeUygula(context);
  }

  @override
  void dispose() {
    _kullaniciAdiCtrl.dispose();
    _sifreCtrl.dispose();
    super.dispose();
  }

  Future<void> _beniHatirlaYukle() async {
    final r = await SecureStorageService.getValue<bool>('beni_hatirla');
    if (mounted) setState(() => _beniHatirla = r ?? false);
  }

  Future<void> _otomatikGirisKontrol() async {
    final hatirla = await StorageService.beniHatirlaIsaretlenmisMi();
    if (hatirla != true) return;

    // Geçerli token varsa direkt yönlendir
    if (await StorageService.tokenGecerliMi()) {
      final s = await SecureStorageService.getValue<String>('gruplar');
      List<dynamic> gruplar = [];
      if (s != null) gruplar = jsonDecode(s);

      Roller role = Roller.uye;
      if (gruplar.contains(Roller.antrenor.name)) {
        role = Roller.antrenor;
      } else if (gruplar.contains(Roller.yonetici.name)) {
        role = Roller.yonetici;
      } else if (gruplar.contains(Roller.cafe.name)) {
        role = Roller.cafe;
      }

      if (!mounted) return;
      await NavigationHelper.redirectAfterLogin(context, role);
      return;
    }

    // Token yoksa profilleri API’den tekrar çek
    try {
      final u = await SecureStorageService.getValue<String>('kullanici_adi');
      final p = await SecureStorageService.getValue<String>('sifre');
      if (u == null || p == null) return;

      final profiller = await AuthService.fetchMyMembers(u, p);
      if (profiller.isEmpty) return;

      await SecureStorageService.setValue<String>(
        'kullanici_profiller',
        jsonEncode(profiller.map((e) => e.toJson()).toList()),
      );

      // 👇 AKTİF EVENT KONTROLÜ: varsa direkt Event QR sayfasına
      try {
        final int uid = profiller.first.user.id;
        final ApiResult<EventModel?> evRes =
            await QrEventApiService.getirEventAktifApi(userId: uid);
        final aktifEvent = evRes.data; // null => yok
        if (aktifEvent != null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => EventQrPage(userId: uid)),
          );
          return;
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        ShowMessage.error(context, e.message);
      } catch (e) {
        if (!mounted) return;
        ShowMessage.error(context, 'Hata: $e');
      }

      if (profiller.length > 1) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
        );
        return;
      }

      await _profilIleGiris(profiller.first);
    } catch (e) {
      // Sessiz geç, login ekranında kalır
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
      final profiller = await AuthService.fetchMyMembers(u, p);
      if (profiller.isEmpty) {
        ShowMessage.error(context, 'Profil bulunamadı.');
        return;
      }

      await SecureStorageService.setValue<String>(
        'kullanici_profiller',
        jsonEncode(profiller.map((e) => e.toJson()).toList()),
      );
      await SecureStorageService.setValue<String>('kullanici_adi', u);
      await SecureStorageService.setValue<String>('sifre', p);

      // 👇 AKTİF EVENT KONTROLÜ: varsa direkt Event QR sayfasına
      try {
        final int uid = profiller.first.user.id;
        final ApiResult<EventModel?> evRes =
            await QrEventApiService.getirEventAktifApi(userId: uid);
        final aktifEvent = evRes.data;
        if (aktifEvent != null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => EventQrPage(userId: uid)),
          );
          return;
        }
      } catch (_) {}

      if (profiller.length == 1) {
        await _profilIleGiris(profiller.first);
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
        );
      }
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Bilinmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _profilIleGiris(KullaniciProfilModel profil) async {
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final rol = await AuthService.loginUser(profil);

      await sendFCMDevice(isMainAccount: profil.anaHesap);

      if (!mounted) return;
      await NavigationHelper.redirectAfterLogin(context, rol);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } finally {
      LoadingSpinner.hide(context);
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
                _baslik(),
                _girdiAlani(),
                _beniHatirlaKutusu(),
                _sifremiUnuttum(),
                _kayitOl(),
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
            onChanged: (v) {
              setState(() => _beniHatirla = v ?? false);
              SecureStorageService.setValue<bool>('beni_hatirla', _beniHatirla);
            },
          ),
          const Text("Beni Hatırla"),
        ],
      );

  Widget _sifremiUnuttum() => TextButton(
        onPressed: () {},
        child: const Text("Şifremi unuttum!"),
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
}
