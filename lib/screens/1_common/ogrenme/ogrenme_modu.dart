// lib/screens/1_common/ogrenme/ogrenme_modu.dart
//
// Rehberin durumu ve adım motoru. Katman (ogrenme_katmani.dart) bunu dinleyip
// çizer; ekranlar bilmez. Motor ekrana bakarak ilerler: kullanıcı parlayan
// yere dokunur, sonraki adımın hedefi açık sayfada belirince adım geçer.
// Kullanıcı geri dönerse (alt sayfayı kapatırsa) ekranda duran önceki adıma
// iner. Her giriş baştan başlar; rehber açıkken yazma istekleri ağa çıkmaz.
// Bitince ya da "Kapat" denince rehber sırasında açılan her şey kapanır,
// "?"ye dokunulan sayfaya dönülür; kapı ancak dönüş bitince kalkar.

import 'dart:async';

import 'package:fitcall/screens/1_common/ogrenme/hedef_bulucu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';

/// [donus]: başlangıç sayfasına dönülüyor; dokunuşlar yutulur, kapı açık.
enum RehberDurumu { kapali, adim, bitis, donus }

class OgrenmeModu extends ChangeNotifier {
  OgrenmeModu._();

  static final OgrenmeModu ornek = OgrenmeModu._();

  /// Katman kurulunca verilir; yoksa rehber başlamaz, liste okumaya düşer.
  HedefBulucu? bulucu;

  /// Hedef kaybolunca geçiş animasyonu için beklenen tur sayısı.
  static const _kayipSabri = 4;
  static const _tur = Duration(milliseconds: 100);

  RehberDurumu _durum = RehberDurumu.kapali;
  OgrenmeGorevi? _gorev;
  int _adim = 0;
  Rect? _delik;
  bool _dokunuldu = false;
  bool _yanlis = false;
  bool _denendi = false;
  bool _hedefYok = false;
  bool _bitisteUstteSayfa = false;
  int _kayip = 0;
  int _gorunmez = 0;
  NavigatorState? _navigator;
  Route<dynamic>? _baslangic;
  Timer? _saat;
  Timer? _yanlisSaati;

  RehberDurumu get durum => _durum;
  bool get acik => _durum != RehberDurumu.kapali;
  OgrenmeGorevi? get gorev => _gorev;
  int get adimNo => _adim;
  OgrenmeAdimi? get adim => _gorev == null || _durum != RehberDurumu.adim
      ? null
      : _gorev!.adimlar[_adim];

  /// Parlayan alan (katman koordinatı); hedef ekranda yoksa null.
  Rect? get delik => _delik;

  /// Adımın hedefi açık sayfada yok (kullanıcı başka ekrana geçti).
  bool get hedefYok => _hedefYok;

  /// Kullanıcı parlayan yer dışına dokundu (kısa süre gösterilir).
  bool get yanlis => _yanlis;

  /// Son butona dokunuldu ("Denemeydi, bir şey olmadı.").
  bool get denendi => _denendi;

  /// [gorev]'i [baslangic] sayfasında baştan başlatır.
  void baslat(
    OgrenmeGorevi gorev, {
    required NavigatorState navigator,
    required Route<dynamic> baslangic,
  }) {
    _temizle();
    _gorev = gorev;
    _durum = RehberDurumu.adim;
    _navigator = navigator;
    _baslangic = baslangic;
    OgrenmeKapisi.engellenenler.clear();
    OgrenmeKapisi.acik = true;
    _saat = Timer.periodic(_tur, (_) => izle());
    notifyListeners();
    izle();
  }

  /// Rehberi kapatır. [geriDon] ise rehber sırasında açılan sayfa, alt
  /// sayfa ve diyaloglar kapanır, başlangıç sayfasına dönülür; kapı, kapanan
  /// sayfaların animasyonu bitince kalkar (kapanırken attıkları istek de
  /// engellensin). Başlangıç sayfası artık yoksa yalnız kapatılır.
  Future<void> kapat({bool geriDon = false}) async {
    if (!acik || _durum == RehberDurumu.donus) return;
    final navigator = _navigator;
    final baslangic = _baslangic;
    if (!geriDon ||
        navigator == null ||
        !navigator.mounted ||
        baslangic == null ||
        !baslangic.isActive ||
        baslangic.isCurrent) {
      _temizle();
      OgrenmeKapisi.acik = false;
      notifyListeners();
      return;
    }
    _saat?.cancel();
    _yanlisSaati?.cancel();
    _durum = RehberDurumu.donus;
    _delik = null;
    notifyListeners();
    FocusManager.instance.primaryFocus?.unfocus();
    final kapananlar = <TransitionRoute<dynamic>>[];
    navigator.popUntil((r) {
      if (r == baslangic) return true;
      if (r is TransitionRoute) kapananlar.add(r);
      return false;
    });
    // Engellenen isteklerin hata mesajları başlangıç sayfasında kalmasın.
    ScaffoldMessenger.maybeOf(navigator.context)?.clearSnackBars();
    await Future.wait([for (final r in kapananlar) r.completed])
        .timeout(const Duration(seconds: 2), onTimeout: () => const []);
    await WidgetsBinding.instance.endOfFrame;
    // Bu arada yeni bir rehber başladıysa ona dokunma.
    if (_durum != RehberDurumu.donus) return;
    _temizle();
    OgrenmeKapisi.acik = false;
    notifyListeners();
  }

