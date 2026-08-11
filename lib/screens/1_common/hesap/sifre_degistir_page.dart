// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';

class SifreDegistirPage extends StatefulWidget {
  const SifreDegistirPage({super.key});

  @override
  State<SifreDegistirPage> createState() => _SifreDegistirPageState();
}

class _SifreDegistirPageState extends State<SifreDegistirPage> {
  final _formKey = GlobalKey<FormState>();
  final _eskiCtrl = TextEditingController();
  final _yeniCtrl = TextEditingController();
  final _yeni2Ctrl = TextEditingController();
  bool _showOld = false, _showNew = false, _showNew2 = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eskiCtrl.dispose();
    _yeniCtrl.dispose();
    _yeni2Ctrl.dispose();
    super.dispose();
  }

  String? _validateNew(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Yeni şifre zorunludur.';
    if (s.length < 8) return 'En az 8 karakter olmalı.';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
      return 'Harf ve rakam içermeli.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_yeniCtrl.text != _yeni2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yeni şifreler eşleşmiyor.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await UyeApiService.kullaniciSifreDegistir(
        eskiSifre: _eskiCtrl.text.trim(),
        yeniSifre: _yeniCtrl.text.trim(),
      );

      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty ? res.mesaj : 'Şifreniz başarıyla değiştirildi.',
      );
      AuthService.logout(context);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Geri',
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Şifreyi Değiştir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 48,
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Fields
                        _ModernTextField(
                          controller: _eskiCtrl,
                          label: 'Mevcut Şifre',
                          obscureText: !_showOld,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            tooltip: 'Şifre görünürlüğü',
                            onPressed: () =>
                                setState(() => _showOld = !_showOld),
                            icon: Icon(_showOld
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
                        ),

                        const SizedBox(height: 16),

                        _ModernTextField(
                          controller: _yeniCtrl,
                          label: 'Yeni Şifre',
                          obscureText: !_showNew,
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            tooltip: 'Şifre görünürlüğü',
                            onPressed: () =>
                                setState(() => _showNew = !_showNew),
                            icon: Icon(_showNew
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: _validateNew,
                        ),

                        const SizedBox(height: 16),

                        _ModernTextField(
                          controller: _yeni2Ctrl,
                          label: 'Yeni Şifre (Tekrar)',
                          obscureText: !_showNew2,
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            tooltip: 'Şifre görünürlüğü',
                            onPressed: () =>
                                setState(() => _showNew2 = !_showNew2),
                            icon: Icon(_showNew2
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                  )
                                : const Text(
                                    'Şifreyi Değiştir',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }
}
