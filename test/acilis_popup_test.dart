// Açılış popup'ları: kurallar (doğum günü, yayın aralığı, özet) ve popup
// ekranlarının davranışı. Taşma matrisi: tasma_ekranlar_test.dart.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/dogum_gunu_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/duyuru_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/konfeti_patlamasi.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_detay_sheet.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_varsayilan_poster.dart';
import 'package:fitcall/services/core/acilis_popup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DuyuruModel _duyuru({
  String altBaslik = '',
  String icerik = '',
  String? bitis = '2026-10-31T23:59:00+03:00',
  List<Map<String, dynamic>> resimler = const [],
}) =>
    DuyuruModel.fromMap({
      'id': 3,
      'baslik': 'Kış kampı kayıtları açıldı',
      'alt_baslik': altBaslik,
      'icerik': icerik,
      'resimler': resimler,
      'yayin_baslangic': '2026-10-01T09:00:00+03:00',
      'yayin_bitis': bitis,
    });

Future<void> _ac(WidgetTester tester, Widget popup,
    {bool hareketiAzalt = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: FitcallTema.acik,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: hareketiAzalt,
      ),
      child: Scaffold(body: popup),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr', null);
  });

  group('dogumGunuMu', () {
    test('ay ve gün eşleşince kutlanır, yıl önemsiz', () {
      expect(dogumGunuMu(DateTime(2012, 10, 9), DateTime(2026, 10, 9, 8)),
          isTrue);
      expect(dogumGunuMu(DateTime(2012, 10, 9), DateTime(2026, 10, 10)),
          isFalse);
      expect(dogumGunuMu(DateTime(2012, 9, 10), DateTime(2026, 10, 9)),
          isFalse);
    });

    test('1 Ocak doğum tarihi hiç kutlanmaz (yer tutucu/sahte tarih)', () {
      expect(dogumGunuMu(DateTime(2000, 1, 1), DateTime(2026, 1, 1)), isFalse);
    });

    test('29 Şubat: artık yılda 29\'unda, diğer yıllarda 28\'inde', () {
      final dogum = DateTime(2012, 2, 29);
      expect(dogumGunuMu(dogum, DateTime(2028, 2, 29)), isTrue);
      expect(dogumGunuMu(dogum, DateTime(2028, 2, 28)), isFalse);
      expect(dogumGunuMu(dogum, DateTime(2027, 2, 28)), isTrue);
      expect(dogumGunuMu(dogum, DateTime(2027, 3, 1)), isFalse);
    });
  });

  group('popupYayindaMi', () {
    final simdi = DateTime(2026, 10, 9, 12);

    test('yayın aralığındaysa gösterilir', () {
      expect(popupYayindaMi(_duyuru(), simdi), isTrue);
    });

    test('bitişi olmayan ya da süresi geçmiş duyuru gösterilmez', () {
      expect(popupYayindaMi(_duyuru(bitis: null), simdi), isFalse);
      expect(popupYayindaMi(_duyuru(), DateTime(2026, 11, 1)), isFalse);
      expect(popupYayindaMi(_duyuru(), DateTime(2026, 9, 30)), isFalse);
    });
  });

  group('duyuruPopupOzeti / duyuruDetayiVarMi', () {
    test('alt başlık doluysa özet odur', () {
      final d = _duyuru(altBaslik: '  7-14 yaş, kontenjan sınırlı ', icerik: 'x');
      expect(duyuruPopupOzeti(d), '7-14 yaş, kontenjan sınırlı');
    });

    test('alt başlık boşsa içerik tek satıra indirgenir', () {
      final d = _duyuru(icerik: 'Kayıtlar\n\nofiste   alınır.');
      expect(duyuruPopupOzeti(d), 'Kayıtlar ofiste alınır.');
    });

    test('içerik ya da ikinci bir görsel yoksa detay yok', () {
      expect(duyuruDetayiVarMi(_duyuru()), isFalse);
      expect(duyuruDetayiVarMi(_duyuru(icerik: 'Ayrıntı')), isTrue);
      expect(
        duyuruDetayiVarMi(_duyuru(resimler: [
          {'id': 1, 'url': 'https://ornek/1.jpg'},
          {'id': 2, 'url': 'https://ornek/2.jpg'},
        ])),
        isTrue,
      );
    });
  });

  group('DuyuruPopup', () {
    testWidgets('görselsiz duyuruda varsayılan poster ve iki buton',
        (tester) async {
      var kapat = 0, detay = 0;
      await _ac(
        tester,
        DuyuruPopup(
          duyuru: _duyuru(altBaslik: 'Kontenjan sınırlı', icerik: 'Ayrıntı'),
          onKapat: () => kapat++,
          onDetay: () => detay++,
        ),
      );

      expect(find.byType(DuyuruVarsayilanPoster), findsOneWidget);
      expect(find.text('Kış kampı kayıtları açıldı'), findsOneWidget);
      expect(find.text('Kontenjan sınırlı'), findsOneWidget);

      await tester.tap(find.text('Detaylı bilgi'));
      await tester.tap(find.text('Tamam'));
      await tester.tap(find.byTooltip('Kapat'));
      expect((detay, kapat), (1, 2));
    });

    testWidgets('detay yoksa yalnız Tamam', (tester) async {
      await _ac(tester, DuyuruPopup(duyuru: _duyuru(), onKapat: () {}));
      expect(find.text('Detaylı bilgi'), findsNothing);
      expect(find.text('Tamam'), findsOneWidget);
    });
  });

  group('DuyuruDetaySheet', () {
    // Koyu temada başlık ve içerik gömülü açık-tema renkleriyle (#111827,
    // #374151) çizildiği için okunmuyordu; artık tema rengini almalı.
    testWidgets('koyu temada başlık ve içerik tema yazı rengini alır',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: FitcallTema.koyu,
        home: Scaffold(
          body: DuyuruDetaySheet(
            duyuru: DuyuruModel.fromMap({
              'id': 0,
              'baslik': 'Kış kampı',
              'icerik': 'Kayıtlar ofiste.',
              'yayin_baslangic': '2026-10-01T09:00:00+03:00',
            }),
          ),
        ),
      ));
      await tester.pump();

      final yaziRengi = FitcallTema.koyu.colorScheme.onSurface;
      Color? renk(String metin) =>
          tester.widget<Text>(find.text(metin)).style?.color;
      expect(renk('Kış kampı'), yaziRengi);
      expect(renk('Kayıtlar ofiste.'), yaziRengi);
      expect(find.byType(DuyuruVarsayilanPoster), findsOneWidget);
    });
  });

  group('DogumGunuPopup', () {
    testWidgets('ad, kutlama metni ve imza; Teşekkürler kapatır',
        (tester) async {
      var kapat = 0;
      await _ac(
        tester,
        DogumGunuPopup(
          ad: 'Elif',
          imza: 'Binay Akademi',
          onKapat: () => kapat++,
        ),
      );

      expect(find.text('Elif'), findsOneWidget);
      expect(find.text(DogumGunuPopup.baslik), findsOneWidget);
      expect(find.text(DogumGunuPopup.dilek), findsOneWidget);
      expect(find.text('Binay Akademi'), findsOneWidget);

      await tester.tap(find.text('Teşekkürler'));
      expect(kapat, 1);

      // Animasyon bitince ağaç temiz kapanmalı.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('imza boşsa gösterilmez', (tester) async {
      await _ac(tester,
          DogumGunuPopup(ad: 'Elif', imza: null, onKapat: () {}));
      expect(find.text('Binay Akademi'), findsNothing);
    });

    testWidgets('"hareketi azalt" açıkken konfeti çizilmez', (tester) async {
      await _ac(
        tester,
        DogumGunuPopup(ad: 'Elif', onKapat: () {}),
        hareketiAzalt: true,
      );
      expect(
        find.descendant(
          of: find.byType(KonfetiPatlamasi),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });
}
