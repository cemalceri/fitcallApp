// test/yonetim_yardim_test.dart
//
// Yönetici/ofis yardım sayfası tek dosyada iki kapsam taşıyor: sorular
// `_Kapsam` ile etiketli, sayfa role göre süzüyor. Süzme bozulursa ofis
// çalışanı hakediş ve ciro sorularını, yönetici de kendisinde olmayan program
// ekranının cevaplarını okur — antrenörde bir kez düzeltilen hatanın aynısı.
//
// Doğrulama ARAMA üzerinden yapılıyor: hem bölüm başlıkları hem soru kartları
// tembel (lazy) sliver'larda yaşıyor, ekranın altında kalan bir başlık hiç
// build edilmiyor. Aramak listeyi kısaltıp aranan kaydı görünür kılıyor.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/yonetim_yardim_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _ac(WidgetTester tester, {required bool ofis}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('tr', 'TR'),
    theme: FitcallTema.acik,
    home: YonetimYardimPage(ofis: ofis),
  ));
  await tester.pump();
}

Future<void> _ara(WidgetTester tester, String sorgu) async {
  await tester.enterText(find.byType(TextField), sorgu);
  await tester.pump();
}

/// Aranan metnin sonuçlarda çıkıp çıkmadığı.
Future<bool> _bulundu(
  WidgetTester tester, {
  required bool ofis,
  required String sorgu,
  required String beklenen,
}) async {
  await _ac(tester, ofis: ofis);
  await _ara(tester, sorgu);
  return find.textContaining(beklenen).evaluate().isNotEmpty;
}

void main() {
  group('Yönetim yardım sayfası — rol süzmesi', () {
    testWidgets('program soruları yalnız ofiste', (tester) async {
      expect(
        await _bulundu(tester,
            ofis: true,
            sorgu: 'program ekranını',
            beklenen: 'Program ekranını nasıl okurum'),
        isTrue,
      );
      expect(
        await _bulundu(tester,
            ofis: false,
            sorgu: 'program ekranını',
            beklenen: 'Program ekranını nasıl okurum'),
        isFalse,
      );
    });

    testWidgets('hakediş soruları yalnız yöneticide', (tester) async {
      expect(
        await _bulundu(tester,
            ofis: false,
            sorgu: 'hakediş saatleri ekranı',
            beklenen: 'Hakediş saatleri ekranı nasıl ilerliyor'),
        isTrue,
      );
      expect(
        await _bulundu(tester,
            ofis: true,
            sorgu: 'hakediş saatleri ekranı',
            beklenen: 'Hakediş saatleri ekranı nasıl ilerliyor'),
        isFalse,
      );
    });

    testWidgets('bakiye kırpması sorusu yalnız ofiste', (tester) async {
      expect(
        await _bulundu(tester,
            ofis: true,
            sorgu: 'bakiye ve borç',
            beklenen: 'bakiye ve borç neden görünmüyor'),
        isTrue,
      );
      expect(
        await _bulundu(tester,
            ofis: false,
            sorgu: 'bakiye ve borç',
            beklenen: 'bakiye ve borç neden görünmüyor'),
        isFalse,
      );
    });

    testWidgets('ortak sorular iki kabukta da var', (tester) async {
      for (final ofis in [true, false]) {
        expect(
          await _bulundu(tester,
              ofis: ofis,
              sorgu: 'birden fazla profil',
              beklenen: 'Birden fazla profilim var'),
          isTrue,
          reason: 'ofis=$ofis kabuğunda ortak soru kayboldu',
        );
      }
    });

    testWidgets('arama cevabın içinde de eşleşiyor', (tester) async {
      // "24 saat" soru başlıklarında geçmiyor, yalnız iptal modlarının
      // cevabında. Arama cevap metnini taramazsa bu soru bulunamaz.
      expect(
        await _bulundu(tester,
            ofis: true, sorgu: '24 saat', beklenen: 'işlem şekli'),
        isTrue,
      );
    });

    testWidgets('sonuç bulunamayan aramada boş durum çıkar', (tester) async {
      await _ac(tester, ofis: true);
      await _ara(tester, 'zzzzz');

      expect(find.textContaining('için sonuç yok'), findsOneWidget);
    });

    testWidgets('bölüm çipi seçilince diğer bölümün soruları gizlenir',
        (tester) async {
      await _ac(tester, ofis: true);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Üyeler'));
      await tester.pump();

      expect(find.textContaining('Program ekranını nasıl okurum'), findsNothing);
      expect(find.textContaining('Üye listesinde ne arayabilir'), findsOneWidget);
    });
  });
}
