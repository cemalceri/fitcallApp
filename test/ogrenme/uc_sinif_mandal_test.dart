// Öğrenme modu kapısı fail-closed çalışır: sınıflanmamış uç engellenir. Bu
// mandal, lib/'deki her ucun (`$baseUrl/<ad>`) okuma, altyapı ya da yazma
// kümesinden tam olarak birinde durmasını ister; yeni bir uç eklenince
// lib/services/ogrenme/uc_siniflari.dart'ta sınıflandırılmalı.

import 'dart:io';

import 'package:fitcall/services/ogrenme/uc_siniflari.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _koddakiUclar() {
  final desen = RegExp(r'\$baseUrl/([A-Za-z0-9_]+)');
  return {
    for (final dosya in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      for (final m in desen.allMatches(dosya.readAsStringSync())) m[1]!,
  };
}

void main() {
  final uclar = _koddakiUclar();

  test('koddaki her uç sınıflandırılmış', () {
    expect(uclar, isNotEmpty);
    final eksik = uclar
        .where((u) =>
            !okumaUclari.contains(u) &&
            !altyapiUclari.contains(u) &&
            !yazmaUclari.contains(u))
        .toList()
      ..sort();
    expect(eksik, isEmpty,
        reason: "Yeni uç veri değiştiriyor mu? Backend view'ına bakıp "
            "uc_siniflari.dart'ta okuma ya da yazma kümesine ekle.");
  });

  test('bir uç tek kümede durur', () {
    expect(okumaUclari.intersection(yazmaUclari), isEmpty);
    expect(okumaUclari.intersection(altyapiUclari), isEmpty);
    expect(yazmaUclari.intersection(altyapiUclari), isEmpty);
  });

  test('kümelerde koddan silinmiş uç kalmaz', () {
    final fazla = {...okumaUclari, ...altyapiUclari, ...yazmaUclari}
        .difference(uclar)
        .toList()
      ..sort();
    expect(fazla, isEmpty);
  });

  test('ucAdi /api/ sonrasındaki ilk parçayı alır', () {
    expect(
        ucAdi('https://www.binay.fit/api/getTeyitDetay?x=1'), 'getTeyitDetay');
    expect(ucAdi('https://www.binay.fit/api/n/'), 'n');
    expect(ucAdi('https://www.binay.fit/api/ofisUyeDetay/12/'), 'ofisUyeDetay');
    expect(ucAdi('https://ornek.com/a/b'), 'b');
  });
}
