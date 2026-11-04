// lib/screens/1_common/ogrenme/hedef_bulucu.dart
//
// Rehber adımının hedefini canlı ekranda bulur. Yalnız açık (en üstteki)
// sayfadaki öğeler sayılır; "görünür" demek, öğenin ortasına dokunulsa
// dokunuşun ona gideceği demektir (üstünde alt sayfa, klavye ya da başka bir
// öğe yok, kaydırılıp ekran dışına çıkmamış).

import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HedefSonucu {
  /// Katman koordinatında öğenin alanı.
  final Rect alan;
  final bool gorunur;
  final BuildContext baglam;

  const HedefSonucu(this.alan, this.gorunur, this.baglam);
}

class HedefBulucu {
  /// Navigator'u saran alt ağaç: aramanın ve dokunma denemesinin kökü.
  final GlobalKey uygulama;

  /// Rehber katmanı: delik ve panel bu koordinatta çizilir.
  final GlobalKey katman;

  /// Klavyenin kapladığı alt yükseklik; altında kalan öğe görünmez sayılır.
  final double Function() klavye;

  HedefBulucu({
    required this.uygulama,
    required this.katman,
    required this.klavye,
  });

  /// Seçiciye uyan, açık sayfadaki ilk öğe; görünür olan öne alınır.
  HedefSonucu? bul(Secici secici) {
    final adaylar = switch (secici) {
      HedefSecici(:final id) => OgrenmeHedefi.kayitlilar(id).toList(),
      MetinSecici(:final metin) => _metinAdaylari(metin),
    };
    HedefSonucu? yedek;
    for (final aday in adaylar) {
      final sonuc = _olc(aday);
      if (sonuc == null) continue;
      if (sonuc.gorunur) return sonuc;
      yedek ??= sonuc;
    }
    return yedek;
  }

  /// Sayfa hâlâ yükleniyor mu (ortak yükleme göstergesi ekranda mı)?
  bool yukleniyorMu() => bul(const Secici.hedef(Hedef.yukleniyor)) != null;

  /// Rehber bu ekranda hemen başlayabilir mi: ilk adımın (ilki atlanabilirse
  /// ikincinin) hedefi açık sayfada var mı?
  bool baslatilabilir(OgrenmeGorevi gorev) {
    final adimlar = gorev.adimlar;
    if (adimlar.isEmpty) return false;
    if (bul(adimlar.first.hedef) != null) return true;
    return adimlar.first.atlanabilir &&
        adimlar.length > 1 &&
        bul(adimlar[1].hedef) != null;
  }

  /// Ekran dışında kalan hedefi ortaya kaydırır.
  void kaydir(HedefSonucu sonuc) {
    if (!sonuc.baglam.mounted) return;
    Scrollable.ensureVisible(
      sonuc.baglam,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  HedefSonucu? _olc(BuildContext baglam) {
    if (!baglam.mounted) return null;
    if (!(ModalRoute.isCurrentOf(baglam) ?? true)) return null;
    final kutu = baglam.findRenderObject();
    final kok = uygulama.currentContext?.findRenderObject();
    final katmanKutusu = katman.currentContext?.findRenderObject();
    if (kutu is! RenderBox || kok is! RenderBox || katmanKutusu is! RenderBox) {
      return null;
    }
    if (!kutu.attached || !kutu.hasSize || !kok.hasSize) return null;
    final sol = katmanKutusu.globalToLocal(kutu.localToGlobal(Offset.zero));
    final alan = sol & kutu.size;
    return HedefSonucu(alan, _dokunulur(kok, kutu), baglam);
  }

  /// Öğenin ekrandaki kısmının ortasına dokunulsa dokunuş ona gider mi?
  bool _dokunulur(RenderBox kok, RenderBox kutu) {
    final ekran =
        Rect.fromLTWH(0, 0, kok.size.width, kok.size.height - klavye());
    final ust = kok.globalToLocal(kutu.localToGlobal(Offset.zero));
    final gorunen = (ust & kutu.size).intersect(ekran);
    if (gorunen.width < 1 || gorunen.height < 1) return false;
    final sonuc = BoxHitTestResult();
    kok.hitTest(sonuc, position: gorunen.center);
    return sonuc.path.any((giris) => giris.target == kutu);
  }

  /// Yazısı [metin] olan Text'lerin en yakın dokunulabilir ataları.
  List<BuildContext> _metinAdaylari(String metin) {
    final kok = uygulama.currentContext;
    if (kok is! Element) return const [];
    final adaylar = <BuildContext>[];
    void gez(Element e) {
      final w = e.widget;
      if (w is Text && (w.data ?? w.textSpan?.toPlainText()) == metin) {
        final ata = _dokunulabilirAta(e);
        if (ata != null) adaylar.add(ata);
      }
      e.visitChildElements(gez);
    }

    kok.visitChildElements(gez);
    return adaylar;
  }

  static Element? _dokunulabilirAta(Element e) {
    Element? bulunan;
    var derinlik = 0;
    e.visitAncestorElements((ata) {
      final w = ata.widget;
      if (_dokunulabilir(w)) {
        bulunan = ata;
        return false;
      }
      // Sayfa ya da alt sayfa sınırında dur: başlık yazısı, sayfayı saran bir
      // dokunma alanına bağlanmasın.
      if (w is Scaffold || w is BottomSheet || w is Dialog || w is Navigator) {
        return false;
      }
      return ++derinlik < 40;
    });
    return bulunan;
  }

  static bool _dokunulabilir(Widget w) => switch (w) {
        ButtonStyleButton(:final onPressed) => onPressed != null,
        IconButton(:final onPressed) => onPressed != null,
        InkResponse(:final onTap) => onTap != null,
        GestureDetector(:final onTap) => onTap != null,
        ListTile(:final onTap) => onTap != null,
        _ => false,
      };
}
