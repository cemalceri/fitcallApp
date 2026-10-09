// lib/screens/1_common/acilis_popup/widgets/dogum_gunu_popup.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/konfeti_patlamasi.dart';
import 'package:flutter/material.dart';

/// Tam ekran doğum günü kutlaması: kobalt zemin, konfeti, tek buton.
///
/// Zemin her iki temada da marka kobaltı — bu bir "an", tema yüzeyi değil.
class DogumGunuPopup extends StatelessWidget {
  final String ad;

  /// Kartın altındaki imza (işletme adı). Boşsa gösterilmez — iki işletme
  /// var, sabit "Binay Akademi" yazmak Datça üyesine yanlış olur.
  final String? imza;
  final VoidCallback onKapat;

  /// Testlerde animasyonsuz render için kapatılabilir.
  final bool konfeti;

  const DogumGunuPopup({
    super.key,
    required this.ad,
    required this.onKapat,
    this.imza,
    this.konfeti = true,
  });

  static const String baslik = 'İyi ki doğdun, iyi ki bizimlesin!';
  static const String dilek = 'Tenis, sağlık ve neşe dolu bir sene dileriz.';

  static Future<void> goster(BuildContext context,
      {required String ad, String? imza}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Doğum günü',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => DogumGunuPopup(
        ad: ad,
        imza: imza,
        onKapat: () => Navigator.of(ctx).pop(),
      ),
      transitionBuilder: (_, animasyon, __, child) {
        final egri =
            CurvedAnimation(parent: animasyon, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: egri,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(egri),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metin = context.metin;
    const beyaz = Colors.white;
    final soluk = Colors.white.withValues(alpha: 0.86);

    return Material(
      color: Marka.mavi,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.xl, Bosluk.s, Bosluk.xl, Bosluk.xl),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Kapat',
                      onPressed: onKapat,
                      style: IconButton.styleFrom(foregroundColor: soluk),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  // Küçük ekran + büyük yazı ölçeğinde içerik taşmasın diye
                  // gerekirse orantılı küçülür.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, kisit) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: kisit.maxWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.cake_rounded,
                                      size: 44, color: Marka.turuncuAcik),
                                ),
                                const SizedBox(height: Bosluk.xl),
                                Text(
                                  ad,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: metin.displaySmall
                                      ?.copyWith(color: beyaz),
                                ),
                                const SizedBox(height: Bosluk.m),
                                Text(
                                  baslik,
                                  textAlign: TextAlign.center,
                                  style:
                                      metin.titleLarge?.copyWith(color: beyaz),
                                ),
                                const SizedBox(height: Bosluk.m),
                                Text(
                                  dilek,
                                  textAlign: TextAlign.center,
                                  style:
                                      metin.bodyLarge?.copyWith(color: soluk),
                                ),
                                if (imza != null && imza!.trim().isNotEmpty) ...[
                                  const SizedBox(height: Bosluk.xl),
                                  Text(
                                    imza!.trim(),
                                    textAlign: TextAlign.center,
                                    style: metin.labelLarge?.copyWith(
                                      color: Marka.maviAcik,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Bosluk.l),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onKapat,
                      style: FilledButton.styleFrom(
                        backgroundColor: Marka.turuncu,
                        foregroundColor: beyaz,
                      ),
                      child: const Text('Teşekkürler'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (konfeti)
            const Positioned.fill(
              child: KonfetiPatlamasi(kaynakYuksekligi: 0.32),
            ),
        ],
      ),
    );
  }
}
