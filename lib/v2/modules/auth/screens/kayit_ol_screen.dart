import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/v2/modules/auth/services/auth_service.dart';
import 'package:fitcall/v2/shared/widgets/show_message_widget.dart';
import 'package:fitcall/v2/shared/widgets/kullanici_sozlesmesi_widget.dart';
import 'package:flutter/services.dart';

class KayitOlScreen extends StatefulWidget {
  const KayitOlScreen({super.key});

  @override
  State<KayitOlScreen> createState() => _KayitOlScreenState();
}

class _KayitOlScreenState extends State<KayitOlScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ShowMessage.error(context, 'Şifreler eşleşmiyor.');
      return;
    }
    if (!_acceptedTerms) {
      ShowMessage.error(context, 'Kullanıcı sözleşmesini kabul etmelisiniz.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        email: _emailController.text,
        phone: _phoneController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception(
            'Kayıt işlemi zaman aşımına uğradı. Lütfen tekrar deneyin.'),
      );
      ShowMessage.success(
        context,
        'Kayıt başarılı. Hesabınız onaylandıktan sonra giriş yapabilirsiniz.',
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
      body: Stack(
        fit: StackFit.expand,
        children: [
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1500, sigmaY: 1500),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            hintText: 'Ad',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            hintText: 'Soyad',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'E-posta (maxleo@mail.com)',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            // Sadece e-posta adreslerinde kullanılabilecek karakterlere izin ver
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9a-zA-Z@._\-]')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            hintText: 'Telefon (5XXXXXXXXX)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            hintText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Şifre (Tekrar)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _confirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() =>
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptedTerms = v ?? false),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.black),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'Kullanıcı sözleşmesini okudum, '),
                                    TextSpan(
                                      text: 'kabul ediyorum.',
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                  'Kullanıcı Sözleşmesi'),
                                              content:
                                                  const SingleChildScrollView(
                                                child:
                                                    KullaniciSozlesmesiWidget(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Kapat'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Kayıt Ol'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
