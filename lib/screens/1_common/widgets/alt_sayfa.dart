// lib/screens/1_common/widgets/alt_sayfa.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Ders işlemlerinin ortak sunum kalıbı: ekranın altından açılan sayfa.
///
/// Antrenör takvimindeki onay / iptal / devir / detay akışları ekranın
/// ortasında `showDialog` ile açılıyordu; üye takviminde aynı sınıf işlem
/// alttan geliyordu. Ortadaki diyalog telefonda başparmakla ulaşılamayan bir
/// kalıp — hepsi burada birleşti.
Future<T?> altSayfaGoster<T>(
  BuildContext context, {
  required Widget cocuk,

  /// Klavye açılan formlarda tam yükseklik gerekir.
  double maksYukseklikOrani = 0.92,
  bool kaydirmaCubugu = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: kaydirmaCubugu,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * maksYukseklikOrani,
      ),
      child: Padding(
        // Klavye açıkken içerik klavyenin altında kalmasın.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: cocuk,
      ),
    ),
  );
}

/// Alt sayfa başlığı — ikon, başlık, alt başlık ve kapat düğmesi.
class AltSayfaBasligi extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String? altBaslik;
  final Color? renk;

  const AltSayfaBasligi({
    super.key,
    required this.ikon,
    required this.baslik,
    this.altBaslik,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final vurgu = renk ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.s, Bosluk.m),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Bosluk.s),
            decoration: BoxDecoration(
              color: vurgu.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Yaricap.m),
            ),
            child: Icon(ikon, color: vurgu, size: 22),
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(baslik, style: context.metin.titleMedium),
                if (altBaslik != null)
                  Text(altBaslik!, style: context.metin.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }
}
