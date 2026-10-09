// lib/screens/1_common/acilis_popup/widgets/duyuru_popup.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_gorseli.dart';
import 'package:fitcall/services/core/acilis_popup_service.dart';
import 'package:flutter/material.dart';

/// Tam ekran duyuru popup'ı: üstte görsel (ekranın ~2/3'ü), altta başlık,
/// kısa özet ve butonlar.
///
/// Görsel kırpılmadan sığdırılır (afiş üstündeki yazılar kesilmesin); boşluk
/// aynı görselin bulanık kopyasıyla dolar. Görsel yoksa ya da yüklenemezse
/// kodla çizilmiş varsayılan poster gösterilir.
class DuyuruPopup extends StatelessWidget {
  final DuyuruModel duyuru;
  final VoidCallback onKapat;

  /// null ise "Detaylı bilgi" gizlenir (gösterilecek fazlası yok).
  final VoidCallback? onDetay;

  const DuyuruPopup({
    super.key,
    required this.duyuru,
    required this.onKapat,
    this.onDetay,
  });

  /// Popup'ı açar. "Detaylı bilgi"ye basıldıysa true döner.
  static Future<bool> goster(BuildContext context, DuyuruModel duyuru) async {
    final detayVar = duyuruDetayiVarMi(duyuru);
    final sonuc = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Duyuru',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => DuyuruPopup(
        duyuru: duyuru,
        onKapat: () => Navigator.of(ctx).pop(false),
        onDetay: detayVar ? () => Navigator.of(ctx).pop(true) : null,
      ),
      transitionBuilder: (_, animasyon, __, child) {
        final egri =
            CurvedAnimation(parent: animasyon, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: egri,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(egri),
            child: child,
          ),
        );
      },
    );
    return sonuc ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    final ozet = duyuruPopupOzeti(duyuru);
    final ekranYuksekligi = MediaQuery.sizeOf(context).height;

    return Material(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Görsel kalan alanı doldurur; metin bloğu en az ekranın ~1/3'ünü
          // aldığı için görsel en fazla ~2/3 olur, uzun metinde küçülür.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DuyuruGorseli(url: duyuru.ilkResim),
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(Bosluk.s),
                      child: IconButton(
                        tooltip: 'Kapat',
                        onPressed: onKapat,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: ekranYuksekligi * 0.33),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Bosluk.xl, Bosluk.l, Bosluk.xl, Bosluk.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          duyuru.baslik,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: metin.titleLarge,
                        ),
                        if (ozet.isNotEmpty) ...[
                          const SizedBox(height: Bosluk.s),
                          Text(
                            ozet,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: metin.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Bosluk.l),
                    _butonlar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _butonlar() {
    final detay = onDetay;
    if (detay == null) {
      return FilledButton(onPressed: onKapat, child: const Text('Tamam'));
    }
    return Row(
      children: [
        Expanded(
          child: TextButton(onPressed: onKapat, child: const Text('Tamam')),
        ),
        const SizedBox(width: Bosluk.m),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: detay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: Bosluk.m),
            ),
            child: const Text('Detaylı bilgi'),
          ),
        ),
      ],
    );
  }
}
