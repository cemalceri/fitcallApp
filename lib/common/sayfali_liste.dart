// lib/common/sayfali_liste.dart
//
// Aşağı kaydırdıkça sayfa sayfa yüklenen listenin durumu (ofis ve yönetici
// üye listeleri).
//
// Önceden bütün üyeler tek istekte geliyor, arama telefonda yapılıyordu;
// liste uzadıkça ilk açılış yavaşlıyordu. Artık sunucu 20'şer döndürüyor,
// arama ve filtre de sunucuda. Arama yazılırken eski bir istek yenisinden
// sonra dönebilir: her yeniden başlatma yeni bir "nesil" açar, eski nesilden
// dönen cevap atılır.

import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/foundation.dart';

/// Tek sayfanın sonucu.
class SayfaSonucu<T> {
  final List<T> ogeler;
  final int toplamSayfa;

  /// Filtre + aramaya uyan toplam kayıt (yalnız bu sayfa değil).
  final int toplam;

  const SayfaSonucu({
    required this.ogeler,
    required this.toplamSayfa,
    required this.toplam,
  });
}

/// 1'den başlayan sayfa numarasıyla bir sayfayı getirir.
typedef SayfaGetirici<T> = Future<SayfaSonucu<T>> Function(int sayfa);

class SayfaliListe<T> extends ChangeNotifier {
  /// [anahtar] verilirse eklenen sayfada önceden gelmiş kayıt atlanır: liste
  /// offset ile sayfalanıyor, kaydırırken araya kayıt eklenir/silinirse
  /// sayfa sınırındaki satır iki kez gelebilir.
  SayfaliListe(this._getir, {Object? Function(T)? anahtar}) : _anahtar = anahtar;

  SayfaGetirici<T> _getir;
  final Object? Function(T)? _anahtar;

  /// Yenileme sürüyor (iskeletli ya da iskeletsiz). Bu sırada sonraki sayfa
  /// istenmez: eski sayfa numarasıyla gelen cevap yeni listenin arkasına
  /// eklenip kayıt kaybı/tekrarı doğuruyordu.
  bool _yenileniyor = false;

  List<T> _ogeler = const [];
  int _sayfa = 0;
  int _toplamSayfa = 0;
  int? _toplam;
  bool _ilkYukleniyor = true;
  bool _dahaYukleniyor = false;
  String? _hata;
  String? _dahaHatasi;

  /// [_dahaHatasi] aşağı çekip yenilemeden geldi: "Tekrar dene" sonraki
  /// sayfayı değil ilk sayfayı yeniden ister (eldeki liste eskidi).
  bool _yenilemeHatasi = false;
  int _nesil = 0;
  bool _kapandi = false;

  List<T> get ogeler => _ogeler;

  /// Filtre + aramaya uyan toplam kayıt; ilk sayfa gelene kadar null.
  int? get toplam => _toplam;

  /// İlk sayfa yükleniyor (iskelet gösterilir).
  bool get ilkYukleniyor => _ilkYukleniyor;

  /// Sonraki sayfa yükleniyor (listenin sonunda iskelet satırları).
  bool get dahaYukleniyor => _dahaYukleniyor;

  /// İlk sayfa alınamadı; liste yerine hata gösterilir.
  String? get hata => _hata;

  /// Sonraki sayfa alınamadı; liste durur, sonunda "Tekrar dene" çıkar.
  String? get dahaHatasi => _dahaHatasi;

  bool get dahaVar => _sayfa < _toplamSayfa;

  /// Listeyi ilk sayfadan yeniden yükler. [getir] verilirse filtre/arama
  /// değişmiştir, bundan sonraki sayfalar onunla istenir.
  ///
  /// [iskelet] false ise (aşağı çekip yenileme) mevcut liste cevap gelene
  /// kadar ekranda kalır.
  Future<void> yenile({bool iskelet = true, SayfaGetirici<T>? getir}) async {
    if (getir != null) _getir = getir;
    final nesil = ++_nesil;
    if (iskelet) _ilkYukleniyor = true;
    _yenileniyor = true;
    _hata = null;
    _dahaHatasi = null;
    _yenilemeHatasi = false;
    _dahaYukleniyor = false;
    _bildir();

    try {
      final sonuc = await _getir(1);
      if (nesil != _nesil || _kapandi) return;
      _ogeler = List.unmodifiable(sonuc.ogeler);
      _sayfa = 1;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (e) {
      if (nesil != _nesil || _kapandi) return;
      // Aşağı çekip yenilemede hata: eldeki liste silinmez, mesaj liste
      // sonunda görünür; ilk yüklemede liste yerine hata.
      if (iskelet || _ogeler.isEmpty) {
        _hata = hataMesaji(e);
      } else {
        _dahaHatasi = hataMesaji(e);
        _yenilemeHatasi = true;
      }
    }
    _ilkYukleniyor = false;
    _yenileniyor = false;
    _bildir();
  }

  /// Sonraki sayfayı ekler. Yükleme sürerken, hata varken ya da sayfa
  /// kalmadıysa hiçbir şey yapmaz — kaydırma her karede çağırabilir.
  Future<void> dahaFazla() async {
    if (!dahaVar ||
        _dahaYukleniyor ||
        _yenileniyor ||
        _hata != null ||
        _dahaHatasi != null) {
      return;
    }
    await _sonrakiSayfa();
  }

  /// Sonraki sayfa hatasından sonra kullanıcının "Tekrar dene"si.
  Future<void> dahaTekrarDene() async {
    if (_dahaYukleniyor || _yenileniyor) return;
    _dahaHatasi = null;
    // Hata yenilemeden geldiyse (eldeki liste korunmuştu) baştan yükle.
    if (_yenilemeHatasi || !dahaVar || _sayfa == 0) {
      await yenile(iskelet: false);
      return;
    }
    await _sonrakiSayfa();
  }

  Future<void> _sonrakiSayfa() async {
    final nesil = _nesil;
    final istenen = _sayfa + 1;
    _dahaYukleniyor = true;
    _bildir();

    try {
      final sonuc = await _getir(istenen);
      if (nesil != _nesil || _kapandi || _sayfa != istenen - 1) return;
      _ogeler = List.unmodifiable([..._ogeler, ..._yeniler(sonuc.ogeler)]);
      _sayfa = istenen;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (e) {
      if (nesil != _nesil || _kapandi) return;
      _dahaHatasi = hataMesaji(e);
    }
    _dahaYukleniyor = false;
    _bildir();
  }

  Iterable<T> _yeniler(List<T> gelen) {
    final anahtar = _anahtar;
    if (anahtar == null) return gelen;
    final varOlan = {for (final o in _ogeler) anahtar(o)};
    return gelen.where((o) => varOlan.add(anahtar(o)));
  }

  static String hataMesaji(Object e) => e is ApiException
      ? e.message
      : 'Veriler yüklenirken bir hata oluştu.';

  void _bildir() {
    if (!_kapandi) notifyListeners();
  }

  @override
  void dispose() {
    _kapandi = true;
    super.dispose();
  }
}
