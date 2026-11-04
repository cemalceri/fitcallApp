// lib/screens/1_common/ogrenme/gorevler.dart
//
// Rehber kataloğu. Yazım kuralları: "sen" dili, emir kipi, adım başına tek
// cümle ve en çok 8 kelime, buton adı ekrandaki gibi «…» içinde. Yapı
// test/ogrenme/gorev_katalogu_test.dart ile, ekranla uyumu sürücü testiyle
// korunur.

import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> ogrenmeGorevleri = [
  OgrenmeGorevi(
    id: 'uye.katilamayacagim',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Derse gelemeyeceğimi nasıl bildiririm?',
    kosulMetni: 'Takviminde ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDersliGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDers),
        metin: 'Gelecek bir dersine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılamayacağım'),
        metin: '«Katılamayacağım»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimAciklama),
        metin: 'İstersen kutuya nedenini yaz.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılamayacağımı Bildir'),
        metin: '«Katılamayacağımı Bildir»e dokun.',
        kalici: true,
        sonuc: 'ofise ve hocana haber gider',
      ),
    ],
    kural: 'Dersten en az 24 saat önce bildirirsen ders hakkın yanmaz. '
        'Daha geç bildirirsen ders hakkın yanar. '
        'Grup dersinde diğerleri geliyorsa ders iptal olmaz.',
  ),
];

List<OgrenmeGorevi> sayfaGorevleri(OgrenmeSayfasi sayfa) =>
    ogrenmeGorevleri.where((g) => g.sayfa == sayfa).toList();
