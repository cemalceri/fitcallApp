// "?" rehberinin sürücü testi: üye takviminde "Derse gelemeyeceğimi nasıl
// bildiririm?" rehberi gerçek ekranda, sahte veriyle baştan sona yürünür.
// Ekranda buton adı ya da akış değişirse bu test kırılır; rehber güncellenir.

import 'dart:convert';

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_metni.dart';
import 'package:fitcall/screens/2_uye/takvim/uye_takvim_page.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/ders_detay_popup.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:fitcall/services/ogrenme/uc_siniflari.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../tool/magaza_gorselleri/demo_veri.dart' as demo;
import '../../tool/magaza_gorselleri/sahneler.dart' show uyeOturumu;

/// Sürmekte olan bir ders: hangi gün ve saatte çalışırsa çalışsın bu hafta
/// ve bitmemiş.
Map<String, Object?> _surenDers() {
  final simdi = simdiKulup();
  final gun = DateTime(simdi.year, simdi.month, simdi.day);
  final once = simdi.subtract(const Duration(minutes: 30));
  final baslangic = once.isBefore(gun) ? gun : once;
  return demo.ders(baslangic: baslangic, dakika: 120);
}

void main() {
  final modu = OgrenmeModu.ornek;
  late List<String> istekler;
  late List<Map<String, Object?>> dersler;

  final istemci = MockClient((istek) async {
    final uc = ucAdi(istek.url.toString());
    istekler.add(uc);
    if (uc == 'getUyeDersProgrami') {
      return http.Response.bytes(
          utf8.encode(jsonEncode({'data': dersler})), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
    return http.Response('{"detail": "yok"}', 404,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });

  setUpAll(() => initializeDateFormatting('tr', null));

  tearDown(() {
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  setUp(() {
    istekler = [];
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues(uyeOturumu());
  });

  Future<void> kur(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: const DersListesiPage(),
    ));
    await bekle(tester, 10);
  }

  Future<void> rehberiAc(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Nasıl yapılır?'));
    await bekle(tester, 5);
    expect(find.text('Bu sayfada ne öğrenmek istersin?'), findsOneWidget);
  }

  Future<void> deligeDokun(WidgetTester tester) async {
    final delik = modu.delik;
    expect(delik, isNotNull, reason: 'Parlayan yer yok (adım ${modu.adimNo})');
    await tester.tapAt(delik!.center);
    await bekle(tester, 6);
  }

  /// Rehberi açıp son butona kadar yürür.
  Future<void> bitiseYuru(WidgetTester tester) async {
    await rehberiAc(tester);
    await tester.tap(find.text('Derse gelemeyeceğimi nasıl bildiririm?'));
    await bekle(tester, 8);
    await deligeDokun(tester);
    await deligeDokun(tester);
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 8);
    await deligeDokun(tester);
    expect(modu.durum, RehberDurumu.bitis);
  }

  Future<void> kapatVeTemizle(WidgetTester tester) async {
    modu.kapat();
    await bekle(tester, 6);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets(
      'veri varken rehber ekranda baştan sona yürür, hiçbir şey '
      'gönderilmez', (tester) async {
    dersler = [_surenDers()];
    await http.runWithClient(() async {
      await kur(tester);
      await rehberiAc(tester);
      expect(find.text('Ekranda adım adım gösterilir.'), findsOneWidget);
      await tester.tap(find.text('Derse gelemeyeceğimi nasıl bildiririm?'));
      await bekle(tester, 8);

      // Ajandada ders zaten görünüyor: "güne dokun" adımı atlanır.
      expect(modu.durum, RehberDurumu.adim);
      expect(modu.adimNo, 1);
      final dersMerkezi = modu.delik!.center;

      // Parlayan yer dışına dokunuş durdurulur.
      await tester.tapAt(const Offset(20, 400));
      await bekle(tester, 2);
      expect(find.text('Parlayan yere dokun.'), findsOneWidget);
      expect(find.byType(DersDetayPopup), findsNothing);

      await deligeDokun(tester); // ders → detay açılır
      expect(find.byType(DersDetayPopup), findsOneWidget);
      expect(modu.adimNo, 2);

      await deligeDokun(tester); // "Katılamayacağım" → form açılır
      expect(modu.adimNo, 3);
      expect(find.text('Anladım'), findsOneWidget);

      await tester.tap(find.text('Anladım'));
      await bekle(tester, 8);
      expect(modu.adimNo, 4);
      expect(find.text(sonucCumlesi('ofise ve hocana haber gider')),
          findsOneWidget);

      await deligeDokun(tester); // son buton: basılmaz
      expect(modu.durum, RehberDurumu.bitis);
      expect(find.text('Denemeydi, bir şey olmadı.'), findsOneWidget);
      expect(find.text('Hepsi bu kadar'), findsOneWidget);
      expect(find.text('Şimdi yap'), findsNothing);
      expect(find.textContaining('Grup dersinde'), findsOneWidget);

      expect(OgrenmeKapisi.engellenenler, isEmpty);
      expect(istekler.where((u) => !okumaUclari.contains(u)), isEmpty,
          reason: 'Rehber sırasında yalnız okuma isteği gider: $istekler');

      // "Takvime dön": açılan alt sayfa kapanır; dönüş bitene kadar dokunuş
      // yutulur, kapı sonra kalkar.
      await tester.tap(find.text('Takvime dön'));
      await tester.pump();
      expect(modu.durum, RehberDurumu.donus);
      expect(OgrenmeKapisi.acik, isTrue);
      await tester.tapAt(dersMerkezi);
      await bekle(tester, 8);
      expect(modu.acik, isFalse);
      expect(find.byType(DersDetayPopup), findsNothing);
      expect(OgrenmeKapisi.acik, isFalse);
      await kapatVeTemizle(tester);
    }, () => istemci);
  });

  testWidgets('alt sayfa kapanınca rehber önceki adıma döner', (tester) async {
    dersler = [_surenDers()];
    await http.runWithClient(() async {
      await kur(tester);
      await rehberiAc(tester);
      await tester.tap(find.text('Derse gelemeyeceğimi nasıl bildiririm?'));
      await bekle(tester, 8);
      await deligeDokun(tester);
      expect(modu.adimNo, 2);

      Navigator.of(tester.element(find.byType(DersDetayPopup))).pop();
      await bekle(tester, 10);
      expect(modu.adimNo, 1);
      expect(modu.delik, isNotNull);
      await kapatVeTemizle(tester);
    }, () => istemci);
  });

  testWidgets('paneldeki Kapat da başlangıç sayfasına döner', (tester) async {
    dersler = [_surenDers()];
    await http.runWithClient(() async {
      await kur(tester);
      await rehberiAc(tester);
      await tester.tap(find.text('Derse gelemeyeceğimi nasıl bildiririm?'));
      await bekle(tester, 8);
      await deligeDokun(tester);
      expect(find.byType(DersDetayPopup), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(RehberAdimPaneli), matching: find.text('Kapat')));
      await bekle(tester, 8);
      expect(modu.acik, isFalse);
      expect(find.byType(DersDetayPopup), findsNothing);
      expect(OgrenmeKapisi.acik, isFalse);
      await kapatVeTemizle(tester);
    }, () => istemci);
  });

  testWidgets('bitişte geri tuşu da başlangıç sayfasına döndürür',
      (tester) async {
    dersler = [_surenDers()];
    await http.runWithClient(() async {
      await kur(tester);
      await bitiseYuru(tester);
      await tester.binding.handlePopRoute();
      await bekle(tester, 8);
      expect(modu.acik, isFalse);
      expect(find.byType(DersDetayPopup), findsNothing);
      expect(find.byType(DersListesiPage), findsOneWidget);
      expect(OgrenmeKapisi.acik, isFalse);
      await kapatVeTemizle(tester);
    }, () => istemci);
  });

  testWidgets('veri yokken rehber numaralı adımlarla okunur', (tester) async {
    dersler = [];
    await http.runWithClient(() async {
      await kur(tester);
      await rehberiAc(tester);
      expect(
          find.text('Takviminde ders olunca deneyebilirsin.'), findsOneWidget);
      await tester.tap(find.text('Derse gelemeyeceğimi nasıl bildiririm?'));
      await bekle(tester, 5);
      expect(modu.acik, isFalse);
      expect(find.text('Takviminde ders olunca ekranda deneyebilirsin.'),
          findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Dersten en az 24 saat önce'), findsOneWidget);
      await kapatVeTemizle(tester);
    }, () => istemci);
  });
}

/// Rehberin sürekli animasyonu yüzünden pumpAndSettle bitmez; adım adım ilerlet.
Future<void> bekle(WidgetTester tester, int tur) async {
  for (var i = 0; i < tur; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
