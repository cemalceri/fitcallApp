import 'dart:ui';
import 'package:fitcall/v2/modules/auth/services/auth_service.dart';
import 'package:fitcall/v2/router/routes.dart';
import 'package:fitcall/v2/shared/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kullaniciAdiController = TextEditingController();
  final _parolaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _girisYap() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profiller = await AuthService.login(
        _kullaniciAdiController.text,
        _parolaController.text,
      );
      Navigator.pushReplacementNamed(
        context,
        routeEnums[SayfaAdi.profilSecimV2]!,
        arguments: profiller,
      );
    } catch (e) {
      ShowMessage.error(
        context,
        e.toString().replaceAll(
            'Exception: ', ''), // gereksiz Exception: ön ekini kaldırır
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
              fit: BoxFit.fill,
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _kullaniciAdiController,
                      decoration: const InputDecoration(
                        hintText: 'Kullanıcı Adı veya E-posta',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _parolaController,
                      decoration: const InputDecoration(
                        hintText: 'Şifre',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _girisYap,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Giriş Yap'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Şifremi unuttum sayfasına yönlendir
                          },
                          child: const Text('Şifremi Unuttum'),
                        ),
                        const Text('  |  '),
                        TextButton(
                          onPressed: () {
                            // Kayıt ol sayfasına yönlendir
                          },
                          child: const Text('Kayıt Ol'),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
