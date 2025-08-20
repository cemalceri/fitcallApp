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
// PendingAction entegrasyonu
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';

import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1) Zorunlu güncelleme kontrolü (gerekirse sayfa açılır ve akış burada bitmeli)
      await GuncellemeKoordinatoru.kontrolVeUygula(context);
      if (!mounted) return;

      // 2) Güncelleme kapısı geçildiyse otomatik giriş akışı
      await _otomatikGirisKontrol();
    });
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

  /// Profiller listesi içinden veya storage’dan mantıklı bir userId üret.
  Future<int?> _tahminiUserIdAl({List<KullaniciProfilModel>? profiller}) async {
    if (profiller != null && profiller.isNotEmpty) {
      return profiller.first.user.id;
    }
    // Olası fallback anahtarları (proje tarafında varsa)
    final candidates = ['user_id', 'kullanici_id', 'uid'];
    for (final k in candidates) {
      final v = await SecureStorageService.getValue<int>(k);
      if (v != null && v > 0) return v;
    }
    return null;
  }

  /// PendingAction varsa önce onu aç.
  Future<bool> _handlePendingAction() async {
    try {
      final action = await PendingActionStore.instance.take();
      if (action == null) return false;
      if (!mounted) return true;
      switch (action.type) {
        case PendingActionType.dersTeyit:
          await Navigator.pushNamed(context, routeEnums[SayfaAdi.dersTeyit]!,
              arguments: action.data);
          break;
        case PendingActionType.bildirimListe:
          await Navigator.pushNamed(context, routeEnums[SayfaAdi.bildirimler]!);
          break;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Aktif event varsa QR sayfasına gider, true döner.
  Future<bool> _aktifEventVarmiGit(int? uid) async {
    final stored = await SecureStorageService.getValue<int>('user_id');
    final userId = uid ?? stored;
    if (userId == null || userId <= 0) return false;
    try {
      final ApiResult<EventModel?> evRes =
          await QrEventApiService.getirEventAktifApi(userId: userId);
      final aktifEvent = evRes.data;
      if (aktifEvent == null) return false;

      if (!mounted) return false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EventQrPage(userId: userId)),
      );
      return true;
    } catch (_) {
      // sessiz geç
    }
    return false;
  }

  Future<void> _otomatikGirisKontrol() async {
    final hatirla = await StorageService.beniHatirlaIsaretlenmisMi();
    if (hatirla != true) return;

    // Token geçerliyse: rolü belirle (rol boş olabilir → rolsüz)
    if (await StorageService.tokenGecerliMi()) {
      // --- PROFİLLERİ HER ZAMAN API'DEN ÇEKMEYE ÇALIŞ ---
      List<KullaniciProfilModel> profiller = [];
      try {
        final u = await SecureStorageService.getValue<String>('kullanici_adi');
        final p = await SecureStorageService.getValue<String>('sifre');
        if (u != null && p != null) {
          profiller = await AuthService.fetchMyMembers(u, p);
          await SecureStorageService.setValue<String>(
            'kullanici_profiller',
            jsonEncode(profiller.map((e) => e.toJson()).toList()),
          );
        } else {
          // Son çare: eldeki cache
          final s = await SecureStorageService.getValue<String>(
              'kullanici_profiller');
          if (s != null) {
            final arr = (jsonDecode(s) as List);
            profiller = arr
                .map((e) =>
                    KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        }
      } catch (_) {/* ignore */}

      // 0) PendingAction varsa önce onu aç
      await _handlePendingAction();

      // 1) Aktif event varsa direkt QR
      final uid = await _tahminiUserIdAl(profiller: profiller);
      if (await _aktifEventVarmiGit(uid)) return;

      // 2) Event yoksa: profil akışı
      if (profiller.isNotEmpty) {
        if (profiller.length > 1) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
          );
          return;
        }

        // Tek profil: rolsüz ise anasayfaya geçmeyelim
        final p = profiller.first;
        final gr = p.gruplar;
        if (gr.isEmpty ||
            (!gr.contains(Roller.antrenor.name) &&
                !gr.contains(Roller.uye.name) &&
                !gr.contains(Roller.yonetici.name) &&
                !gr.contains(Roller.cafe.name))) {
          if (!mounted) return;
          ShowMessage.error(context, 'Aktif etkinlik bulunamadı.');
          return;
        }
        await _profilIleGiris(p);
        return;
      }

      // 3) Hâlâ profil yoksa: rolsüz ve aktif event de yok → hata göster
      if (!mounted) return;
      ShowMessage.error(context, 'Aktif etkinlik bulunamadı.');
      return;
    }

    // Token yoksa profilleri API’den tekrar çek ve aynı akışı uygula
    try {
      final u = await SecureStorageService.getValue<String>('kullanici_adi');
      final p = await SecureStorageService.getValue<String>('sifre');
      if (u == null || p == null) return;

      setState(() => _yukleniyor = true);
      try {
        // HER ZAMAN API'DEN ÇEK
        final profiller = await AuthService.fetchMyMembers(u, p);
        await SecureStorageService.setValue<String>(
          'kullanici_profiller',
          jsonEncode(profiller.map((e) => e.toJson()).toList()),
        );
        await SecureStorageService.setValue<String>('kullanici_adi', u);
        await SecureStorageService.setValue<String>('sifre', p);

        // 0) PendingAction varsa önce onu aç
        await _handlePendingAction();

        // 1) Aktif event kontrolü (profil yoksa da userId tahmin etmeye çalış)
        final uid = await _tahminiUserIdAl(profiller: profiller);
        if (await _aktifEventVarmiGit(uid)) return;

        // 2) Event yoksa profil akışı
        if (profiller.isEmpty) {
          ShowMessage.error(context, 'Profil bulunamadı.');
          return;
        }
        if (profiller.length > 1) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
          );
          return;
        }
        final pModel = profiller.first;
        final gr = pModel.gruplar;
        if (gr.isEmpty ||
            (!gr.contains(Roller.antrenor.name) &&
                !gr.contains(Roller.uye.name) &&
                !gr.contains(Roller.yonetici.name) &&
                !gr.contains(Roller.cafe.name))) {
          ShowMessage.error(context, 'Aktif etkinlik bulunamadı.');
          return;
        }
        await _profilIleGiris(pModel);
        return;
      } finally {
        if (mounted) setState(() => _yukleniyor = false);
      }
    } catch (_) {/* ignore */}
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
      // HER ZAMAN API'DEN ÇEK
      final profiller = await AuthService.fetchMyMembers(u, p);
      await SecureStorageService.setValue<String>(
        'kullanici_profiller',
        jsonEncode(profiller.map((e) => e.toJson()).toList()),
      );
      await SecureStorageService.setValue<String>('kullanici_adi', u);
      await SecureStorageService.setValue<String>('sifre', p);

      // 0) PendingAction varsa önce onu aç
      await _handlePendingAction();

      // 1) Aktif event kontrolü (profil yoksa da userId tahmin etmeye çalış)
      final uid = await _tahminiUserIdAl(profiller: profiller);
      if (await _aktifEventVarmiGit(uid)) return;

      // 2) Event yoksa profil akışı
      if (profiller.isEmpty) {
        ShowMessage.error(context, 'Profil bulunamadı.');
        return;
      }
      if (profiller.length > 1) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
        );
        return;
      }
      final pModel = profiller.first;
      final gr = pModel.gruplar;
      if (gr.isEmpty ||
          (!gr.contains(Roller.antrenor.name) &&
              !gr.contains(Roller.uye.name) &&
              !gr.contains(Roller.yonetici.name) &&
              !gr.contains(Roller.cafe.name))) {
        ShowMessage.error(context, 'Aktif etkinlik bulunamadı.');
        return;
      }
      await _profilIleGiris(pModel);
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              setState(() => _beniHatirla = value ?? false);
              await StorageService.setBeniHatirla(_beniHatirla);
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
}
