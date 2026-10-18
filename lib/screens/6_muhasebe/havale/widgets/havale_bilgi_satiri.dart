// lib/screens/6_muhasebe/havale/widgets/havale_bilgi_satiri.dart
//
// Hesap Özeti'nde bakiye kartının altındaki düz bilgi satırı: kontrol
// bekleyen dekont varken üye bakiyenin neden değişmediğini görsün ve ikinci
// kez havale yapmasın. İkinci bir kimlik yüzeyi değil; "beklenen bakiye"
// gösterilmez (bakiye yalnız onayla değişir).

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class HavaleBilgiSatiri extends StatelessWidget {
  final int bekleyenSayisi;
  final VoidCallback onTap;

  const HavaleBilgiSatiri({
    super.key,
    required this.bekleyenSayisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metin = context.metin;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Yaricap.m),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.xs, vertical: Bosluk.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 20, color: context.renkler.uyari),
              const SizedBox(width: Bosluk.s),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '$bekleyenSayisi dekont kontrol bekliyor. ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: 'Onaydan sonra bakiyene yansır.'),
                  ]),
                  style: metin.bodyMedium,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: context.cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
