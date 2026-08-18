// lib/screens/4_auth/forgot_password_page.dart
//
// Şifremi unuttum — native ekran.
//
// Eskiden web sayfasını tarayıcıda açan bir ara duraktı. Akış web'le aynı ve
// kural tek yerde (backend `auths/sifre_sifirlama_service.py`):
//
//   kullanıcı adı  → doğrudan link
//   10 haneli tel  → tek hesap varsa link, BİRDEN ÇOKSA hesap seçimi
//
// Seçim adımı şart: aynı cep numarası birden çok hesaba bağlanabiliyor (veli
// kendi numarasını çocuğunun kaydına da yazıyor). Hesaplar maskeli listelenir —
// bu ekran kimlik doğrulamasından önce geliyor.
//
// Şifrenin kendisi e-postadaki tek kullanımlık bağlantıda değiştirilir; mobil
// bu adımı devralmıyor.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/4_auth/sifre_sifirlama_model.dart';
import 'package:fitcall/screens/4_auth/widgets/hesap_secim_listesi.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/kayit_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _kimlikCtrl = TextEditingController();

  bool _yukleniyor = false;

  /// Girilen değer — seçim adımında ikinci isteğe aynen gönderilir.
  String _kimlik = '';

  /// Sonuç: null ise form gösterilir.
  SifreSifirlamaSonucu? _sonuc;

  @override
  void dispose() {
    _kimlikCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final kimlik = _kimlikCtrl.text.trim();
    setState(() {
      _yukleniyor = true;
      _kimlik = kimlik;
    });

    await _cagir(() => KayitService.sifremiUnuttum(kimlik));
  }

  Future<void> _hesapSec(SifirlamaHesabi hesap) async {
    setState(() => _yukleniyor = true);
    await _cagir(
      () => KayitService.secilenHesabaGonder(
        identifier: _kimlik,
        userId: hesap.userId,
      ),
    );
  }

  /// İki uç da aynı sonucu döndürüyor; hata gösterimi de ortak.
  Future<void> _cagir(Future<SifreSifirlamaSonucu> Function() istek) async {
    try {
      final sonuc = await istek();
      if (!mounted) return;
      setState(() {
        _sonuc = sonuc;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      _hataGoster(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      _hataGoster('İşlem tamamlanamadı. Lütfen tekrar deneyin.');
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(mesaj),
        backgroundColor: context.cs.error,
        duration: const Duration(seconds: 5),
      ));
  }

  void _bastanBasla() {
    setState(() {
      _sonuc = null;
      _kimlik = '';
      _kimlikCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sonuc = _sonuc;

    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Bosluk.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: switch (sonuc?.durum) {
                null => _form(),
                SifirlamaDurumu.secimGerekli => HesapSecimListesi(
                    hesaplar: sonuc!.hesaplar,
                    yukleniyor: _yukleniyor,
                    onSec: _hesapSec,
                    onVazgec: _bastanBasla,
                  ),
                SifirlamaDurumu.gonderildi => _SonucGorunumu(
                    ikon: Icons.mark_email_read_outlined,
                    baslik: 'Bağlantı gönderildi',
                    aciklama:
                        'Şifre sıfırlama bağlantısını ${sonuc!.maskeliEposta ?? 'e-posta adresinize'} '
                        'gönderdik. Bağlantı 48 saat geçerli; gelen kutunuzda '
                        'yoksa spam klasörüne de bakın.',
                    eylemEtiketi: 'Giriş ekranına dön',
                    onEylem: () => Navigator.pop(context),
                  ),
                SifirlamaDurumu.epostasiz => _SonucGorunumu(
                    ikon: Icons.mail_lock_outlined,
                    baslik: 'Kayıtlı e-posta yok',
                    aciklama: sonuc!.hesaplar.isEmpty
                        ? 'Hesabınızda kayıtlı bir e-posta adresi bulunmuyor. '
                            'Şifrenizi sıfırlamak için kulüple iletişime geçin.'
                        : '',
                    eylemEtiketi: 'Tekrar dene',
                    onEylem: _bastanBasla,
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset_rounded, size: 56, color: context.cs.primary),
          const SizedBox(height: Bosluk.l),
          Text('Şifrenizi mi unuttunuz?',
              textAlign: TextAlign.center, style: context.metin.titleLarge),
          const SizedBox(height: Bosluk.s),
          Text(
            'Kullanıcı adınızı ya da kulüpte kayıtlı cep telefonunuzu girin; '
            'sıfırlama bağlantısını e-posta adresinize gönderelim.',
            textAlign: TextAlign.center,
            style: context.metin.bodyMedium
                ?.copyWith(color: context.cs.onSurfaceVariant),
          ),
          const SizedBox(height: Bosluk.xl),
          TextFormField(
            controller: _kimlikCtrl,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı ya da cep telefonu',
              prefixIcon: Icon(Icons.person_search_outlined),
              hintText: '5551112233',
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Kullanıcı adı ya da telefon girin'
                : null,
            onFieldSubmitted: (_) => _gonder(),
          ),
          const SizedBox(height: Bosluk.l),
          FilledButton(
            onPressed: _yukleniyor ? null : _gonder,
            child: _yukleniyor
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Bağlantı gönder'),
          ),
        ],
      ),
    );
  }
}

class _SonucGorunumu extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final String eylemEtiketi;
  final VoidCallback onEylem;

  const _SonucGorunumu({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.eylemEtiketi,
    required this.onEylem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: context.cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(ikon, size: 40, color: context.cs.primary),
        ),
        const SizedBox(height: Bosluk.l),
        Text(baslik, textAlign: TextAlign.center, style: context.metin.titleLarge),
        if (aciklama.isNotEmpty) ...[
          const SizedBox(height: Bosluk.s),
          Text(
            aciklama,
            textAlign: TextAlign.center,
            style: context.metin.bodyMedium
                ?.copyWith(color: context.cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: Bosluk.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onEylem, child: Text(eylemEtiketi)),
        ),
      ],
    );
  }
}
