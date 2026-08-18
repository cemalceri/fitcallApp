// lib/screens/4_auth/widgets/hesap_secim_listesi.dart
//
// Şifre sıfırlamada hesap seçimi.
//
// Bir cep numarası birden çok hesaba bağlanabiliyor (veli kendi numarasını
// çocuğunun kaydına da yazıyor). Hangi hesabın şifresinin sıfırlanacağını
// kullanıcı seçer.
//
// Ad ve e-posta MASKELİ gelir: ekran kimlik doğrulamasından önce açılıyor,
// numarayı bilen biri hesap sahiplerinin tam adını öğrenmemeli. Maskeleme
// sunucuda yapılır (auths/sifre_sifirlama_service.py), burada yalnız gösterilir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/4_auth/sifre_sifirlama_model.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

class HesapSecimListesi extends StatelessWidget {
  final List<SifirlamaHesabi> hesaplar;

  /// Seçim gönderiliyor — satırlar kilitlenir.
  final bool yukleniyor;

  final ValueChanged<SifirlamaHesabi> onSec;
  final VoidCallback onVazgec;

  const HesapSecimListesi({
    super.key,
    required this.hesaplar,
    required this.onSec,
    required this.onVazgec,
    this.yukleniyor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_alt_outlined, size: 48, color: context.cs.primary),
        const SizedBox(height: Bosluk.l),
        Text('Hangi hesap sizin?',
            textAlign: TextAlign.center, style: context.metin.titleLarge),
        const SizedBox(height: Bosluk.s),
        Text(
          'Bu numaraya birden fazla hesap bağlı. Sıfırlama bağlantısı yalnız '
          'seçtiğiniz hesabın e-postasına gönderilir.',
          textAlign: TextAlign.center,
          style: context.metin.bodyMedium
              ?.copyWith(color: context.cs.onSurfaceVariant),
        ),
        const SizedBox(height: Bosluk.l),
        for (final hesap in hesaplar) ...[
          ListeSatiri(
            onGorsel: ListeAvatari(basHarfler: _basHarfler(hesap.maskeliAd)),
            baslik: hesap.maskeliAd.isEmpty ? 'Hesap' : hesap.maskeliAd,
            altBaslik: hesap.epostaVarMi
                ? hesap.maskeliEposta
                : 'Kayıtlı e-posta yok',
            okGoster: true,
            onTap: yukleniyor ? null : () => onSec(hesap),
          ),
          const ListeAyraci(),
        ],
        const SizedBox(height: Bosluk.l),
        TextButton(
          onPressed: yukleniyor ? null : onVazgec,
          child: const Text('Başka bir bilgiyle ara'),
        ),
      ],
    );
  }

  /// Maskeli addan baş harfler: "Me**** Ka**" → "MK".
  String _basHarfler(String maskeliAd) {
    final parcalar = maskeliAd
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parcalar.isEmpty) return '?';
    final harfler = parcalar.take(2).map((p) => p[0].toUpperCase()).join();
    return harfler.isEmpty ? '?' : harfler;
  }
}
