// QR doğrulama sonuç ekranı.
//
// Eskiden her hata aynı gri "Bilgi" kartına düşüyordu; backend'in hata kodu
// kullanılmadığı için "süresi dolmuş" ile "kod bu tesise ait değil" görevliye
// aynı görünüyordu. Bu testler kod → durum eşlemesini ve ekranın her durumda
// çizilebildiğini sabitliyor.

import 'package:fitcall/screens/1_common/widgets/qr_sonuc_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

QrSonucu _hata(String kod, [String mesaj = 'mesaj']) =>
    QrSonucu.hatadan(ApiException(kod, mesaj), zaman: DateTime(2026, 7, 23, 14, 32));

void main() {
  setUpAll(() async => initializeDateFormatting('tr_TR'));

  group('Backend hata kodu → ekran durumu', () {
    test('süresi dolmuş kod ayrı durum', () {
      expect(_hata('QR_EXPIRED').tip, QrSonucTipi.suresiDolmus);
    });

    test('bulunamayan kod ayrı durum', () {
      expect(_hata('QR_NOT_FOUND').tip, QrSonucTipi.bulunamadi);
    });

    test('geçersiz kod ayrı durum', () {
      expect(_hata('INVALID_QR').tip, QrSonucTipi.gecersiz);
    });

    test('iptal edilmiş giriş ayrı durum', () {
      expect(_hata('ENTRY_CANCELED').tip, QrSonucTipi.iptalEdilmis);
    });

    test('etkinlik durumları tek başlıkta toplanır', () {
      for (final kod in ['EVENT_PASSIVE', 'EVENT_NOT_STARTED', 'EVENT_FINISHED']) {
        expect(_hata(kod).tip, QrSonucTipi.etkinlikUygunDegil, reason: kod);
      }
    });

    test('bilinmeyen kod genel hataya düşer', () {
      expect(_hata('SERVER_ERROR').tip, QrSonucTipi.hata);
      expect(_hata('TIMEOUT').tip, QrSonucTipi.hata);
    });

    test('backend mesajı korunur', () {
      expect(_hata('QR_EXPIRED', 'QR kodun süresi dolmuş').mesaj,
          'QR kodun süresi dolmuş');
    });

    test('yalnız başarı durumu basarili sayılır', () {
      expect(_hata('QR_EXPIRED').basarili, isFalse);
      expect(
        QrSonucu(
          tip: QrSonucTipi.basarili,
          mesaj: 'Hoşgeldiniz, Ayşe Yılmaz',
          zaman: DateTime(2026, 7, 23),
        ).basarili,
        isTrue,
      );
    });
  });

  group('QrSonucGorunumu', () {
    Future<void> ciz(WidgetTester tester, QrSonucu sonuc,
        {Size boyut = const Size(360, 640)}) async {
      tester.view.physicalSize = boyut;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QrSonucGorunumu(sonuc: sonuc, onYenidenTara: () {}),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('başarıda kişinin adı ve onay başlığı görünür', (tester) async {
      await ciz(
        tester,
        QrSonucu(
          tip: QrSonucTipi.basarili,
          mesaj: 'Hoşgeldiniz, Ayşe Yılmaz',
          zaman: DateTime(2026, 7, 23, 14, 32),
        ),
      );

      expect(find.text('Hoşgeldiniz, Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('Giriş onaylandı'), findsOneWidget);
      expect(find.text('Okutuldu · 14:32'), findsOneWidget);
      expect(find.text('Sonrakini tara'), findsOneWidget);
    });

    testWidgets('süresi dolmuşta ne yapılacağı yazıyor', (tester) async {
      await ciz(tester, _hata('QR_EXPIRED', 'QR kodun süresi dolmuş'));

      expect(find.text('Kodun süresi dolmuş'), findsOneWidget);
      expect(find.textContaining('yeni kod üretmesini'), findsOneWidget);
    });

    testWidgets('bulunamadıda başlık artık ham mesaj değil', (tester) async {
      await ciz(tester, _hata('QR_NOT_FOUND', 'QR kod bulunamadı'));

      expect(find.text('Kayıt bulunamadı'), findsOneWidget);
      expect(find.text('QR kod bulunamadı'), findsOneWidget);
    });

    testWidgets('bitir düğmesi yalnız geri çağrım verilince çıkar',
        (tester) async {
      await ciz(tester, _hata('QR_NOT_FOUND'));
      expect(find.text('Bitir'), findsNothing);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QrSonucGorunumu(
            sonuc: _hata('QR_NOT_FOUND'),
            onYenidenTara: () {},
            onBitir: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Bitir'), findsOneWidget);
    });

    testWidgets('yeniden tara geri çağrımı tetiklenir', (tester) async {
      var tetiklendi = false;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QrSonucGorunumu(
            sonuc: _hata('QR_EXPIRED'),
            onYenidenTara: () => tetiklendi = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sonrakini tara'));
      expect(tetiklendi, isTrue);
    });

    testWidgets('uzun mesaj küçük ekranda taşma vermez', (tester) async {
      await ciz(
        tester,
        QrSonucu(
          tip: QrSonucTipi.basarili,
          mesaj: 'Hoşgeldiniz, Abdurrahman Çelebioğulları Karahisarlıoğlu',
          zaman: DateTime(2026, 7, 23, 9, 5),
        ),
        boyut: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('her durum çizilebilir', (tester) async {
      for (final tip in QrSonucTipi.values) {
        await ciz(
          tester,
          QrSonucu(tip: tip, mesaj: 'Deneme', zaman: DateTime(2026, 7, 23)),
        );
        expect(tester.takeException(), isNull, reason: tip.name);
      }
    });
  });
}
