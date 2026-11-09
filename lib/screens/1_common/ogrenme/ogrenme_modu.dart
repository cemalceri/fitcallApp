// lib/screens/1_common/ogrenme/ogrenme_modu.dart
//
// Rehberin durumu ve adım motoru. Katman (ogrenme_katmani.dart) bunu dinleyip
// çizer; ekranlar bilmez. Motor ekrana bakarak ilerler: kullanıcı parlayan
// yere dokunur, sonraki adımın hedefi açık sayfada belirince adım geçer.
// Kullanıcı geri dönerse (alt sayfayı kapatırsa) ekranda duran önceki adıma
// iner. Her giriş baştan başlar; rehber açıkken yazma istekleri ağa çıkmaz.
// Bitince ya da "Kapat" denince rehber sırasında açılan her şey kapanır,
// "?"ye dokunulan sayfaya dönülür; kapı ancak dönüş bitince kalkar.
// Başlangıç sayfası bir kabuk sekmesiyse sekme de geri gelir; o sayfada
// geri tuşu rehberi kapatır.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:fitcall/screens/1_common/ogrenme/hedef_bulucu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';

/// [donus]: başlangıç sayfasına dönülüyor; dokunuşlar yutulur, kapı açık.
enum RehberDurumu { kapali, adim, bitis, donus }

/// Rehberin başladığı kabuk sekmesi. Sekmeler aynı rotada durduğu için
/// sayfa dönüşü (`popUntil`) sekmeyi geri getirmez; bu bilgiyle getirilir.
class RehberSekmesi {
  final int sekme;
  final int Function() aktif;
  final ValueChanged<int> gec;

  const RehberSekmesi({
    required this.sekme,
    required this.aktif,
    required this.gec,
  });
}

/// Başlangıç sayfasında geri tuşu: sayfayı (ya da kabuğu) kapatmaz,
/// rehberi kapatır.
class _GeriTusu extends PopEntry<Object?> {
  final VoidCallback onGeri;

  _GeriTusu(this.onGeri);

  /// Hiç değişmez; her rehberde yenisini kurup sızdırmamak için ortak.
  static final _hayir = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get canPopNotifier => _hayir;

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    // Navigator kayıtlı girişleri dolaşırken çağırır; kapatmak girişi
    // kaydından siler, bu yüzden dolaşma bittikten sonra.
    if (!didPop) scheduleMicrotask(onGeri);
  }
}

class OgrenmeModu extends ChangeNotifier {
  OgrenmeModu._();

  static final OgrenmeModu ornek = OgrenmeModu._();

  /// Katman kurulunca verilir; yoksa rehber başlamaz, liste okumaya düşer.
  HedefBulucu? bulucu;

  /// Hedef kaybolunca geçiş animasyonu için beklenen tur sayısı.
  static const _kayipSabri = 4;

  /// Parlayan yere dokunulduktan sonra: sonraki ekran bir istek bekliyor
  /// olabilir (ör. seçilen üyenin adı sorulurken not penceresi gecikir);
  /// bu arada önceki adıma inilmez.
  static const _dokunusSabri = 20;
  static const _tur = Duration(milliseconds: 100);

  RehberDurumu _durum = RehberDurumu.kapali;
  OgrenmeGorevi? _gorev;
  int _adim = 0;
  Rect? _delik;
  Rect? _sonDelik;
  bool _menuAcik = false;

  /// Bu adımın hedefi bir kez yerine kaydırıldı mı (yarım görünüyorsa).
  bool _yerlesti = false;
  int _yanlisSayaci = 0;
  bool _dokunuldu = false;
  bool _yanlis = false;
  bool _denendi = false;
  bool _hedefYok = false;
  bool _sonrakiYok = false;
  bool _bitisteUstteSayfa = false;
  int _kayip = 0;
  int _gorunmez = 0;
  NavigatorState? _navigator;
  Route<dynamic>? _baslangic;
  RehberSekmesi? _sekme;
  _GeriTusu? _geriTusu;
  Timer? _saat;
  Timer? _yanlisSaati;

