// lib/screens/1_common/ogrenme/gorevler.dart
//
// Rehber kataloğu. Yazım kuralları: "sen" dili, emir kipi, adım başına tek
// cümle ve en çok 8 kelime, buton adı ekrandaki gibi «…» içinde. Yapı
// test/ogrenme/gorev_katalogu_test.dart ile, ekranla uyumu sürücü testiyle
// korunur.
//
// Ana sayfa turları (`*.anaSayfa`) yalnız okuma adımlarıdır; ilk giriş
// kartının «Başla»sı bunları açar.
//
// Rehberler rol dosyalarında (gorevler_<rol>.dart); bu dosya yalnız
// birleştirir. Rollerle ortak sayfalar gorevler_genel / gorevler_duyuru'da.

import 'package:fitcall/screens/1_common/ogrenme/gorevler_antrenor.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler_duyuru.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler_genel.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler_ofis.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler_uye.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler_yonetici.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> ogrenmeGorevleri = [
  ...uyeGorevleri,
  ...antrenorGorevleri,
  ...ofisGorevleri,
  ...yoneticiGorevleri,
  ...genelGorevler,
  ...duyuruGorevleri,
];

/// [sayfa]'nın rehberleri; [rol] verilirse yalnız o role açık olanlar.
List<OgrenmeGorevi> sayfaGorevleri(OgrenmeSayfasi sayfa, {String? rol}) =>
    ogrenmeGorevleri
        .where((g) => g.sayfa == sayfa && (rol == null || g.rolde(rol)))
        .toList();

OgrenmeGorevi gorevBul(String id) =>
    ogrenmeGorevleri.firstWhere((g) => g.id == id);
