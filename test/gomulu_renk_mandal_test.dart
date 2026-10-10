// Gömülü renk mandalı.
//
// Renk temaları ancak ekranlar rengi temadan okursa çalışır: gömülü bir hex ya
// da `Colors.x` o ekranı temadan koparır, takım değişince yerinde kalır ve
// koyu modda "beyaz zemine beyaz yazı" doğurur. 2026-10 turunda 225 hex'in
// büyük kısmı token'a taşındı. Bu test sayıyı bugünkü değere kilitler: azalabilir,
// artamaz. Yeni ekran rengi `context.cs` / `context.renkler` / `context.gecis`
// üzerinden almalı; bilinçli bir sabit gerekiyorsa (QR'ın siyah-beyazı, top
// seviye renkleri gibi veri renkleri) taban sayıyı gerekçesiyle güncelleyin.
//
// Temizlenen eski palet (indigo, mor, turkuaz, pembe...) hiçbir yerde geri
// gelmemeli; o renkler uygulamayı rengarenk gösteren asıl kaynaktı.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Taban sayılar (2026-10). Düşürdükçe güncelleyin; artırmayın.
const int _hexTabani = 42;
const int _adliRenkTabani = 176;

/// Temaya ait olmayan, temizlenmiş eski palet.
const List<String> _yasakHexler = [
  '6366F1', // indigo
  '8B5CF6', // mor
  '7B2CBF', '9D4EDD', // telafi moru
  '2E7D6B', '4CAF93', '4FAE97', // QR turkuazı
  '3B82F6', // mavi
  '0EA5E9', // gök mavisi
  'EC4899', // pembe
  '25D366', // WhatsApp yeşili
  '2F6B5F', '4DB6AC', // QR doğrula ekranındaki eski turkuaz
];

Iterable<File> _dartDosyalari() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    // Tema dosyası renklerin tek kaynağı; sayıma girmez.
    .where((f) => !f.path.replaceAll(r'\', '/').endsWith('lib/common/tema.dart'));

void main() {
  final hexDeseni = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
  final adliDeseni = RegExp(r'\bColors\.(?!transparent\b)[a-zA-Z]+');

  test('gömülü hex renk sayısı tabanı aşmıyor', () {
    var toplam = 0;
    final dosyaBasina = <String, int>{};
    for (final f in _dartDosyalari()) {
      final n = hexDeseni.allMatches(f.readAsStringSync()).length;
      if (n > 0) dosyaBasina[f.path] = n;
      toplam += n;
    }
    expect(toplam, lessThanOrEqualTo(_hexTabani),
        reason: 'Gömülü Color(0x…) sayısı $toplam (taban $_hexTabani). '
            'Rengi temadan okuyun. Dosyalar: $dosyaBasina');
  });

  test('Colors.x kullanımı tabanı aşmıyor', () {
    var toplam = 0;
    for (final f in _dartDosyalari()) {
      toplam += adliDeseni.allMatches(f.readAsStringSync()).length;
    }
    expect(toplam, lessThanOrEqualTo(_adliRenkTabani),
        reason: 'Colors.x sayısı $toplam (taban $_adliRenkTabani). '
            'Rengi temadan okuyun.');
  });

  test('temizlenen eski palet geri gelmedi', () {
    final bulunan = <String>[];
    for (final f in _dartDosyalari()) {
      final s = f.readAsStringSync().toUpperCase();
      for (final hex in _yasakHexler) {
        if (s.contains('0XFF$hex')) bulunan.add('${f.path}: $hex');
      }
    }
    expect(bulunan, isEmpty);
  });
}
