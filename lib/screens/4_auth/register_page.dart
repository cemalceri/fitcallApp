// lib/screens/4_auth/register_page.dart
//
// Üyelik başvurusu — native ekran.
//
// Eskiden bu sayfa yalnız bir ara duraktı: web'deki `/auths/register` formunu
// tarayıcıda açıp kendini kapatıyordu. Kullanıcı uygulamadan çıkmış oluyor,
// mobil tarih seçici/klavye davranışını kaybediyor ve dönüşte ne olduğunu
// anlamıyordu. Form artık uygulamanın içinde (bkz. widgets/kayit_sihirbazi.dart);
// doğrulama sunucuda aynı web formuyla yapılıyor.

import 'package:fitcall/models/4_auth/kayit_secenekleri_model.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/4_auth/widgets/kayit_sihirbazi.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/kayit_service.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  KayitSecenekleri? _secenekler;
  bool _yukleniyor = true;
  String? _yuklemeHatasi;
  bool _gonderiliyor = false;

  /// Gönderim bitince dolar: başvuru sonucu ekranı gösterilir.
  BasvuruSonucu? _sonuc;

  @override
  void initState() {
    super.initState();
    _secenekleriYukle();
  }

  Future<void> _secenekleriYukle() async {
    setState(() {
      _yukleniyor = true;
      _yuklemeHatasi = null;
    });
    try {
      final secenekler = await KayitService.secenekler();
      if (!mounted) return;
      setState(() {
        _secenekler = secenekler;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _yuklemeHatasi = e.message;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _yuklemeHatasi = 'Başvuru formu yüklenemedi.';
        _yukleniyor = false;
      });
    }
  }

  Future<void> _gonder(Map<String, dynamic> alanlar) async {
    setState(() => _gonderiliyor = true);
    try {
      final sonuc = await KayitService.basvuruGonder(alanlar);
      if (!mounted) return;
      setState(() {
        _sonuc = sonuc;
        _gonderiliyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _gonderiliyor = false);
      // Sunucunun alan mesajı ("Telefon 10 hane...") doğrudan gösterilir;
      // mobil kopyası olsa çelişebilirdi.
      _hataGoster(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _gonderiliyor = false);
      _hataGoster('Başvuru gönderilemedi. Lütfen tekrar deneyin.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üyelik Başvurusu')),
      body: SafeArea(
        child: switch (true) {
          _ when _sonuc != null => _SonucGorunumu(
              sonuc: _sonuc!,
              onKapat: () => Navigator.pop(context),
            ),
          _ when _yukleniyor => const IskeletKart(),
          _ when _yuklemeHatasi != null => Center(
              child: BosDurum(
                ikon: Icons.wifi_off_rounded,
                baslik: 'Form yüklenemedi',
                aciklama: _yuklemeHatasi!,
                eylemEtiketi: 'Tekrar dene',
                eylemIkonu: Icons.refresh_rounded,
                onEylem: _secenekleriYukle,
              ),
            ),
          _ => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: KayitSihirbazi(
                    secenekler: _secenekler!,
                    gonderiliyor: _gonderiliyor,
                    onGonder: _gonder,
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}

/// Gönderim sonrası ekran. Aynı kişinin ikinci başvurusu hata değil bilgi:
/// kullanıcı formu doğru doldurmuş, talebi zaten sırada.
class _SonucGorunumu extends StatelessWidget {
  final BasvuruSonucu sonuc;
  final VoidCallback onKapat;

  const _SonucGorunumu({required this.sonuc, required this.onKapat});

  @override
  Widget build(BuildContext context) {
    final mevcut = sonuc.durum == BasvuruDurumu.mevcut;
    final renk = mevcut ? context.cs.primary : context.renkler.basari;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Bosluk.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mevcut ? Icons.hourglass_bottom_rounded : Icons.check_rounded,
                size: 40,
                color: renk,
              ),
            ),
            const SizedBox(height: Bosluk.l),
            Text(
              mevcut ? 'Başvurunuz zaten sırada' : 'Başvurunuz alındı',
              textAlign: TextAlign.center,
              style: context.metin.headlineSmall,
            ),
            const SizedBox(height: Bosluk.s),
            Text(
              sonuc.mesaj,
              textAlign: TextAlign.center,
              style: context.metin.bodyMedium
                  ?.copyWith(color: context.cs.onSurfaceVariant),
            ),
            const SizedBox(height: Bosluk.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onKapat,
                child: const Text('Giriş ekranına dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
