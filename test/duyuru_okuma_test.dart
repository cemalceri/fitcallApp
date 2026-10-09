// Yönetici/ofis "Duyurular" ekranı: model, biçim yardımcıları ve okuma
// durumu görünümünün davranışı. Taşma matrisi: tasma_ekranlar_test.dart.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_bicim.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_yonetim_listesi.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/okuma_durumu_gorunumu.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/duyuru_ornekleri.dart';

Future<void> _ac(WidgetTester tester, Widget w) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: FitcallTema.acik,
    home: Scaffold(body: w),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('tr', null));

  group('Model', () {
    test('okuma durumu ayrıştırılır, oran gören ∩ hedef üzerinden', () {
      final v = DuyuruOkumaDurumu.fromJson(okumaDurumuJson());
      expect(v.durum, DuyuruYayinDurumu.yayinda);
      expect(v.duyuru.popupGoster, isTrue);
      expect(v.ozet.oran, closeTo(54 / 142, 1e-9));
      expect(v.gordu.first.adlar, 'Can YILMAZ, Ece YILMAZ');
      expect(v.gordu.first.uyeProfilleri.length, 2);
      expect(v.gordu[1].uyeProfilleri, isEmpty); // antrenör: detaya gidilmez
      expect(v.gormedi.last.uygulamaKullaniyor, isFalse);
      expect(v.webDuzenleYolu, '/duyuru/7/duzenle/?isletme=1');
    });

    test('ölçülmeyen duyuruda oran yok', () {
      final s = DuyuruYonetimSatiri.fromJson({
        'id': 1,
        'baslik': 'Hocalara',
        'hedef_kitle': 'antrenorler',
        'durum': 'yayinda',
        'yayin_baslangic': '2026-10-01T09:00:00+03:00',
        'goren_sayisi': null,
        'hedef_sayisi': null,
      });
      expect(s.olculuyor, isFalse);
      expect(s.oran, isNull);
    });
  });

  group('Biçim', () {
    test('oran metni', () {
      expect(oranMetni(54 / 142), '%38');
      expect(oranMetni(1 / 1027), '<%1');
      expect(oranMetni(0), '%0');
    });

    test('yayın aralığı', () {
      expect(yayinAraligi(DateTime(2026, 10, 3), DateTime(2026, 10, 17)),
          '3–17 Eki');
      expect(yayinAraligi(DateTime(2026, 9, 28), DateTime(2026, 10, 5)),
          '28 Eyl – 5 Eki');
      expect(yayinAraligi(DateTime(2026, 10, 3), null), '3 Eki – süresiz');
    });

    test('Türkçe büyük harfli adlar küçük harfle aranır', () {
      expect(aramaBicimi('İpek IŞIK'), 'ipek ışık');
    });
  });

  group('OkumaDurumuGorunumu', () {
    testWidgets('segment geçişi, iki gruplu görmeyenler ve arama',
        (tester) async {
      await _ac(
        tester,
        OkumaDurumuGorunumu(
          veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson()),
          onIcerikGor: () {},
          onYenile: () async {},
          onHesapSec: (_) {},
        ),
      );

      expect(find.text('%38'), findsOneWidget);
      expect(find.text('54 / 142 hesap gördü'), findsOneWidget);
      expect(find.text('Can YILMAZ, Ece YILMAZ'), findsOneWidget);
      expect(find.text("Popup'ta gördü · Detayı açtı"), findsOneWidget);
      expect(find.text('Ana sayfadan açtı'), findsOneWidget);

      await tester.tap(find.text('Görmedi (2)'));
      await tester.pump();
      expect(find.text('Uygulamayı kullananlar'), findsOneWidget);
      expect(find.text('Uygulamayı kullanmayanlar'), findsOneWidget);
      expect(find.text('Ada DEMİR'), findsOneWidget);

      // Büyük harfli "IŞIK" küçük harfle bulunur; diğerleri süzülür.
      await tester.enterText(find.byType(TextField), 'ışık');
      await tester.pump();
      expect(find.text('İpek IŞIK'), findsOneWidget);
      expect(find.text('Ada DEMİR'), findsNothing);
    });

    testWidgets('yalnız üye profili olan satır tıklanır', (tester) async {
      final secilen = <int>[];
      await _ac(
        tester,
        OkumaDurumuGorunumu(
          veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson()),
          onIcerikGor: () {},
          onYenile: () async {},
          onHesapSec: (h) => secilen.add(h.hesapId),
        ),
      );

      await tester.tap(find.text('Murat Hoca')); // antrenör: gidilmez
      await tester.tap(find.text('Can YILMAZ, Ece YILMAZ'));
      expect(secilen, [1]);

      final antrenorSatiri = tester.widget<ListeSatiri>(find.ancestor(
          of: find.text('Murat Hoca'), matching: find.byType(ListeSatiri)));
      expect(antrenorSatiri.okGoster, isFalse);
    });

    testWidgets('planlı duyuruda liste yok, başlangıç bilgisi var',
        (tester) async {
      await _ac(
        tester,
        OkumaDurumuGorunumu(
          veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson(durum: 'planli')),
          onIcerikGor: () {},
          onYenile: () async {},
        ),
      );
      expect(find.text('Yayın henüz başlamadı'), findsOneWidget);
      expect(find.textContaining('Gördü ('), findsNothing);
      expect(find.text('Can YILMAZ, Ece YILMAZ'), findsNothing);
    });

    testWidgets('ölçülmeyen duyuruda segment yok, kayıtlar görünür',
        (tester) async {
      await _ac(
        tester,
        OkumaDurumuGorunumu(
          veri: DuyuruOkumaDurumu.fromJson(okumaDurumuJson(olculuyor: false)),
          onIcerikGor: () {},
          onYenile: () async {},
        ),
      );
      expect(find.textContaining('ölçülmüyor'), findsOneWidget);
      expect(find.textContaining('Görmedi'), findsNothing);
      expect(find.text('Can YILMAZ, Ece YILMAZ'), findsOneWidget);
    });
  });

  group('DuyuruYonetimListesi', () {
    testWidgets('gruplar, oran ve ölçülmeyen satır', (tester) async {
      DuyuruYonetimSatiri satir(int id, String durum,
              {int? goren, int? hedef, String kitle = 'herkes'}) =>
          DuyuruYonetimSatiri.fromJson({
            'id': id,
            'baslik': 'Duyuru $id',
            'hedef_kitle': kitle,
            'durum': durum,
            'yayin_baslangic': '2026-10-03T09:00:00+03:00',
            'yayin_bitis': '2026-10-17T23:59:00+03:00',
            'goren_sayisi': goren,
            'hedef_sayisi': hedef,
          });
      final secilen = <int>[];
      await _ac(
        tester,
        DuyuruYonetimListesi(
          duyurular: [
            satir(1, 'yayinda', goren: 54, hedef: 142),
            satir(2, 'planli', goren: 0, hedef: 142),
            satir(3, 'gecmis', kitle: 'antrenorler'),
          ],
          onSec: (d) => secilen.add(d.id),
          onYenile: () async {},
        ),
      );

      expect(find.text('Yayında'), findsOneWidget);
      expect(find.text('Planlanan'), findsOneWidget);
      expect(find.text('Geçmiş'), findsOneWidget);
      expect(find.text('%38'), findsOneWidget);
      expect(find.text('54/142'), findsOneWidget);
      expect(find.text('ölçülmüyor'), findsOneWidget);
      expect(find.text('Herkes · 3–17 Eki'), findsNWidgets(2));

      await tester.tap(find.text('Duyuru 1'));
      expect(secilen, [1]);
    });
  });
}
