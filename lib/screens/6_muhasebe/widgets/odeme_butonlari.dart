// lib/screens/6_muhasebe/widgets/odeme_butonlari.dart
//
// Hesap Özeti bakiye kartındaki iki ödeme yolu: EFT / Havale (hesaplar +
// dekont sayfası) ve kredi kartı. Kredi kartıyla ödeme henüz yok; buton
// bunu söyler ve üyeyi EFT / Havale'ye yönlendirir (2026-10-19).

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class OdemeButonlari extends StatelessWidget {
  final VoidCallback onHavale;
  final VoidCallback onKrediKarti;

  const OdemeButonlari({
    super.key,
    required this.onHavale,
    required this.onKrediKarti,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    // Kimlik yüzeyinin üstünde buton zemin renginde: ana renk yüzeyle aynı
    // aileden olduğu için orada kaybolurdu.
    final stil = FilledButton.styleFrom(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    Widget buton(IconData ikon, String yazi, VoidCallback onTap) => Expanded(
          child: FilledButton.icon(
            onPressed: onTap,
            style: stil,
            icon: Icon(ikon, size: 18),
            // Dar ekranda ve büyük yazıda iki satıra iner, kesilmez.
            label: Text(yazi, maxLines: 2, textAlign: TextAlign.center),
          ),
        );
    return Row(
      children: [
        buton(Icons.account_balance_outlined, 'EFT / Havale', onHavale),
        const SizedBox(width: Bosluk.s),
        buton(Icons.credit_card_rounded, 'Kredi kartı ile öde', onKrediKarti),
      ],
    );
  }
}

/// Kredi kartıyla ödeme hazır olana kadar: bilgi ver, EFT / Havale'ye yönlendir.
Future<void> krediKartiYakindaGoster(
  BuildContext context, {
  required VoidCallback onHavale,
}) async {
  final havaleyeGit = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.credit_card_rounded),
      title: const Text('Kredi kartıyla ödeme yakında'),
      content: const Text(
        'Kredi kartıyla ödeme henüz hazır değil. Şimdilik EFT / Havale ile '
        'ödeyebilir, dekontunu uygulamadan yükleyebilirsin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('EFT / Havale ile öde'),
        ),
      ],
    ),
  );
  if (havaleyeGit == true) onHavale();
}
