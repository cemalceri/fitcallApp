// Rehber balonunun yerleşim kuralı (rehber_balonu.dart): balon parlayan
// yerin hemen altında, yer yoksa üstünde; ikisine de sığmazsa deliğin altı
// kırpılır. Delik her zaman güvenli alanın içinde kalır (halka ekranda).

import 'package:fitcall/screens/1_common/ogrenme/rehber_balonu.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// 390×844, durum çubuğu 47, alt çubuk 34.
const _guvenli = Rect.fromLTRB(0, 47, 390, 810);
const _balon = Size(358, 90);

BalonYeri _yer(Rect hedef, {Size balon = _balon, Rect guvenli = _guvenli}) =>
    balonYeri(
      delik: delikHesapla(hedef, guvenli),
      guvenli: guvenli,
      balon: balon,
    );

void main() {
  test('üst yarıdaki hedef: balon hemen altta, ok hedefin ortasında', () {
    const hedef = Rect.fromLTWH(16, 290, 358, 68);
    final y = _yer(hedef);
    expect(y.ok, OkYonu.yukari);
    expect(y.sol.dy, closeTo(hedef.bottom + BalonOlcu.pay + BalonOlcu.dis, 0.01));
    expect(y.okX, closeTo(hedef.center.dx, 0.01));
    expect(y.sol.dx, BalonOlcu.yan);
  });

  test('en alttaki hedef: balon üstte, ok aşağı', () {
    const hedef = Rect.fromLTWH(16, 740, 358, 52);
    final y = _yer(hedef);
    expect(y.ok, OkYonu.asagi);
    expect(y.sol.dy + _balon.height,
        closeTo(hedef.top - BalonOlcu.pay - BalonOlcu.dis, 0.01));
  });

  test('sağ üst köşedeki ikon: delik daire, ok sağa kayar, balon kenarda',
      () {
    const hedef = Rect.fromLTWH(334, 51, 48, 48);
    final delik = delikHesapla(hedef, _guvenli)!;
    expect(delik.top, greaterThanOrEqualTo(_guvenli.top + BalonOlcu.delikKenari));
    expect(delik.right,
        lessThanOrEqualTo(_guvenli.right - BalonOlcu.delikKenari));
    final y = _yer(hedef);
    expect(y.ok, OkYonu.yukari);
    expect(y.sol.dx + _balon.width, closeTo(390 - BalonOlcu.yan, 0.01));
    expect(y.okX, greaterThan(300));
    expect(y.okX,
        lessThanOrEqualTo(y.sol.dx + _balon.width - BalonOlcu.kose));
    final sekil = delikSekli(delik);
    expect(sekil.tlRadiusX, closeTo(delik.shortestSide / 2, 0.01));
  });

  test('küçük hedef en az 44×44 delik açar', () {
    final delik = delikHesapla(const Rect.fromLTWH(100, 300, 16, 16), _guvenli)!;
    expect(delik.width, greaterThanOrEqualTo(BalonOlcu.enKucukDelik));
    expect(delik.height, greaterThanOrEqualTo(BalonOlcu.enKucukDelik));
    expect(delik.center, const Offset(108, 308));
  });

  test('ekran genişliğinde, ekranın altına uzanan liste: delik ekranda, '
      'balon üstte', () {
    // Borç dökümü alt sayfası (0.75): liste 0…390 × 345…844.
    const hedef = Rect.fromLTRB(0, 345, 390, 844);
    final delik = delikHesapla(hedef, _guvenli)!;
    expect(delik, const Rect.fromLTRB(8, 339, 382, 802));
    final y = _yer(hedef, balon: const Size(358, 160));
    expect(y.ok, OkYonu.asagi);
    expect(y.delik, delik);
    expect(y.sol.dy, greaterThanOrEqualTo(_guvenli.top + BalonOlcu.dikey));
  });

  test('iki yana da sığmayan hedef: balon altta, deliğin altı kırpılır', () {
    // Alt sayfa 0.95'e çekilmiş: liste 0…390 × 177…844.
    const hedef = Rect.fromLTRB(0, 177, 390, 844);
    const balon = Size(358, 160);
    final y = _yer(hedef, balon: balon);
    expect(y.ok, OkYonu.yukari);
    final delik = y.delik!;
    expect(delik.top, 171);
    expect(delik.height, greaterThanOrEqualTo(BalonOlcu.enAzDelik));
    expect(y.sol.dy + balon.height,
        closeTo(_guvenli.bottom - BalonOlcu.dikey, 0.01));
    expect(y.sol.dy, closeTo(delik.bottom + BalonOlcu.dis, 0.01));
  });

  test('kırpınca çok kısa kalan delik: balon oksuz, hedefe uzak kenarda', () {
    const guvenli = Rect.fromLTRB(0, 0, 320, 568);
    const hedef = Rect.fromLTRB(0, 60, 320, 568);
    final y = _yer(hedef, balon: const Size(288, 480), guvenli: guvenli);
    expect(y.ok, OkYonu.yok);
    expect(y.delik, delikHesapla(hedef, guvenli));
  });

  test('klavye açık: balon klavyenin üstünde, yazı kutusunun üstünde', () {
    // Klavye 300 px: güvenli alan 544'te biter; kutu klavyenin hemen üstünde.
    const guvenli = Rect.fromLTRB(0, 47, 390, 544);
    const kutu = Rect.fromLTWH(16, 470, 358, 56);
    final y = _yer(kutu, guvenli: guvenli);
    expect(y.ok, OkYonu.asagi);
    expect(y.sol.dy + _balon.height, lessThan(kutu.top));
  });

  test('hedef yok: balon güvenli alanın altına yaslı, ok yok', () {
    final y = balonYeri(delik: null, guvenli: _guvenli, balon: _balon);
    expect(y.ok, OkYonu.yok);
    expect(y.delik, isNull);
    expect(y.sol.dy + _balon.height,
        closeTo(_guvenli.bottom - BalonOlcu.dikey, 0.01));
  });

  test('bitiş: delik kapandıysa kart son parlayan yerin yanında, oksuz', () {
    const son = Rect.fromLTWH(16, 200, 358, 60);
    final y = balonYeri(
        delik: null, konum: son, guvenli: _guvenli, balon: _balon);
    expect(y.ok, OkYonu.yok);
    expect(y.sol.dy, closeTo(son.bottom + BalonOlcu.pay + BalonOlcu.dis, 0.01));
  });

  test('dar ekranda balon genişliği kenar boşluklarına uyar', () {
    expect(balonGenisligi(const Rect.fromLTWH(0, 0, 320, 568)), 288);
    expect(balonGenisligi(const Rect.fromLTWH(0, 0, 800, 1200)),
        BalonOlcu.enGenis);
  });
}
