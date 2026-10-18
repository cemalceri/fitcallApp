// lib/screens/7_yonetici/uyeler/widgets/uye_siralama_sheet.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici Üyeler — sıralama seçimi. Satıra dokununca seçilir ve kapanır.
///
/// "Hiç" değerleri: son kontrol / son ödeme eskiden yeniye sırada başta
/// (en eski sayılır), tersinde sonda; dersi olmayan iki yönde de sonda.
class UyeSiralamaSheet extends StatelessWidget {
  final UyeSiralama secili;

  const UyeSiralamaSheet({super.key, required this.secili});

  static Future<UyeSiralama?> ac(
    BuildContext context, {
    required UyeSiralama secili,
  }) {
    return altSayfaGoster<UyeSiralama>(
      context,
      cocuk: UyeSiralamaSheet(secili: secili),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AltSayfaBasligi(
          ikon: Icons.swap_vert_rounded,
          baslik: 'Sırala',
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: Bosluk.l),
            children: [
              for (final s in UyeSiralama.secenekler)
                ListTile(
                  selected: s == secili,
                  leading: Icon(
                    s == secili
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: s == secili ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(s.etiket),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, s);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