  void _temizle() {
    _saat?.cancel();
    _yanlisSaati?.cancel();
    _saat = null;
    _durum = RehberDurumu.kapali;
    _gorev = null;
    _adim = 0;
    _delik = null;
    _dokunuldu = false;
    _yanlis = false;
    _denendi = false;
    _hedefYok = false;
    _bitisteUstteSayfa = false;
    _kayip = 0;
    _gorunmez = 0;
    _navigator = null;
    _baslangic = null;
  }

  /// Bir tur: ekrana bakıp adımı ilerletir, geri alır ya da deliği izler.
  @visibleForTesting
  void izle() {
    if (_durum == RehberDurumu.bitis) return _bitisiIzle();
    final gorev = _gorev;
    final b = bulucu;
    if (gorev == null || b == null || _durum != RehberDurumu.adim) return;
    if (!(_baslangic?.isActive ?? false)) {
      kapat();
      return;
    }
    final adim = gorev.adimlar[_adim];
    final simdiki = b.bul(adim.hedef);
    if (!adim.bilgi &&
        _adim + 1 < gorev.adimlar.length &&
        (adim.atlanabilir || _dokunuldu || simdiki == null)) {
      final sonraki = b.bul(gorev.adimlar[_adim + 1].hedef);
      if (sonraki != null) {
        _git(_adim + 1, sonraki);
        return;
      }
    }
    if (simdiki != null) {
      _kayip = 0;
      _goster(simdiki);
      return;
    }
    if (++_kayip < _kayipSabri) return;
    for (var j = _adim - 1; j >= 0; j--) {
      final onceki = b.bul(gorev.adimlar[j].hedef);
      if (onceki != null) {
        _git(j, onceki);
        return;
      }
    }
    if (_delik != null || !_hedefYok) {
      _delik = null;
      _hedefYok = true;
      notifyListeners();
    }
  }

  void _git(int adim, HedefSonucu hedef) {
    _adim = adim;
    _dokunuldu = false;
    _yanlis = false;
    _kayip = 0;
    _gorunmez = 0;
    _goster(hedef, bildir: true);
  }

  void _goster(HedefSonucu hedef, {bool bildir = false}) {
    // Ekran dışındaki (kaydırılmış, klavye altında) hedef ortaya kaydırılır;
    // kaydırma yetmezse yaklaşık saniyede bir yeniden denenir.
    if (hedef.gorunur) {
      _gorunmez = 0;
    } else if (_gorunmez++ % 10 == 0) {
      bulucu?.kaydir(hedef);
    }
    final yeni = hedef.gorunur ? hedef.alan : null;
    if (bildir || yeni != _delik || _hedefYok) {
      _delik = yeni;
      _hedefYok = false;
      notifyListeners();
    }
  }

  /// Parlayan yerden geçen dokunuş (katman bildirir).
  void delikDokunusu() {
    final gorev = _gorev;
    if (gorev == null || _durum != RehberDurumu.adim) return;
    final adim = gorev.adimlar[_adim];
    if (adim.kalici) {
      _denendi = true;
      _bitir();
    } else if (!adim.bilgi && _adim == gorev.adimlar.length - 1) {
      _bitir();
    } else {
      _dokunuldu = true;
    }
  }

  /// Parlayan yer dışına dokunuş: kısa bir uyarı.
  void yanlisDokunus() {
    if (_durum != RehberDurumu.adim) return;
    _yanlis = true;
    _yanlisSaati?.cancel();
    _yanlisSaati = Timer(const Duration(seconds: 2), () {
      _yanlis = false;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Okuma adımını geçer.
  void anladim() {
    final gorev = _gorev;
    if (gorev == null || _durum != RehberDurumu.adim) return;
    if (_adim == gorev.adimlar.length - 1) {
      _bitir();
      return;
    }
    _adim++;
    _dokunuldu = false;
    _yanlis = false;
    _kayip = 0;
    _gorunmez = 0;
    notifyListeners();
    izle();
  }

  void _bitir() {
    _durum = RehberDurumu.bitis;
    _bitisteUstteSayfa = !(_baslangic?.isCurrent ?? true);
    _delik = null;
    _yanlis = false;
    notifyListeners();
  }

  /// Bitişte geri tuşu: üstteki alt sayfa geri tuşuyla kapandıysa dönüş
  /// butonu gibi davranılır; başlangıç sayfası kapandıysa rehber kapanır.
  void _bitisiIzle() {
    final baslangic = _baslangic;
    if (baslangic == null || !baslangic.isActive) {
      kapat();
    } else if (_bitisteUstteSayfa && baslangic.isCurrent) {
      kapat(geriDon: true);
    }
  }
}
