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
  bool _sifreGizli = true;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildGlassContainer(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(isDark),
          const SizedBox(height: 32),
          _buildTitle(isDark),
          const SizedBox(height: 8),
          _buildSubtitle(isDark),
          const SizedBox(height: 32),
          _buildInputFields(isDark),
          const SizedBox(height: 16),
          _buildRememberMe(isDark),
          const SizedBox(height: 24),
          _buildLoginButton(isDark),
          const SizedBox(height: 16),
          _buildLinks(isDark),
          const SizedBox(height: 24),
          _buildVersion(isDark),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        width: 100,
        height: 100,
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Text(
      "Hoşgeldiniz",
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return Text(
      "Giriş için lütfen bilgilerinizi giriniz",
      style: TextStyle(
        fontSize: 15,
        color: isDark
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFF64748B),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInputFields(bool isDark) {
    return Column(
      children: [
        // Kullanıcı Adı
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _kullaniciAdiCtrl,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: "Kullanıcı Adı",
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Şifre
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _sifreCtrl,
            obscureText: _sifreGizli,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: "Şifre",
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _sifreGizli
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _sifreGizli = !_sifreGizli;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMe(bool isDark) {
    return Row(
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: _beniHatirla,
            onChanged: (value) async {
              final v = value ?? false;
              setState(() => _beniHatirla = v);
              StorageService.setBeniHatirla(v);
              if (!v) {
                await SecureStorageService.remove(_kRememberUser);
                await SecureStorageService.remove(_kRememberPass);
              }
            },
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return isDark ? Colors.white : const Color(0xFF1E293B);
              }
              return isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade300;
            }),
            checkColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "Beni Hatırla",
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _yukleniyor ? null : _girisButonunaBasildi,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
          foregroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          disabledBackgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.grey.shade400,
          elevation: 0,
          shadowColor: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _yukleniyor
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                  ),
                ),
              )
            : const Text(
                "Giriş Yap",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildLinks(bool isDark) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, routeEnums[SayfaAdi.sifremiUnuttum]!);
          },
          child: Text(
            "Şifremi Unuttum",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hesabın yok mu? ",
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF64748B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, routeEnums[SayfaAdi.kayitol]!);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                "Kayıt ol",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersion(bool isDark) {
    return Text(
      _surumYazi ?? '',
      style: TextStyle(
        fontSize: 12,
        color: isDark
            ? Colors.white.withValues(alpha: 0.4)
            : const Color(0xFF94A3B8),
      ),
    );
  }
}
