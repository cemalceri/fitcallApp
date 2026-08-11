// ignore_for_file: use_build_context_synchronously
import 'package:fitcall/screens/1_common/3_mobil_app/app_update_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _kullaniciAdiCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _sifreFocus = FocusNode();
  bool _beniHatirla = false;
  bool _yukleniyor = false;
  bool _sifreGizli = true;

  /// Açılışta beni-hatırla durumu belirlenene kadar true; bu sürede form yerine
  /// nötr açılış splash'ı gösterilir. Böylece beni-hatırla açıkken kullanıcı
  /// adı/şifre formu bir an bile görünmez.
  bool _hazirlaniyor = true;

  /// Beni-hatırla ile sessiz otomatik giriş sürüyor: form gizlenir, tam ekran
  /// "Giriş yapılıyor…" gösterilir. Manuel girişte false kalır.
  bool _otomatikGiris = false;

  String? _surumYazi; // vX.Y.Z (build)

  // Güvenli depoda saklanacak anahtarlar
  static const _kRememberUser = 'remember_username';
  static const _kRememberPass = 'remember_password';

  @override
  void initState() {
    super.initState();
    _surumYukle();
    _acilisAkisi();
  }

  @override
  void dispose() {
    NotificationFCMService.instance.hasPendingNotification
        .removeListener(_onNotificationDismissedRetryLogin);
    _kullaniciAdiCtrl.dispose();
    _sifreCtrl.dispose();
    _sifreFocus.dispose();
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

  /// Açılış akışı: beni-hatırla'yı erken okuyup formu mu yoksa nötr splash'ı mı
  /// göstereceğimizi belirler. Kapalıysa form anında gelir; açıksa form HİÇ
  /// çizilmez, doğrudan otomatik giriş açılışına geçilir (eski davranışta form
  /// bir an görünüp kayboluyordu). Güncelleme kontrolü + otomatik giriş ilk
  /// frame sonrasına ertelenir.
  Future<void> _acilisAkisi() async {
    final remember = await StorageService.beniHatirlaIsaretlenmisMi();
    if (mounted) setState(() => _beniHatirla = remember);
    if (remember != true) {
      _formuGoster();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await GuncellemeKoordinatoru.kontrolVeUygula(context);
      await _tryAutoLoginFromApi();
    });
  }

  void _formuGoster() {
    if (mounted && _hazirlaniyor) setState(() => _hazirlaniyor = false);
  }

  /// Beni hatırla açık ve kayıtlı krediler varsa profilleri **API'den** çeker ve yönlendirir.
  Future<void> _tryAutoLoginFromApi() async {
    // Pending bildirim varsa auto-login bekleyecek; dialog kapatılınca tetiklenecek.
    if (NotificationFCMService.instance.hasPendingNotification.value) {
      NotificationFCMService.instance.hasPendingNotification
          .addListener(_onNotificationDismissedRetryLogin);
      return;
    }

    final remember = await StorageService.beniHatirlaIsaretlenmisMi();
    if (remember != true) {
      _formuGoster();
      return;
    }

    final u = await SecureStorageService.getValue<String>(_kRememberUser);
    final p = await SecureStorageService.getValue<String>(_kRememberPass);
    if (u == null || u.isEmpty || p == null || p.isEmpty) {
      _formuGoster();
      return;
    }

    // Otomatik giriş: formu gizle, tam ekran açılış göster.
    setState(() {
      _otomatikGiris = true;
      _yukleniyor = true;
    });
    try {
      final result = await AuthService.fetchMyMembers(u, p);
      final profiller = result.profiller;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
      );
    } catch (_) {
      // oto login sessiz düşsün; formu aç, kullanıcı manuel giriş yapabilir
      if (mounted) {
        setState(() {
          _otomatikGiris = false;
          _yukleniyor = false;
          _hazirlaniyor = false;
        });
      }
    }
  }

  void _onNotificationDismissedRetryLogin() {
    final notifier = NotificationFCMService.instance.hasPendingNotification;
    if (notifier.value == false) {
      notifier.removeListener(_onNotificationDismissedRetryLogin);
      if (mounted) {
        _tryAutoLoginFromApi();
      }
    }
  }

  Future<void> _girisButonunaBasildi() async {
    if (_yukleniyor) return;
    final u = _kullaniciAdiCtrl.text.trim();
    final p = _sifreCtrl.text;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Şifre yöneticisine "bu değerleri kaydedebilirsin" sinyali.
    TextInput.finishAutofillContext();

    setState(() => _yukleniyor = true);
    try {
      final result = await AuthService.fetchMyMembers(u, p);
      final profiller = result.profiller;

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
    final cs = context.cs;

    return Scaffold(
      // Buzlu cam yüzeyler ve iç içe yarı saydam katmanlar kaldırıldı:
      // düz yüzey + net kontrast hem okunur hem koyu temayla uyumlu.
      body: SafeArea(
        child: (_hazirlaniyor || _otomatikGiris)
            ? _girisYapiliyor()
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Bosluk.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _logo(cs),
                            const SizedBox(height: Bosluk.xl),
                            Text('Hoş geldiniz',
                                style: context.metin.headlineMedium),
                            const SizedBox(height: Bosluk.xs),
                            Text(
                              'Giriş için bilgilerinizi girin',
                              textAlign: TextAlign.center,
                              style: context.metin.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: Bosluk.xl),
                            _kullaniciAlani(),
                            const SizedBox(height: Bosluk.m),
                            _sifreAlani(),
                            const SizedBox(height: Bosluk.s),
                            _beniHatirlaSatiri(),
                            const SizedBox(height: Bosluk.l),
                            _girisButonu(),
                            const SizedBox(height: Bosluk.s),
                            _baglantilar(),
                            const SizedBox(height: Bosluk.l),
                            _surum(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Beni-hatırla otomatik girişinde gösterilen tam ekran açılış.
  Widget _girisYapiliyor() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _logo(context.cs),
          const SizedBox(height: Bosluk.xxl),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (_otomatikGiris) ...[
            const SizedBox(height: Bosluk.l),
            Text('Giriş yapılıyor…', style: context.metin.titleSmall),
          ],
        ],
      ),
    );
  }

  Widget _logo(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(Bosluk.l),
      decoration: BoxDecoration(
        // Logo siyah çizgili: koyu temada okunması için zemin hep beyaz.
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Yaricap.xl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Image.asset(
        'assets/images/logo.png',
        width: 92,
        height: 92,
        semanticLabel: 'Binay Tenis Akademi',
      ),
    );
  }

  Widget _kullaniciAlani() {
    return TextFormField(
      controller: _kullaniciAdiCtrl,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Kullanıcı adı',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      validator: (v) =>
          (v ?? '').trim().isEmpty ? 'Kullanıcı adı gerekli' : null,
      onFieldSubmitted: (_) => _sifreFocus.requestFocus(),
    );
  }

  Widget _sifreAlani() {
    return TextFormField(
      controller: _sifreCtrl,
      focusNode: _sifreFocus,
      obscureText: _sifreGizli,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: 'Şifre',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
          icon: Icon(_sifreGizli
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
        ),
      ),
      validator: (v) => (v ?? '').isEmpty ? 'Şifre gerekli' : null,
      onFieldSubmitted: (_) => _girisButonunaBasildi(),
    );
  }

  Widget _beniHatirlaSatiri() {
    return Row(
      children: [
        Checkbox(
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
        ),
        const Expanded(child: Text('Beni hatırla')),
      ],
    );
  }

  Widget _girisButonu() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _yukleniyor ? null : _girisButonunaBasildi,
        child: _yukleniyor
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Giriş yap'),
      ),
    );
  }

  Widget _baglantilar() {
    return Column(
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(
              context, routeEnums[SayfaAdi.sifremiUnuttum]!),
          child: const Text('Şifremi unuttum'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text('Hesabın yok mu?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodyMedium),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, routeEnums[SayfaAdi.kayitol]!),
              child: const Text('Kayıt ol'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _surum() {
    return Text(_surumYazi ?? '', style: context.metin.bodySmall);
  }
}
