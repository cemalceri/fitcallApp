// lib/screens/1_common/widgets/erisim_kisitli.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:flutter/material.dart';

/// Ana hesap zorunlu sayfaların yetkisiz görünümü.
///
/// Hem `myRouteGenerator` guard'ı hem de sekme kabuğu aynı ekranı gösterir:
/// kabukta sekme `Navigator` üzerinden geçmediği için guard devreye girmez,
/// kontrolü kabuk kendi yapar (bkz. `UyeKabuk`).
class ErisimKisitli extends StatelessWidget {
  /// Kabuk içinde gösterildiğinde geri butonu anlamsız olur.
  final bool geriButonu;

  const ErisimKisitli({super.key, this.geriButonu = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: geriButonu ? AppBar(title: const Text('Erişim kısıtlı')) : null,
      body: BosDurum(
        ikon: Icons.lock_outline_rounded,
        baslik: 'Erişim kısıtlı',
        aciklama: 'Bu sayfayı yalnızca ana hesap kullanıcısı görebilir. '
            'Ana hesaba geçmek için profil değiştir.',
        ikonRengi: context.renkler.uyari,
      ),
    );
  }
}
