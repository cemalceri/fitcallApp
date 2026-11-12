// Kabuk geri tuşu: bir önceki sekmeye döner, önceki yoksa uygulama kapanır.

import 'package:fitcall/screens/1_common/widgets/sekme_gecmisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('geri tuşu ziyaret sırasının tersiyle döner, sonda kapanır', () {
    final g = SekmeGecmisi();
    var aktif = 0;
    void git(int yeni) {
      g.kaydet(aktif, yeni);
      aktif = yeni;
    }

    expect(g.kapatabilir(aktif), isTrue);
    git(4); // Ana Sayfa kartından Dersler
    git(1); // Raporlar
    expect(g.kapatabilir(aktif), isFalse);

    aktif = g.geriHedefi();
    expect(aktif, 4);
    aktif = g.geriHedefi();
    expect(aktif, 0);
    expect(g.kapatabilir(aktif), isTrue);
  });

  test('aynı sekme yığında bir kez durur', () {
    final g = SekmeGecmisi();
    g.kaydet(0, 2);
    g.kaydet(2, 0);
    g.kaydet(0, 2);
    expect(g.geriAl(), 0);
    expect(g.bos, isTrue);
  });

  test('geçmiş yokken başka sekmedeyse önce Ana Sayfa', () {
    final g = SekmeGecmisi();
    expect(g.kapatabilir(3), isFalse);
    expect(g.geriHedefi(), 0);
  });
}
