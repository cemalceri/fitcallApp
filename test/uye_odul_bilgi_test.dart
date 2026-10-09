// Ödül sayacının "bu ne?" bilgi sayfası: ⓘ ve kart dokunuşu sayfayı açmalı,
// ödüle özgü metinler ödül tanımından gelmeli.

import 'package:fitcall/models/2_uye/uye_odul_model.dart';
import 'package:fitcall/screens/2_uye/home/widgets/uye_odul_sayaci.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

OdulDurumModel _durum({int sayac = 7, String? aciklama, int esik = 20}) =>
    OdulDurumModel.fromJson({
      'aktif': true,
      'odul_adi': 'Smoothie',
      'aciklama': aciklama,
      'ikon': 'smoothie',
      'esik': esik,
      'gecerlilik_gun': 10,
      'sayac': sayac,
      'kalan': esik - sayac,
      'hak_edildi': sayac >= esik,
    });

Widget _sar(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('ⓘ bilgi sayfasını ödül tanımının metinleriyle açar',
      (tester) async {
    await tester.pumpWidget(_sar(UyeOdulSayaci(
      durum: _durum(aciklama: 'Spor barda geçerlidir.'),
    )));

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Smoothie nasıl kazanılır?'), findsOneWidget);
    expect(find.text('Spor barda geçerlidir.'), findsOneWidget);
    expect(find.textContaining('20 güne ulaşınca'), findsOneWidget);
    expect(find.textContaining('Kod 10 gün geçerlidir'), findsOneWidget);
    expect(find.text('Şu an 7 / 20 · 13 gün kaldı'), findsOneWidget);
    // Tanımsız ikon anahtarı kahveye değil genel hediye ikonuna düşer.
    expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.local_cafe_rounded), findsNothing);

    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Smoothie nasıl kazanılır?'), findsNothing);
  });

  testWidgets('sayma aşamasında karta dokunmak da sayfayı açar',
      (tester) async {
    await tester.pumpWidget(_sar(UyeOdulSayaci(durum: _durum())));

    await tester.tap(find.text('Fincanın %35 dolu'));
    await tester.pumpAndSettle();

    expect(find.text('Smoothie nasıl kazanılır?'), findsOneWidget);
  });

  testWidgets('açıklama boşsa açıklama satırı çizilmez', (tester) async {
    await tester
        .pumpWidget(_sar(OdulBilgiSheet(durum: _durum(aciklama: '   '))));

    // Başlık + 4 kural + durum + buton; boş açıklama için ayrı Text yok.
    expect(find.text('   '), findsNothing);
    expect(find.textContaining('sayaç sıfırdan başlar'), findsOneWidget);
  });

  testWidgets('ödül hak edilince karta dokunmak sayfayı açmaz, ⓘ açar',
      (tester) async {
    await tester.pumpWidget(_sar(UyeOdulSayaci(
      durum: _durum(sayac: 20),
      onOdulAl: () async {},
    )));

    await tester.tap(find.text('Smoothie hakkını kazandın'));
    await tester.pumpAndSettle();
    expect(find.text('Smoothie nasıl kazanılır?'), findsNothing);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Ödülünü hak ettin, kodunu alabilirsin.'), findsOneWidget);
  });
}
