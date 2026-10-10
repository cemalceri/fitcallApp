// test/support/gradyan.dart
//
// Gradyan örnekleme yardımcısı: kontrast ve tema testleri gradyanı Flutter'ın
// yaptığı gibi (duraklar arası sRGB karışımı) eşit aralıklı noktalarda okur.

import 'package:flutter/material.dart';

/// [g] gradyanını eşit aralıklı [n] noktada örnekler.
List<Color> gradyanOrnekle(Gradient g, {int n = 41}) {
  final renkler = g.colors;
  final duraklar = g.stops ??
      List<double>.generate(renkler.length, (i) => i / (renkler.length - 1));
  return List<Color>.generate(n, (i) {
    final x = i / (n - 1);
    var j = 0;
    while (j < renkler.length - 2 && x > duraklar[j + 1]) {
      j++;
    }
    final a = duraklar[j], b = duraklar[j + 1];
    final t = b == a ? 0.0 : ((x - a) / (b - a)).clamp(0.0, 1.0);
    return Color.lerp(renkler[j], renkler[j + 1], t)!;
  });
}

/// İki gradyan görsel olarak aynı mı (her örnek noktada kanal farkı ≤ [tolerans]).
bool gradyanlarAyni(Gradient a, Gradient b, {double tolerans = 0.004}) {
  final x = gradyanOrnekle(a), y = gradyanOrnekle(b);
  for (var i = 0; i < x.length; i++) {
    if ((x[i].r - y[i].r).abs() > tolerans ||
        (x[i].g - y[i].g).abs() > tolerans ||
        (x[i].b - y[i].b).abs() > tolerans) {
      return false;
    }
  }
  return true;
}
