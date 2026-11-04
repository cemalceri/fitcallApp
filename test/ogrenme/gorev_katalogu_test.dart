// Rehber kataloğunun yapısı ve yazım kuralları; ekrandaki karşılıkların
// kodda durduğu (buton yazısı, hedef kimliği). Ekranla gerçek uyumu sürücü
// testi (uye_takvim_rehber_test.dart) doğrular.

import 'dart:io';

import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:flutter_test/flutter_test.dart';

/// «…» içindeki buton adı tek kelime sayılır.
int _kelime(String metin) => metin
    .replaceAll(RegExp('«[^»]+»'), 'X')
    .split(RegExp(r'\s+'))
    .where((k) => k.isNotEmpty)
    .length;

/// Rehber klasörü dışındaki ekran kodu.
String _ekranKodu() => [
      for (final dosya in Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.dart') &&
              !f.path.replaceAll(r'\', '/').contains('/ogrenme/')))
        dosya.readAsStringSync(),
    ].join('\n');

/// hedefler.dart'taki sabitin adı ("takvim.ders" → "takvimDers").
String? _sabitAdi(String id) {
  final kaynak =
      File('lib/screens/1_common/ogrenme/hedefler.dart').readAsStringSync();
  return RegExp("static const (\\w+) = '${RegExp.escape(id)}';")
      .firstMatch(kaynak)?[1];
}

void main() {
  final kod = _ekranKodu();

  test('kimlikler eşsiz', () {
    final idler = ogrenmeGorevleri.map((g) => g.id).toList();
    expect(idler.toSet(), hasLength(idler.length));
  });

  for (final g in ogrenmeGorevleri) {
    group(g.id, () {
      test('soru ve adım biçimi', () {
        expect(g.baslik, endsWith('?'));
        expect(g.adimlar, isNotEmpty);
        for (final a in g.adimlar) {
          expect(_kelime(a.metin), lessThanOrEqualTo(8), reason: a.metin);
          expect(a.metin, endsWith('.'), reason: a.metin);
          expect(a.kalici && a.bilgi, isFalse, reason: a.metin);
        }
        if (g.kural != null) {
          expect('.'.allMatches(g.kural!).length, lessThanOrEqualTo(2));
        }
      });

      test('yalnız son adım kalıcı, kalıcının sonucu yazılı', () {
        for (final (i, a) in g.adimlar.indexed) {
          if (a.kalici) {
            expect(i, g.adimlar.length - 1, reason: a.metin);
            expect(a.sonuc, isNotNull, reason: a.metin);
          }
          if (a.atlanabilir) {
            expect(i, lessThan(g.adimlar.length - 1), reason: a.metin);
          }
        }
      });

      test('hedefler ekran kodunda duruyor', () {
        for (final a in g.adimlar) {
          switch (a.hedef) {
            case MetinSecici(:final metin):
              expect(kod.contains("'$metin'"), isTrue,
                  reason: '"$metin" yazılı buton ekranda yok; '
                      'buton adı değiştiyse rehberi güncelle.');
            case HedefSecici(:final id):
              final sabit = _sabitAdi(id);
              expect(sabit, isNotNull, reason: "$id hedefler.dart'ta yok");
              expect(kod.contains('Hedef.$sabit'), isTrue,
                  reason: '$id hiçbir ekranda OgrenmeHedefi ile sarılı değil.');
          }
        }
      });
    });
  }
}
