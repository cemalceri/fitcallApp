// lib/screens/1_common/ogrenme/hedef_bulucu.dart
//
// Rehber adımının hedefini canlı ekranda bulur. Yalnız açık (en üstteki)
// sayfadaki ve açık sekmedeki (IndexedStack'te gizli olmayan) öğeler
// sayılır; "görünür" demek, öğenin ortasına dokunulsa
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

  /// Öğenin ekranda görünen kısmı: kaydırma görünümü, alt sayfa ve ekran
  /// (klavye hariç) kırpmaları düşülmüş alan. Delik bunun çevresinde açılır;
  /// ekrandan uzun listede delik ekranın dışına taşmaz.
  final Rect gorunen;
  final bool gorunur;
  final BuildContext baglam;

  const HedefSonucu(this.alan, this.gorunur, this.baglam, {Rect? gorunen})
      : gorunen = gorunen ?? alan;

  /// Öğenin bir kısmı kırpılmış (ekranın altında yarım kalan kart, ekrandan
  /// uzun liste).
  bool get kesik =>
      gorunen.height < alan.height - 1 || gorunen.width < alan.width - 1;
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
  /// [pasifDahil]: yazıyla aranan buton kapalıysa da sayılır (son adımda
  /// buton zaten basılmaz; ad yazılmadan kapalı duran «QR Oluştur» gibi).
  HedefSonucu? bul(Secici secici, {bool pasifDahil = false}) {
    final adaylar = switch (secici) {
      HedefSecici(:final id) => OgrenmeHedefi.kayitlilar(id).toList(),
      MetinSecici(:final metin) => _metinAdaylari(metin, pasifDahil),
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

  /// Adımın hedefi; son (kalıcı) adımda kapalı buton da sayılır.
  HedefSonucu? adimHedefi(OgrenmeAdimi adim) =>
      bul(adim.hedef, pasifDahil: adim.kalici);

  /// Sayfa hâlâ yükleniyor mu (ortak yükleme göstergesi ekranda mı)?
  bool yukleniyorMu() => bul(const Secici.hedef(Hedef.yukleniyor)) != null;

  /// Rehber bu ekranda hemen başlayabilir mi: ilk adımın (ilki atlanabilirse
  /// ikincinin) hedefi açık sayfada var mı?
  bool baslatilabilir(OgrenmeGorevi gorev) {
    final adimlar = gorev.adimlar;
    if (adimlar.isEmpty) return false;
    // Okuma turu sayfadan çıkmaz: anlattığı her yer şimdi ekranda olmalı
    // (ör. bekleyen iş yokken satırlar çizilmez).
    if (adimlar.every((a) => a.bilgi)) {
      return adimlar.every((a) => adimHedefi(a) != null);
    }
    if (adimHedefi(adimlar.first) == null) {
      return adimlar.first.atlanabilir &&
          adimlar.length > 1 &&
          adimHedefi(adimlar[1]) != null;
    }
    // Dokunulmayan okuma adımı ekranı değiştirmez: ardından gelen ilk
    // eylemin hedefi de şimdi ekranda olmalı (boş listede «bir üyeye dokun»
    // adımına gelen rehber okuma adımına geri dönüp takılıyordu).
    for (final adim in adimlar) {
      if (adim.bilgi && adim.dokunulur) return true;
      if (adimHedefi(adim) == null) return false;
      if (!adim.bilgi) return true;
    }
    return true;
  }

  /// Ekran dışında kalan hedefi ortaya kaydırır; görünümünden uzun hedefin
  /// başı üste gelir (ortalansa başı da sonu da kesilirdi).
  void kaydir(HedefSonucu sonuc) {
    if (!sonuc.baglam.mounted) return;
    final konum = Scrollable.maybeOf(sonuc.baglam)?.position;
    final boy = konum == null || !konum.hasViewportDimension
        ? null
        : konum.viewportDimension;
    final uzunluk = konum?.axis == Axis.horizontal
        ? sonuc.alan.width
        : sonuc.alan.height;
    Scrollable.ensureVisible(
      sonuc.baglam,
      alignment: boy != null && uzunluk > boy * 0.8 ? 0.0 : 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  HedefSonucu? _olc(BuildContext baglam) {
    if (!baglam.mounted) return null;
    if (!(ModalRoute.isCurrentOf(baglam) ?? true)) return null;
    // Kabuğun gizli sekmesi: aynı yazı ("Bugün", "Kaydet") başka sekmede
    // de durabilir; açık sekmedeki sayılır.
    if (!Visibility.of(baglam)) return null;
    final kutu = baglam.findRenderObject();
    final kok = uygulama.currentContext?.findRenderObject();
    final katmanKutusu = katman.currentContext?.findRenderObject();
    if (kutu is! RenderBox || kok is! RenderBox || katmanKutusu is! RenderBox) {
      return null;
    }
    if (!kutu.attached || !kutu.hasSize || !kok.hasSize) return null;
    final sol = katmanKutusu.globalToLocal(kutu.localToGlobal(Offset.zero));
    final alan = sol & kutu.size;
    final gorunen = _gorunenKisim(kutu, kok);
    Rect katmanda(Rect r) => Rect.fromPoints(
          katmanKutusu.globalToLocal(kok.localToGlobal(r.topLeft)),
          katmanKutusu.globalToLocal(kok.localToGlobal(r.bottomRight)),
        );
    return HedefSonucu(
      alan,
      _dokunulur(kok, kutu, gorunen),
      baglam,
      gorunen: gorunen == null ? null : katmanda(gorunen),
    );
  }

  /// Öğenin görünen kısmı ([kok] koordinatında): atalarının kırptığı alanlar
  /// (kaydırma görünümü, yapışkan başlık örtüşmesi, alt sayfa) ve ekran
  /// (klavye hariç) düşülür. Hiç görünmüyorsa null.
  Rect? _gorunenKisim(RenderBox kutu, RenderBox kok) {
    var alan = MatrixUtils.transformRect(
        kutu.getTransformTo(kok), Offset.zero & kutu.size);
    RenderObject cocuk = kutu;
    var ata = kutu.parent;
    while (ata != null) {
      final kirpma = ata.describeApproximatePaintClip(cocuk);
      if (kirpma != null) {
        alan = alan.intersect(
            MatrixUtils.transformRect(ata.getTransformTo(kok), kirpma));
      }
      if (identical(ata, kok)) break;
      cocuk = ata;
      ata = ata.parent;
    }
    alan = alan.intersect(
        Rect.fromLTWH(0, 0, kok.size.width, kok.size.height - klavye()));
    return alan.width < 1 || alan.height < 1 ? null : alan;
  }

  /// Öğenin görünen kısmının ortasına dokunulsa dokunuş ona gider mi?
  bool _dokunulur(RenderBox kok, RenderBox kutu, Rect? gorunen) {
    if (gorunen == null) return false;
    final sonuc = BoxHitTestResult();
    kok.hitTest(sonuc, position: gorunen.center);
    return sonuc.path.any((giris) => giris.target == kutu);
  }

  /// Yazısı [metin] olan Text'lerin en yakın dokunulabilir ataları.
  List<BuildContext> _metinAdaylari(String metin, bool pasifDahil) {
    final kok = uygulama.currentContext;
    if (kok is! Element) return const [];
    final adaylar = <BuildContext>[];
    void gez(Element e) {
      final w = e.widget;
      if (w is Text && (w.data ?? w.textSpan?.toPlainText()) == metin) {
        final ata = _dokunulabilirAta(e, pasifDahil);
        if (ata != null) adaylar.add(ata);
      }
      e.visitChildElements(gez);
    }

    kok.visitChildElements(gez);
    return adaylar;
  }

  static Element? _dokunulabilirAta(Element e, bool pasifDahil) {
    Element? bulunan;
    var derinlik = 0;
    e.visitAncestorElements((ata) {
      final w = ata.widget;
      if (_dokunulabilir(w) || (pasifDahil && _pasifButon(w))) {
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

  static bool _pasifButon(Widget w) => switch (w) {
        ButtonStyleButton(:final onPressed) => onPressed == null,
        IconButton(:final onPressed) => onPressed == null,
        _ => false,
      };
}
