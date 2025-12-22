// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/api_urls.dart'; // registerUrl burada tanımlı olmalı
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    // İlk frame'den sonra web'i aç ve bu sayfayı hemen kapat.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _openRegisterWeb(context);
    });
  }

  Future<void> _openRegisterWeb(BuildContext context) async {
    if (_launched) return;
    _launched = true;

    final uri = Uri.parse(registerUrl);

    // In-app browser (CCT/SFVC) destekliyse onu kullan; değilse external’a düş.
    final supports = await supportsLaunchMode(LaunchMode.inAppBrowserView);
    final mode =
        supports ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication;

    final ok = await launchUrl(
      uri,
      mode: mode,
      // browserConfiguration: const BrowserConfiguration(showTitle: true),
    );

    if (!ok && mounted) {
      // Açılamadıysa kısa uyarı verelim ve bu sayfadan yine de çıkalım.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt sayfası açılamadı.')),
      );
    }

    // Kritik nokta: Bu ara sayfayı hemen kapatıyoruz.
    // Web görünümü (CCT/SFVC) açık kalır; kullanıcı geri/kapama ile çıktığında
    // artık login ekranına döner (çünkü bu sayfa pop edildi).
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bu ara ekranda UI göstermiyoruz; anında yönlendirme yapılıyor.
    // İstersen çok kısa bir progress göstergesi bırakılabilir.
    return const Scaffold(
      body: SizedBox.expand(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
