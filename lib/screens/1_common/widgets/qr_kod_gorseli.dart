// lib/screens/1_common/widgets/qr_kod_gorseli.dart
//
// Okuyucuya gösterilen QR kodun ortak görseli (tesis girişi / etkinlik daveti).
//
// Zemin HER TEMADA beyaz, modüller siyah: eskiden zemin `colorScheme.surface`
// idi ve koyu temada siyah modüller koyu gri zeminin üstünde kalıyordu —
// kontrast düşünce kapıdaki okuyucu kodu göremiyor. QR standardı açık
// zemin/koyu modül istediği için bu renkler bilinçli olarak temaya bağlı değil.
//
// Kenarlıktaki nabız dışarıdan besleniyor ([nabiz] 0..1); animasyonu sayfa
// yönetir, bu widget yalnız çizer.

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrKodGorseli extends StatelessWidget {
  /// QR'ın içine yazılacak kod.
  final String kod;

  /// Kare kenar uzunluğu (px).
  final double boyut;

  /// Nabız animasyonunun anlık değeri (0..1); kenarlık ve gölgeyi canlandırır.
  final double nabiz;

  const QrKodGorseli({
    super.key,
    required this.kod,
    required this.boyut,
    this.nabiz = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Kenarlık ve nabız temanın ana renginde; kodun kendisi her temada
    // siyah-beyaz kalır.
    final vurgu = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: vurgu.withValues(alpha: 0.2 + (nabiz * 0.15)),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: vurgu.withValues(alpha: 0.1 + (nabiz * 0.1)),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: QrImageView(
        data: kod,
        version: QrVersions.auto,
        size: boyut,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}
