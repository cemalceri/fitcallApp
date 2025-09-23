// // ignore_for_file: use_build_context_synchronously

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitcall/common/api_urls.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    // İlk frame'den sonra web'i aç ve bu ara sayfayı hemen kapat.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _openForgotWeb(context);
    });
  }

  Future<void> _openForgotWeb(BuildContext context) async {
    if (_launched) return;
    _launched = true;

    final uri = Uri.parse(forgotPasswordUrl);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifremi Unuttum sayfası açılamadı.')),
      );
    }

    // Bu ara sayfayı hemen kapatıyoruz; web görünümü açık kalır.
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ara ekranda progress göstergesi
    return const Scaffold(
      body: SizedBox.expand(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
