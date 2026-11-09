// Rehber kataloğunun motorun (ogrenme_modu.dart) gerektirdiği kuralları.
// Biçim ve "hedef ekran kodunda var mı" kuralları gorev_katalogu_test.dart'ta;
// burada yalnız motorun davranışından doğan kurallar var:
//
// - `yoksa` yazısı ancak «Anladım»a basılıp sonraki hedef bulunamayınca
//   çıkar: «Anladım» yalnız okuma adımında var, son adımda «Anladım» rehberi
//   bitirir. Yazılmazsa motor dokunulur adımda "seç", yalnız okunan adımda
//   «Kapat» diyen varsayılanı gösterir.
// - Seçim adımı (okuma + dokunulur + atlanabilir): sonraki hedef kullanıcının
//   seçimine bağlıdır, «Anladım»da yokken ne yapılacağı (`yoksa`) yazılır.
// - `sonuc` yalnız kalıcı adımda gösterilir, `dokunulur` yalnız okuma adımında
//   bir şey değiştirir; başka yerde yazılmaları rehberin yanlış kurulduğunu
//   gösterir.

import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('katalog boş değil', () {
    expect(ogrenmeGorevleri, isNotEmpty);
  });

  for (final g in ogrenmeGorevleri) {
    test('${g.id}: adım bayrakları motorla uyumlu', () {
      final son = g.adimlar.length - 1;
      for (final (i, a) in g.adimlar.indexed) {
        final yer = '${g.id} ${i + 1}/${g.adimlar.length} "${a.metin}"';
        if (a.yoksa != null) {
          expect(a.bilgi, isTrue,
              reason: '$yer: `yoksa` yalnız okuma adımında çıkar');
          expect(i, lessThan(son),
              reason: '$yer: son adımda «Anladım» rehberi bitirir');
          expect(a.yoksa, endsWith('.'), reason: yer);
        }
        if (a.bilgi && a.dokunulur && a.atlanabilir) {
          expect(a.yoksa, isNotNull,
              reason: '$yer: seçim adımında sonraki hedef seçime bağlı; '
                  '«Anladım»da yokken ne yapılacağını `yoksa` ile yaz');
        }
        if (a.sonuc != null) {
          expect(a.kalici, isTrue,
              reason: '$yer: `sonuc` yalnız kalıcı adımda gösterilir');
        }
        if (a.dokunulur) {
          expect(a.bilgi, isTrue,
              reason: '$yer: `dokunulur` yalnız okuma adımında anlamlı');
        }
      }
    });
  }
}
