// test/kayit_sihirbazi_test.dart
//
// Üyelik başvuru sihirbazının akış kuralları.
//
// Kilitlenen davranışlar:
//   - eksik alanla adım ilerlemez (sunucuya boş başvuru gitmez),
//   - üçüncü adım doğum tarihine göre değişir: 18 yaş altı → veli bilgileri,
//   - 18 yaş altında veli adı + telefonu olmadan ilerlenemez (backend de
//     reddediyor; kullanıcı bunu son adımda değil orada öğrenmeli),
//   - gönderilen gövde backend'in beklediği alan adlarını taşır,
//   - doğum tarihi takvimi cihazın yazı ölçeği ne olursa olsun açılır.

import 'package:fitcall/common/ui_scale.dart';
import 'package:fitcall/models/4_auth/kayit_secenekleri_model.dart';
import 'package:fitcall/screens/4_auth/widgets/kayit_sihirbazi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _secenekler = KayitSecenekleri(
  isletmeler: [Secenek(deger: '1', etiket: 'Binay Tenis Akademi')],
  okullar: [Secenek(deger: '7', etiket: 'Cumhuriyet Ortaokulu')],
  cinsiyetler: [
    Secenek(deger: 'Erkek', etiket: 'Erkek'),
    Secenek(deger: 'Kadın', etiket: 'Kadın'),
  ],
  tenisGecmisi: [Secenek(deger: 'Yok', etiket: 'Yok')],
  programTercihleri: [Secenek(deger: 'Grup', etiket: 'Grup')],
);

/// Sihirbazı uygulamadaki kurulumla (tr-TR Material yerelleştirmesi) pump eder;
/// tarih seçicinin biçimi ve buton metinleri gerçek uygulamayla aynı olsun.
Future<void> _pump(
  WidgetTester tester, {
  Future<void> Function(Map<String, dynamic>)? onGonder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // Uygulamadaki yazı ölçeği sınırı burada da kurulu: doğum tarihi
      // takvimi bu clamp ile çakışıp patlamıştı (bkz. lib/common/ui_scale.dart).
      builder: yaziOlceginiSinirla,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: KayitSihirbazi(
            secenekler: _secenekler,
            onGonder: onGonder ?? (_) async {},
          ),
        ),
      ),
    ),
  );
}

/// Doğum tarihini takvim yerine metin girişiyle seçer (takvimde 20 yıl geri
/// gezinmek testte kırılgan olurdu).
Future<void> _dogumTarihiSec(WidgetTester tester, String gunAyYil) async {
  await tester.tap(find.text('Takvimden seçin'));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).last, gunAyYil);
  await tester.tap(find.text('Seç'));
  await tester.pumpAndSettle();
}

Future<void> _kimlikAdimiDoldur(
  WidgetTester tester, {
  required String dogumTarihi,
}) async {
  await tester.tap(find.text('Kulüp'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Binay Tenis Akademi').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextFormField, 'Ad'), 'Deniz');
  await tester.enterText(find.widgetWithText(TextFormField, 'Soyad'), 'Arslan');
  await _dogumTarihiSec(tester, dogumTarihi);
}

Future<void> _devam(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Devam'));
  await tester.tap(find.text('Devam'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr', null);
  });

  testWidgets('eksik alanla ilk adım geçilmez', (tester) async {
    await _pump(tester);

    await _devam(tester);

    expect(find.text('Ad gerekli'), findsOneWidget);
    expect(find.text('Kulüp seçin'), findsOneWidget);
    // Hâlâ ilk adımdayız.
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('yetişkinde üçüncü adım meslek sorar', (tester) async {
    await _pump(tester);

    await _kimlikAdimiDoldur(tester, dogumTarihi: '14.05.1994');
    await _devam(tester);

    expect(find.text('2 / 4'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cep telefonu'), '5551112233');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'), 'deniz@example.com');
    await _devam(tester);

    expect(find.text('Ek bilgiler'), findsOneWidget);
    expect(find.textContaining('Meslek'), findsWidgets);
    expect(find.text('Veli bilgileri'), findsNothing);
  });

  testWidgets('18 yaş altında veli adımı çıkar ve boş geçilemez',
      (tester) async {
    await _pump(tester);

    final cocukYili = DateTime.now().year - 10;
    await _kimlikAdimiDoldur(tester, dogumTarihi: '14.05.$cocukYili');
    await _devam(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cep telefonu'), '5551112233');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'), 'veli@example.com');
    await _devam(tester);

    expect(find.text('Veli bilgileri'), findsOneWidget);

    // Veli adı/telefonu girilmeden ilerlenemez.
    await _devam(tester);
    expect(find.textContaining('En az bir veli için ad-soyad ve telefon'),
        findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
  });

  // Takvim, uygulamanın yazı ölçeği clamp'i ile Material tarih seçicisinin
  // kendi başlık clamp'i çakıştığı için açılmıyordu: cihaz ölçeği 1.0 (ya da
  // altı) iken seçici başlığı `min(mevcut ölçek, 1.4)` = 1.0 istiyor, bu da
  // bizim 1.0 alt sınırımızla bir noktaya çöküyordu. Küçük ve normal sistem
  // yazısı, kırılmanın görüldüğü iki durum.
  for (final cihazOlcegi in [0.85, 1.0]) {
    testWidgets('doğum tarihi takvimi açılır (cihaz ölçeği $cihazOlcegi)',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = cihazOlcegi;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pump(tester);

      await tester.tap(find.text('Takvimden seçin'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.text('Seç'), findsOneWidget);
    });
  }

  testWidgets('telefon 10 hane değilse uyarır', (tester) async {
    await _pump(tester);

    await _kimlikAdimiDoldur(tester, dogumTarihi: '14.05.1994');
    await _devam(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cep telefonu'), '555111');
    await _devam(tester);

    expect(find.text('10 hane olmalı (5551112233)'), findsOneWidget);
  });

  testWidgets('gönderilen gövde backend alan adlarını taşır', (tester) async {
    Map<String, dynamic>? gonderilen;
    await _pump(tester, onGonder: (alanlar) async => gonderilen = alanlar);

    await _kimlikAdimiDoldur(tester, dogumTarihi: '14.05.1994');
    await _devam(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cep telefonu'), '05551112233');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'), 'deniz@example.com');
    await _devam(tester);
    await _devam(tester); // yetişkin adımı: hepsi isteğe bağlı

    // Son adım: KVKK onayı olmadan gönderilemez.
    await tester.ensureVisible(find.text('Başvuruyu gönder'));
    await tester.tap(find.text('Başvuruyu gönder'));
    await tester.pumpAndSettle();
    expect(gonderilen, isNull);
    expect(
      find.textContaining('KVKK aydınlatma metnini onaylayın'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başvuruyu gönder'));
    await tester.pumpAndSettle();

    expect(gonderilen, isNotNull);
    expect(gonderilen!['isletme'], '1');
    expect(gonderilen!['adi'], 'Deniz');
    expect(gonderilen!['dogum_tarihi'], '1994-05-14');
    // Başındaki sıfır kullanıcının yazdığı gibi gidiyor; sunucu normalleştiriyor.
    expect(gonderilen!['telefon'], '05551112233');
    expect(gonderilen!['kvkk_onay'], true);
    // Yetişkinde veli alanları hiç gönderilmez.
    expect(gonderilen!['anne_adi_soyadi'], isNull);
  });
}
