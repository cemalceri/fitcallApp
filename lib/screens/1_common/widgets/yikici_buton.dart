// lib/screens/1_common/widgets/yikici_buton.dart
//
// Geri alınamayan ya da kayıp doğuran aksiyonların butonu (Sil, İptal et,
// Çıkış yap): kenarlıklı ve hata renginde.
//
// Neden dolgulu değil: Sarı-Kırmızı ve Ay-Yıldız temalarında kimlik rengi
// hata kırmızısına çok yakın. Dolgulu kırmızı buton takım rengiyle karışıyor,
// "bu ekranın ana aksiyonu" gibi okunuyordu. Dolgulu buton yalnız ana renge
// kalır; yıkıcı aksiyon biçimiyle (kenarlık) ayrılır.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class YikiciButon extends StatelessWidget {
  final String etiket;
  final VoidCallback? onPressed;
  final IconData? ikon;

  /// İşlem sürerken etiket yerine buton içi ilerleme göstergesi.
  final bool yukleniyor;

  /// Varsayılan dikey dolgu; dar diyaloglarda küçültülebilir.
  final EdgeInsetsGeometry? padding;

  const YikiciButon({
    super.key,
    required this.etiket,
    required this.onPressed,
    this.ikon,
    this.yukleniyor = false,
    this.padding,
  });

  static ButtonStyle stil(BuildContext context, {EdgeInsetsGeometry? padding}) {
    final cs = context.cs;
    return OutlinedButton.styleFrom(
      foregroundColor: cs.error,
      disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
      padding: padding,
    ).copyWith(
      side: WidgetStateProperty.resolveWith(
        (s) => BorderSide(
          color: s.contains(WidgetState.disabled)
              ? cs.onSurface.withValues(alpha: 0.12)
              : cs.error,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final stilim = stil(context, padding: padding);
    final yazi = yukleniyor
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.error),
          )
        : Text(etiket, maxLines: 1, overflow: TextOverflow.ellipsis);
    final basildi = yukleniyor ? null : onPressed;

    if (ikon != null && !yukleniyor) {
      return OutlinedButton.icon(
        onPressed: basildi,
        style: stilim,
        icon: Icon(ikon, size: 18),
        label: yazi,
      );
    }
    return OutlinedButton(onPressed: basildi, style: stilim, child: yazi);
  }
}
