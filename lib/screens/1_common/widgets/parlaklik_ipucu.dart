// lib/screens/1_common/widgets/parlaklik_ipucu.dart
//
// QR kod gösterilen sayfalardaki (tesis girişi / etkinlik daveti) parlaklık
// ipucu şeridi. Parlaklık otomatik artırılabildiyse bilgilendirme, cihaz veya
// kullanıcı buna izin vermiyorsa eski manuel yönerge gösterilir.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ParlaklikIpucu extends StatelessWidget {
  /// EkranParlaklikKontrolu.maksimumda — parlaklık gerçekten artırıldıysa true.
  final ValueListenable<bool> maksimumda;

  const ParlaklikIpucu({super.key, required this.maksimumda});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: maksimumda,
      builder: (context, otomatik, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                otomatik
                    ? Icons.brightness_high_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 20,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  otomatik
                      ? 'QR kodun kolay okunması için ekran parlaklığı geçici '
                          'olarak artırıldı. Sayfadan çıkınca eski ayarına döner.'
                      : 'Ekran parlaklığını artırarak QR kodun daha kolay '
                          'okunmasını sağlayın.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
