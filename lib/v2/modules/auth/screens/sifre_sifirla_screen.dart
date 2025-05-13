// lib/modules/auth/screens/sifre_sifirla_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fitcall/v2/modules/auth/services/auth_service.dart';
import 'package:fitcall/v2/shared/widgets/show_message_widget.dart';

class SifreSifirlaScreen extends StatefulWidget {
  const SifreSifirlaScreen({super.key});

  @override
  State<SifreSifirlaScreen> createState() => _SifreSifirlaScreenState();
}

class _SifreSifirlaScreenState extends State<SifreSifirlaScreen> {
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      ShowMessage.error(
          context, 'Lütfen e-posta veya kullanıcı adınızı girin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPassword(identifier: id)
          .timeout(const Duration(seconds: 20), onTimeout: () {
        throw Exception('Zaman aşımına uğradı. Lütfen tekrar deneyin.');
      });

      ShowMessage.success(
        context,
        'Şifre sıfırlama bağlantısı gönderildi. E-postanızı kontrol edin.',
      );
    } catch (e) {
      ShowMessage.error(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Arka plan resmi
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              fit: BoxFit.fill,
            ),
          ),
        ),

        // Tam sayfa blurlu form
        Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 80,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Şifreni Sıfırla',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _identifierController,
                          decoration: const InputDecoration(
                            hintText: 'E-posta veya Kullanıcı Adı',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetLink,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Bağlantı Gönder'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Geri Dön'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