  RehberDurumu get durum => _durum;
  bool get acik => _durum != RehberDurumu.kapali;
  OgrenmeGorevi? get gorev => _gorev;
  int get adimNo => _adim;
  OgrenmeAdimi? get adim => _gorev == null || _durum != RehberDurumu.adim
      ? null
      : _gorev!.adimlar[_adim];

  /// Parlayan alan: hedefin görünen kısmı (katman koordinatı); hedef ekranda
  /// yoksa null. Bitişte son adımın hedefi hâlâ görünüyorsa odur.
  Rect? get delik => _delik;

  /// Son parlayan yer: bitiş kartı onun altında ya da üstünde çıkar.
  Rect? get sonDelik => _sonDelik;

  /// Açılır liste ya da menü açık: balon onun seçeneklerini örtmesin.
  bool get menuAcik => _menuAcik;

  /// Her yanlış dokunuşta artar (balon her seferinde yeniden sallanır).
  int get yanlisSayaci => _yanlisSayaci;

  /// Adımın hedefi açık sayfada yok (kullanıcı başka ekrana geçti).
  bool get hedefYok => _hedefYok;

  /// «Anladım»a basıldı ama sonraki adımın hedefi ekranda yok; adım
  /// değişince ya da sonraki hedef belirince kalkar.
  bool get sonrakiYok => _sonrakiYok;

  /// Kullanıcı parlayan yer dışına dokundu (kısa süre gösterilir).
  bool get yanlis => _yanlis;

  /// Son butona dokunuldu ("Denemeydi, herhangi bir işlem yapılmadı.").
  bool get denendi => _denendi;

