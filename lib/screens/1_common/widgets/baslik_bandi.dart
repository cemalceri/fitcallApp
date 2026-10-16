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

/// Kabuk sekmelerinin (Raporlar, Antrenörler…) başlık bandı: solda sayfa
/// adı, sağda bağlam bilgisi ([BaslikKapsulu]), altında tam genişlik
/// [BaslikSecici]. Açıklama satırı bilerek yok: sekme adı ve alt bardaki
/// simge yeterli, bant kısa kalsın.
class SekmeBasligi extends StatelessWidget {
  final String baslik;
  final Widget? sag;
  final Widget? alt;

  const SekmeBasligi({
    super.key,
    required this.baslik,
    this.sag,
    this.alt,
  });

  @override
  Widget build(BuildContext context) {
    return BaslikBandi(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            // Dashboard'daki 44'lük ikon butonlarıyla aynı satır yüksekliği.
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (sag != null) ...[
                  const SizedBox(width: Bosluk.m),
                  sag!,
                ],
              ],
            ),
          ),
          if (alt != null) ...[
            const SizedBox(height: Bosluk.m),
            alt!,
          ],
        ],
      ),
    );
  }
}

/// Başlık satırının sağındaki bilgi kapsülü: "859 kayıt", "12 – 15 Eki".
///
/// Yalnız kenarlık: başlık yazısı rengindeki %16 dolgu üstünde beyaz yazı
/// Binay açıkta 4.5:1'in altında kalıyordu; yazı doğrudan başlık rengi
/// üstünde.
class BaslikKapsulu extends StatelessWidget {
  final String metin;
  final IconData? ikon;

  const BaslikKapsulu(this.metin, {super.key, this.ikon});

  @override
  Widget build(BuildContext context) {
    final on = context.gecis.onBaslik;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: on.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(Yaricap.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 14, color: on),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              metin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: on,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renkli başlıktaki tek seçimli süzgeç: bandın tüm genişliğine yayılan,
/// eşit dilimli seçici (dönem, aktif/pasif…). Seçili dilim başlık yazı
/// renginde dolgu, üstünde başlık rengi; ray yalnız kenarlık.
///
/// Çiplerden farkı: sola yığılıp bandın sağını boş bırakmaz.
class BaslikSecici<T> extends StatelessWidget {
  final List<(T, String)> secenekler;
  final T secili;
  final ValueChanged<T> onSec;

  /// true: başlık bandı yerine içerik yüzeyinde (kart içinde) çizilir —
  /// seçici etkilediği verilerle aynı kutuda durduğunda (yönetici panosu).
  final bool yuzeyde;

  const BaslikSecici({
    super.key,
    required this.secenekler,
    required this.secili,
    required this.onSec,
    this.yuzeyde = false,
  });

  static const double _yaziBoyu = 13;
  static const double _satirOrani = 1.3;
  static const double _dilimDikey = 7;
  static const double _rayIc = 3;

  /// Seçicinin toplam yüksekliği (SliverAppBar `bottom` hesabı için). Yazı
  /// ölçeği 1.3'e çıkabildiği için sabit değer verilmez.
  static double yukseklik(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_yaziBoyu) * _satirOrani +
      _dilimDikey * 2 +
      _rayIc * 2 +
      2; // kenarlık

  @override
  Widget build(BuildContext context) {
    final g = context.gecis;
    return Container(
      padding: const EdgeInsets.all(_rayIc),
      decoration: BoxDecoration(
        border: Border.all(
          color: yuzeyde
              ? context.cs.outlineVariant
              : g.onBaslik.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        children: [
          for (final (deger, etiket) in secenekler)
            Expanded(
              child: _dilim(context, deger, etiket, deger == secili),
            ),
        ],
      ),
    );
  }

  Widget _dilim(BuildContext context, T deger, String etiket, bool seciliMi) {
    final g = context.gecis;
    return Semantics(
      button: true,
      selected: seciliMi,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (seciliMi) return;
          HapticFeedback.lightImpact();
          onSec(deger);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: _dilimDikey),
          decoration: BoxDecoration(
            color: seciliMi
                ? (yuzeyde ? context.cs.primary : g.onBaslik)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Yaricap.m - _rayIc),
          ),
          child: Text(
            etiket,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _yaziBoyu,
              height: _satirOrani,
              fontWeight: seciliMi ? FontWeight.w700 : FontWeight.w500,
              color: yuzeyde
                  ? (seciliMi
                      ? context.cs.onPrimary
                      : context.cs.onSurfaceVariant)
                  : (seciliMi ? g.baslik : g.onBaslik),
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
      content:
          const Text('Yeniden girmek için kullanıcı adı ve şifre gerekecek.'),
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
