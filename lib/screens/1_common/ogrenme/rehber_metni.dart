// lib/screens/1_common/ogrenme/rehber_metni.dart

import 'package:flutter/material.dart';

/// Rehber cümlesindeki «buton adı»nı tırnaklı ve kalın yazar:
/// "«Katılamayacağım»a dokun." → “Katılamayacağım”a dokun.
TextSpan rehberMetni(String metin, {TextStyle? stil}) {
  final parcalar = <InlineSpan>[];
  var i = 0;
  for (final m in RegExp('«([^»]+)»').allMatches(metin)) {
    if (m.start > i) parcalar.add(TextSpan(text: metin.substring(i, m.start)));
    parcalar.add(TextSpan(
      text: '“${m[1]}”',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ));
    i = m.end;
  }
  if (i < metin.length) parcalar.add(TextSpan(text: metin.substring(i)));
  return TextSpan(style: stil, children: parcalar);
}

/// Son adımda butonun ne yapacağını söyleyen cümle.
String sonucCumlesi(String sonuc) =>
    'Buna basınca $sonuc. Şimdi basarsan bir şey olmaz.';
