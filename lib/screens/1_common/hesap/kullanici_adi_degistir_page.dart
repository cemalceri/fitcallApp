// lib/screens/1_common/hesap/kullanici_adi_degistir_page.dart
//
// Ayarlar → "Kullanıcı adını değiştir". Kural sunucuda
// (api/auth/metots.py, kullanici_adi_hatasi): 4-30 karakter, yalnız İngilizce
// harf ve rakam, en az bir harf; küçük harfle saklanır. Başkası kullanıyorsa
// sunucu "uygun değil" der, mesaj alanın altında gösterilir.
//
// Sayfa açılışta API çağırmaz; taşma testine doğrudan girer.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sunucudaki kuralın istemci kopyası: gönderimden önce hızlı geri bildirim.
/// Tekillik yalnız sunucuda denetlenir.
String? kullaniciAdiBicimHatasi(String ham, {String? mevcut}) {
  final ad = ham.trim().toLowerCase();
  if (ad.isEmpty) return 'Yeni kullanıcı adını yaz.';
  if (!RegExp(r'^[a-z0-9]{4,30}$').hasMatch(ad)) {
    return '4-30 karakter; yalnız İngilizce harf ve rakam.';
  }
  if (RegExp(r'^[0-9]+$').hasMatch(ad)) return 'En az bir harf olmalı.';
  if (mevcut != null && ad == mevcut.trim().toLowerCase()) {
    return 'Bu zaten kullanıcı adın.';
  }
  return null;
}

class KullaniciAdiDegistirPage extends StatefulWidget {
  final String mevcutAd;

  const KullaniciAdiDegistirPage({super.key, required this.mevcutAd});

  @override
  State<KullaniciAdiDegistirPage> createState() =>
      _KullaniciAdiDegistirPageState();
}

class _KullaniciAdiDegistirPageState extends State<KullaniciAdiDegistirPage> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _gonderiliyor = false;

  /// Sunucunun alan hatası ("uygun değil"); yazı değişince silinir.
  String? _sunucuHatasi;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _sunucuHatasi = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final aday = _ctrl.text.trim().toLowerCase();
    setState(() => _gonderiliyor = true);
    try {
      final yeni = await UyeApiService.kullaniciAdiniDegistir(aday);
      await StorageService.kullaniciAdiniGuncelle(widget.mevcutAd, yeni);
      if (!mounted) return;
      ShowMessage.success(
          context, 'Kullanıcı adın «$yeni» oldu. Girişte bunu kullan.');
      Navigator.pop(context, yeni);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'KULLANICI_ADI_ALINMIS' || e.code == 'VALIDATION_ERROR') {
        setState(() => _sunucuHatasi = e.message);
      } else {
        ShowMessage.error(context, e.message);
      }
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Kullanıcı adı değiştirilemedi.');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Adını Değiştir')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Bosluk.l),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, color: cs.primary),
                      const SizedBox(width: Bosluk.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Şu anki kullanıcı adın',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                            Text(
                              widget.mevcutAd,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Bosluk.xl),
                OgrenmeHedefi(
                  id: Hedef.genelKullaniciAdiAlani,
                  child: TextFormField(
                    controller: _ctrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.visiblePassword,
                    autofillHints: const [AutofillHints.newUsername],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(30),
                    ],
                    onChanged: (_) {
                      if (_sunucuHatasi != null) {
                        setState(() => _sunucuHatasi = null);
                      }
                    },
                    onFieldSubmitted: (_) => _kaydet(),
                    validator: (v) => kullaniciAdiBicimHatasi(v ?? '',
                        mevcut: widget.mevcutAd),
                    decoration: InputDecoration(
                      labelText: 'Yeni kullanıcı adı',
                      helperText: 'İngilizce harf ve rakam, 4-30 karakter.',
                      helperMaxLines: 2,
                      errorText: _sunucuHatasi,
                      errorMaxLines: 2,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Bosluk.l),
                Text(
                  'Girişte yeni kullanıcı adını ya da e-postanı kullanırsın. '
                  'Şifren değişmez.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Bosluk.xl),
                FilledButton(
                  onPressed: _gonderiliyor ? null : _kaydet,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _gonderiliyor
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: ButonYukleniyorGostergesi(kalinlik: 2),
                        )
                      : const Text(
                          'Kaydet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
