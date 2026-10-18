// lib/screens/6_muhasebe/havale/widgets/hesaplar_gorunumu.dart
//
// Havale / EFT sayfasının "Hesaplar" sekmesi. Hesap yoksa (bugün Datça gibi
// hesabı tanımlanmamış işletme) çıkmaz sokak olmasın: kulüple iletişim.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/banka_hesabi_karti.dart';
import 'package:flutter/material.dart';

class HesaplarGorunumu extends StatelessWidget {
  final List<BankaHesabiModel> hesaplar;
  final KarekodYapici karekodYapici;
  final ValueChanged<BankaHesabiModel>? onKarekodPaylas;
  final VoidCallback? onIletisim;
  final Future<void> Function()? onYenile;

  const HesaplarGorunumu({
    super.key,
    required this.hesaplar,
    this.karekodYapici = varsayilanKarekodYapici,
    this.onKarekodPaylas,
    this.onIletisim,
    this.onYenile,
  });

  @override
  Widget build(BuildContext context) {
    final Widget liste;
    if (hesaplar.isEmpty) {
      liste = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Bosluk.xl),
            child: BosDurum(
              ikon: Icons.account_balance_outlined,
              baslik: 'Havale hesabı henüz tanımlı değil',
              aciklama: 'Ödeme için kulüple iletişime geçebilirsin. Havale '
                  'yaptıysan dekontunu yine de yükleyebilirsin.',
              eylemEtiketi: onIletisim == null ? null : 'İletişim',
              eylemIkonu: Icons.chat_outlined,
              onEylem: onIletisim,
            ),
          ),
        ],
      );
    } else {
      liste = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xl),
        children: [
          for (final hesap in hesaplar) ...[
            BankaHesabiKarti(
              hesap: hesap,
              karekodAcikBaslasin: hesaplar.length == 1,
              karekodYapici: karekodYapici,
              onKarekodPaylas: onKarekodPaylas,
            ),
            const SizedBox(height: Bosluk.m),
          ],
          Text(
            'Havale açıklamasına üyenin adını yaz. Gönderdikten sonra '
            'dekontunu yükle; kulüp kontrol edip hesabına işler.',
            style: context.metin.bodySmall
                ?.copyWith(color: context.cs.onSurfaceVariant),
          ),
        ],
      );
    }
    if (onYenile == null) return liste;
    return RefreshIndicator(onRefresh: onYenile!, child: liste);
  }
}