  /// [gorev]'i [baslangic] sayfasında baştan başlatır. [sekme]: başlangıç
  /// sayfası kabuk sekmesiyse hangisi olduğu.
  void baslat(
    OgrenmeGorevi gorev, {
    required NavigatorState navigator,
    required Route<dynamic> baslangic,
    RehberSekmesi? sekme,
  }) {
    _temizle();
    _gorev = gorev;
    _durum = RehberDurumu.adim;
    _navigator = navigator;
    _baslangic = baslangic;
    _sekme = sekme;
    if (baslangic is ModalRoute) {
      final geri = _GeriTusu(() => kapat(geriDon: true));
      baslangic.registerPopEntry(geri);
      _geriTusu = geri;
    }
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
    final sekme = _sekme;
    if (geriDon) _cekmeceleriKapat();
    if (!geriDon ||
        navigator == null ||
        !navigator.mounted ||
        baslangic == null ||
        !baslangic.isActive ||
        baslangic.isCurrent) {
      if (geriDon && (baslangic?.isActive ?? false)) _sekmeyiGetir(sekme);
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
    _sekmeyiGetir(sekme);
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

  static void _sekmeyiGetir(RehberSekmesi? sekme) {
    if (sekme != null && sekme.aktif() != sekme.sekme) sekme.gec(sekme.sekme);
  }

  /// Rehber sırasında açılan sol menü (çekmece) rota değildir, sayfa dönüşü
  /// onu kapatmaz; kabuklarda çekmece dıştaki Scaffold'dadır. Açık her
  /// çekmece kapanır.
  void _cekmeceleriKapat() {
    final kok = bulucu?.uygulama.currentContext ?? _navigator?.context;
    if (kok is! Element) return;
    void gez(Element e) {
      if (e is StatefulElement) {
        final durum = e.state;
        if (durum is ScaffoldState) {
          if (durum.isDrawerOpen) durum.closeDrawer();
          if (durum.isEndDrawerOpen) durum.closeEndDrawer();
        }
      }
      e.visitChildElements(gez);
    }

    kok.visitChildElements(gez);
  }

  void _temizle() {
    final geri = _geriTusu;
    final baslangic = _baslangic;
    if (geri != null && baslangic is ModalRoute) {
      baslangic.unregisterPopEntry(geri);
    }
    _geriTusu = null;
    _sekme = null;
    _saat?.cancel();
    _yanlisSaati?.cancel();
    _saat = null;
    _durum = RehberDurumu.kapali;
    _gorev = null;
    _adim = 0;
    _delik = null;
    _sonDelik = null;
    _menuAcik = false;
    _dokunuldu = false;
    _yanlis = false;
    _denendi = false;
    _hedefYok = false;
    _sonrakiYok = false;
    _bitisteUstteSayfa = false;
    _kayip = 0;
    _gorunmez = 0;
    _yerlesti = false;
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
    // Başlangıç sayfasında sekme değişti (kabuğun geri tuşu ya da menü):
    // rehber biter, sekme geri gelir.
    final sekme = _sekme;
    if (sekme != null &&
        (_baslangic?.isCurrent ?? false) &&
        sekme.aktif() != sekme.sekme) {
      kapat(geriDon: true);
      return;
    }
    final adim = gorev.adimlar[_adim];
    final simdiki = b.adimHedefi(adim);
    // Atlanabilir adım (okuma adımı da) sonraki hedef görününce geçilir.
    if (_adim + 1 < gorev.adimlar.length &&
        (adim.atlanabilir ||
            (!adim.bilgi && (_dokunuldu || simdiki == null)))) {
      final sonraki = _ilerideki(b, gorev, _adim + 1);
      if (sonraki != null) {
        _git(sonraki.$1, sonraki.$2);
        return;
      }
    }
    if (simdiki != null) {
      _kayip = 0;
      _goster(simdiki);
      return;
    }
    // Açılır liste ya da menü açık: seçenekler deliğin dışında, perde
    // kalkar; menü kapanınca hedef yeniden görünür ve adım sürer.
    if (_menuUstte()) {
      _kayip = 0;
      if (_delik != null || !_menuAcik) {
        _delik = null;
        _menuAcik = true;
        notifyListeners();
      }
      return;
    }
    if (_menuAcik) {
      _menuAcik = false;
      notifyListeners();
    }
    if (++_kayip < (_dokunuldu ? _dokunusSabri : _kayipSabri)) return;
    for (var j = _adim - 1; j >= 0; j--) {
      final onceki = b.adimHedefi(gorev.adimlar[j]);
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

  /// [i]. adımdan başlayarak ekranda hedefi olan ilk adım ve hedefi;
  /// hedefi olmayan atlanabilir adımın üstünden geçilir (yoklaması girilmiş
  /// derste pencere doğrudan ayrıntıda açılır, «Eksik ya da fazla var»
  /// adımı hiç görünmez). Atlanabilir olmayan adımda hedef yoksa null.
  (int, HedefSonucu)? _ilerideki(HedefBulucu b, OgrenmeGorevi gorev, int i) {
    for (var j = i; j < gorev.adimlar.length; j++) {
      final adim = gorev.adimlar[j];
      final hedef = b.adimHedefi(adim);
      if (hedef != null) return (j, hedef);
      if (!adim.atlanabilir) return null;
    }
    return null;
  }

  /// En üstteki rota bir seçim menüsü mü (DropdownButton, showMenu)? İkisi
  /// de PopupRoute'tur; diyalog ve alt sayfa da PopupRoute olduğu için
  /// onlar ayrılır (onların içindeki öğeler hedef olarak aranır).
  bool _menuUstte() {
    final navigator = _navigator;
    if (navigator == null || !navigator.mounted) return false;
    Route<dynamic>? ust;
    // Koşul en üstteki rotada hemen doğru döner: hiçbir şey kapanmaz.
    navigator.popUntil((r) {
      ust = r;
      return true;
    });
    return ust is PopupRoute &&
        ust is! RawDialogRoute &&
        ust is! ModalBottomSheetRoute;
  }

  void _git(int adim, HedefSonucu hedef) {
    _adim = adim;
    _dokunuldu = false;
    _yanlis = false;
    _sonrakiYok = false;
    _kayip = 0;
    _gorunmez = 0;
    _yerlesti = false;
    _goster(hedef, bildir: true);
  }

  void _goster(HedefSonucu hedef, {bool bildir = false}) {
    // Ekran dışındaki (kaydırılmış, klavye altında) hedef ortaya kaydırılır;
    // kaydırma yetmezse yaklaşık saniyede bir yeniden denenir.
    if (hedef.gorunur) {
      _gorunmez = 0;
      // Adımın ilk gösteriminde yarım görünen hedef (ör. sayfanın altındaki
      // kart) bir kez ortaya kaydırılır; sonra kullanıcının kaydırmasına
      // karışılmaz.
      if (!_yerlesti && hedef.kesik) bulucu?.kaydir(hedef);
      _yerlesti = true;
    } else if (_gorunmez++ % 10 == 0) {
      bulucu?.kaydir(hedef);
    }
    final yeni = hedef.gorunur ? hedef.gorunen : null;
    if (yeni != null) _sonDelik = yeni;
    if (bildir || yeni != _delik || _hedefYok || _menuAcik) {
      _delik = yeni;
      _hedefYok = false;
      _menuAcik = false;
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
      // Dokunuş butona geçer; buton alt sayfayı kendisi kapatabilir (ör.
      // filtreyi uygula), bu kapanış geri tuşu sayılmasın.
      _bitir(geriIzle: false);
    } else {
      _dokunuldu = true;
    }
  }

  /// Parlayan yer dışına dokunuş: kısa bir uyarı.
  void yanlisDokunus() {
    if (_durum != RehberDurumu.adim) return;
    _yanlis = true;
    _yanlisSayaci++;
    _yanlisSaati?.cancel();
    _yanlisSaati = Timer(const Duration(seconds: 2), () {
      _yanlis = false;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Okuma adımını geçer. Sonraki adımın hedefi açık sayfada yoksa geçmez:
  /// geçseydi motor hedefsiz adımdan hemen bu adıma geri inerdi (antrenör
  /// takviminde seçili günde yoklaması girilmiş ders yokken 2/4 → 1/4).
  /// Bunun yerine balon sallanır, adımın [OgrenmeAdimi.yoksa] yazısı çıkar.
  void anladim() {
    final gorev = _gorev;
    if (gorev == null || _durum != RehberDurumu.adim) return;
    if (_adim == gorev.adimlar.length - 1) {
      _bitir();
      return;
    }
    final b = bulucu;
    final sonraki = b == null ? null : _ilerideki(b, gorev, _adim + 1);
    if (b != null && sonraki == null) {
      _sonrakiYok = true;
      _yanlisSayaci++;
      notifyListeners();
      return;
    }
    if (sonraki != null) {
      _git(sonraki.$1, sonraki.$2);
      return;
    }
    _adim++;
    _dokunuldu = false;
    _yanlis = false;
    _sonrakiYok = false;
    _kayip = 0;
    _gorunmez = 0;
    notifyListeners();
    izle();
  }

  /// [geriIzle]: bitişte üstte duran sayfanın kapanması geri tuşu sayılır
  /// (rehber başlangıç sayfasına döner).
  void _bitir({bool geriIzle = true}) {
    _durum = RehberDurumu.bitis;
    _bitisteUstteSayfa = geriIzle && !(_baslangic?.isCurrent ?? true);
    // Delik kalır: son parlayan yer hâlâ ekrandaysa bitiş kartı ona bağlanır
    // (bkz. _bitisiIzle).
    _yanlis = false;
    notifyListeners();
  }

  /// Bitişte geri tuşu: üstteki alt sayfa geri tuşuyla kapandıysa dönüş
  /// butonu gibi davranılır; başlangıç sayfası kapandıysa rehber kapanır.
  /// Son adımın hedefi görünürken parlamaya devam eder; kaybolursa (son
  /// dokunuş alt sayfayı kapattı) delik kapanır, kart son yerinde kalır.
  void _bitisiIzle() {
    final baslangic = _baslangic;
    if (baslangic == null || !baslangic.isActive) {
      kapat();
      return;
    }
    if (_bitisteUstteSayfa && baslangic.isCurrent) {
      kapat(geriDon: true);
      return;
    }
    final gorev = _gorev;
    final b = bulucu;
    if (gorev == null || b == null) return;
    final son = b.adimHedefi(gorev.adimlar[_adim]);
    final yeni = son != null && son.gorunur ? son.gorunen : null;
    if (yeni != _delik) {
      _delik = yeni;
      if (yeni != null) _sonDelik = yeni;
      notifyListeners();
    }
  }
}
