// lib/screens/1_common/widgets/kabuk_menusu.dart
//
// Kabuğun sol menüsünü (drawer) her sekmeden açmak için. Drawer kabuğun
// Scaffold'unda durur; sekmelerin kendi Scaffold'u olduğu için
// `Scaffold.of` kabuğa ulaşamaz, "menüyü aç" işlevi bu widget'la iner.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kabuk sekmelerine "menüyü aç" işlevini taşır.
///
/// Kabuktan itilen sayfalar (Ayarlar, detaylar) bu ağacın dışında kalır;
/// onlarda menü butonu çıkmaz, geri oku kalır. Aynı sayfa hem sekme hem
/// itilen sayfa olabildiği için (Hareketler, profil) ayrım buradan yapılır.
class KabukMenusu extends InheritedWidget {
  final VoidCallback menuyuAc;

  const KabukMenusu({
    super.key,
    required this.menuyuAc,
    required super.child,
  });

  /// Kabuk sekmesindeyse menüyü açan işlev, değilse null.
  static VoidCallback? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KabukMenusu>()?.menuyuAc;

  @override
  bool updateShouldNotify(KabukMenusu oldWidget) => false;
}

/// Elle çizilen başlık satırının (bant, sekme başlığı) solundaki menü
/// butonu. Kabuk dışında hiçbir şey çizmez.
class KabukMenuButonu extends StatelessWidget {
  const KabukMenuButonu({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = KabukMenusu.of(context);
    if (ac == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: Bosluk.s),
      child: BaslikIkonButonu(
        ikon: Icons.menu_rounded,
        ipucu: 'Menü',
        onTap: ac,
      ),
    );
  }
}

/// AppBar `leading`'i: kabuk sekmesinde menü butonu, dışında null (AppBar
/// geri okunu kendisi koyar).
Widget? kabukMenuLeading(BuildContext context) {
  final ac = KabukMenusu.of(context);
  if (ac == null) return null;
  return IconButton(
    tooltip: 'Menü',
    icon: const Icon(Icons.menu_rounded),
    onPressed: () {
      HapticFeedback.lightImpact();
      ac();
    },
  );
}
