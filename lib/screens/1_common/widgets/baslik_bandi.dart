// lib/screens/1_common/widgets/baslik_bandi.dart
//
// AppBar kullanmayan sayfaların (kabuk ana sayfaları, profil seç, dersler,
// bildirimler…) başlığı. Her sayfanın başlık çubuğu dolu takım renginde
// (bkz. TemaGecisleri.baslik); AppBar'lı sayfalarda bunu tema yapar, elle
// çizilen başlıklarda bu bant.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dolu takım renginde başlık bandı. Durum çubuğunun arkasına uzanır,
/// içeriği güvenli alanın altından başlar.
///
/// İçindeki `Text`, `Icon`, `IconButton` ve `TextButton` renk vermezse
/// [TemaGecisleri.onBaslik] alır. `context.metin` stilleri kendi rengini
/// taşıdığı için burada [baslikYazi] ile kullanılmalı.
class BaslikBandi extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// false ise durum çubuğu payı bırakılmaz (bant sayfanın tepesinde değilse).
  final bool ustGuvenliAlan;

  const BaslikBandi({
    super.key,
    required this.child,
    this.padding =
        const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.s, Bosluk.m),
    this.ustGuvenliAlan = true,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.gecis;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: baslikDurumCubugu(g.baslik),
      child: Material(
        color: g.baslik,
        child: SafeArea(
          top: ustGuvenliAlan,
          bottom: false,
          child: Padding(
            padding: padding,
            child: BaslikIcerigi(child: child),
          ),
        ),
      ),
    );
  }
}

/// Başlık rengi üstündeki içerik için varsayılan yazı/ikon/buton renkleri.
/// AppBar'ın `bottom` alanı gibi bandın dışındaki renkli başlık parçalarında
/// da kullanılır.
class BaslikIcerigi extends StatelessWidget {
  final Widget child;

  const BaslikIcerigi({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final renk = context.gecis.onBaslik;
    return _BaslikUstunde(
      child: DefaultTextStyle.merge(
        style: TextStyle(color: renk),
        child: IconTheme.merge(
          data: IconThemeData(color: renk),
          child: IconButtonTheme(
            data: IconButtonThemeData(
              // Devre dışı hâl de başlık renginden türer; varsayılan (koyu
              // yazının %38'i) renkli zeminde lekeli görünüyordu.
              style: IconButton.styleFrom(
                foregroundColor: renk,
                disabledForegroundColor: renk.withValues(alpha: 0.45),
                minimumSize: const Size(44, 44),
              ),
            ),
            child: TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: renk,
                  disabledForegroundColor: renk.withValues(alpha: 0.45),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Başlık bandının içinde olduğunu ortak bileşenlere (bildirim zili, profil
/// değiştir) bildirir; onlar da renklerini başlığa göre seçer.
class _BaslikUstunde extends InheritedWidget {
  const _BaslikUstunde({required super.child});

  @override
  bool updateShouldNotify(_BaslikUstunde oldWidget) => false;
}

/// Bileşen renkli başlığın (bant ya da AppBar alanı) üstünde mi?
bool baslikUstundeMi(BuildContext context) =>
    context.getInheritedWidgetOfExactType<_BaslikUstunde>() != null;

/// Başlıktaki ikon butonu: 42×42 yuvarlatılmış kutu. Başlık üstünde kutu
/// başlık yazı renginin hafif tonu, ikon tam renk; sayfa zemininde [renk]
/// (verilmezse ana renk).
class BaslikIkonButonu extends StatelessWidget {
  final IconData ikon;
  final String ipucu;
  final VoidCallback onTap;
  final Color? renk;

  const BaslikIkonButonu({
    super.key,
    required this.ikon,
    required this.ipucu,
    required this.onTap,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final baslikta = baslikUstundeMi(context);
    final on = baslikta ? context.gecis.onBaslik : (renk ?? context.cs.primary);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: ipucu,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: on.withValues(alpha: baslikta ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, size: 22, color: on),
            ),
          ),
        ),
      ),
    );
  }
}

/// Başlığı elle çizen ve içeriği kayan sayfaların gövdesi: durum çubuğunun
/// arkası başlık renginde sabit kalır, kayan içerik (başlık bandı dahil) onun
/// altından geçer. İçerikte [BaslikBandi] `ustGuvenliAlan: false` ile
/// kullanılır.
///
/// Neden: bant içerikle birlikte kayınca durum çubuğunun arkasına sayfa
/// zemini gelirdi; beyaz durum çubuğu ikonları açık zeminde kaybolurdu.
class RenkliDurumCubugu extends StatelessWidget {
  final Widget child;

  const RenkliDurumCubugu({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final g = context.gecis;
    final ust = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: baslikDurumCubugu(g.baslik),
      child: Column(
        children: [
          SizedBox(
            height: ust,
            width: double.infinity,
            child: ColoredBox(color: g.baslik),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Başlık rengi üstündeki yazı stili: verilen stilin rengini
/// [TemaGecisleri.onBaslik] ile değiştirir.
TextStyle? baslikYazi(BuildContext context, TextStyle? stil) =>
    stil?.copyWith(color: context.gecis.onBaslik);

/// Renkli başlıktaki süzgeç çipi (üye listeleri, duyurular…).
///
/// Seçili: başlık yazı renginde dolgu, üstünde başlık rengi. Seçili değil:
/// yalnız kenarlık. İkisinde de yazı tam opak — renkli zeminde soluk gri
/// okunmuyordu.
class BaslikCipi extends StatelessWidget {
  final String etiket;
  final bool secili;
  final VoidCallback onSec;

  const BaslikCipi({
    super.key,
    required this.etiket,
    required this.secili,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.gecis;
    return Semantics(
      button: true,
      selected: secili,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSec();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: secili ? g.onBaslik : Colors.transparent,
            border: Border.all(color: g.onBaslik, width: 1.2),
            borderRadius: BorderRadius.circular(Yaricap.xl),
          ),
          child: Text(
            etiket,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
              color: secili ? g.baslik : g.onBaslik,
            ),
          ),
        ),
      ),
    );
  }
}


/// SliverAppBar başlığı: yalnız başlık kapanınca görünür. Açıkken aynı bilgi
/// genişleyen alanda yazıyor (profil sayfaları); iki kez okunmasın.
class KapaninciBaslik extends StatelessWidget {
  final Widget child;
  const KapaninciBaslik({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ayar =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (ayar == null) return child;
    final aralik = ayar.maxExtent - ayar.minExtent;
    final acik = aralik <= 0
        ? 0.0
        : ((ayar.currentExtent - ayar.minExtent) / aralik).clamp(0.0, 1.0);
    // Son %30'luk kapanışta belirir.
    final opaklik = ((0.3 - acik) / 0.3).clamp(0.0, 1.0);
    return Opacity(opacity: opaklik, child: child);
  }
}

/// Çıkış onayı: başlıktaki çıkış düğmesi diğer ikon düğmelerine benziyor ve
/// profil değiştirin hemen yanında; yanlışlıkla oturum kapanmasın.
Future<bool> cikisOnayla(BuildContext context) async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Çıkış yapılsın mı?'),
      content: const Text(
          'Yeniden girmek için kullanıcı adı ve şifre gerekecek.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Çıkış yap')),
      ],
    ),
  );
  return onay == true;
}
