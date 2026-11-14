// Yönetici Ekip ve "Ödeme onay bekliyor" rehberlerinin hedefleri: her biri
// ekranda bir kez durur; antrenör kartı hedefi yoklama hapları çizilen
// (dersi olan) ilk karttadır, listenin ilkinde değil.

import 'package:fitcall/models/9_yonetici/bekleyen_dekont_models.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/7_yonetici/dekont/bekleyen_dekontlar_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _hedef(String id) =>
    find.byWidgetPredicate((w) => w is OgrenmeHedefi && w.id == id);

Future<void> _ciz(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('Ekip: hedefler tek, antrenör hedefi dersi olan kartta',
      (tester) async {
    await _ciz(
      tester,
      EkipGorunumu(
        onKisi: (_) {},
        data: EkipData.fromJson({
          'donem': 'bu_ay',
          'ozet': {'kisi_sayisi': 2, 'gelen_sayisi': 1},
          'kisiler': [
            {'id': 1, 'ad_soyad': 'Ayşe Ofis', 'giris_gun_sayisi': 3},
            {'id': 2, 'ad_soyad': 'Ece Su'},
          ],
          'antrenorler': [
            {'id': 7, 'ad_soyad': 'Dersi Yok'},
            {'id': 8, 'ad_soyad': 'Can Hoca', 'ders_sayisi': 4, 'yoklama_bekleyen': 2},
          ],
        }),
      ),
    );

    for (final id in [
      Hedef.ekipOfisOzeti,
      Hedef.ekipKisiKarti,
      Hedef.ekipAntrenorOzeti,
      Hedef.ekipAntrenorKarti,
    ]) {
      expect(_hedef(id), findsOneWidget, reason: id);
    }
    expect(
      find.descendant(
          of: _hedef(Hedef.ekipAntrenorKarti), matching: find.text('Can Hoca')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: _hedef(Hedef.ekipKisiKarti), matching: find.text('Ayşe Ofis')),
      findsOneWidget,
    );
  });

  testWidgets('Ekip: dersi olan antrenör yoksa kart hedefi konmaz',
      (tester) async {
    await _ciz(
      tester,
      EkipGorunumu(
        onKisi: (_) {},
        data: EkipData.fromJson({
          'antrenorler': [
            {'id': 7, 'ad_soyad': 'Dersi Yok'},
          ],
        }),
      ),
    );
    expect(_hedef(Hedef.ekipAntrenorOzeti), findsOneWidget);
    expect(_hedef(Hedef.ekipAntrenorKarti), findsNothing);
  });

  testWidgets('Dekontlar: özet ve ilk satır hedef; boş listede yok',
      (tester) async {
    final dekontlar = BekleyenDekont.liste({
      'dekontlar': [
        {'id': 1, 'uye_adi': 'Deniz Arslan', 'beyan_tutar': '1500.00'},
        {'id': 2, 'uye_adi': 'Can Ek', 'beyan_tutar': '900.00'},
      ],
    });
    await _ciz(
      tester,
      BekleyenDekontlarGorunumu(dekontlar: dekontlar, onDekont: (_) {}),
    );
    expect(_hedef(Hedef.dekontOzeti), findsOneWidget);
    expect(
      find.descendant(
          of: _hedef(Hedef.dekontSatiri), matching: find.text('Deniz Arslan')),
      findsOneWidget,
    );

    await _ciz(tester, const BekleyenDekontlarGorunumu(dekontlar: []));
    expect(_hedef(Hedef.dekontOzeti), findsNothing);
    expect(_hedef(Hedef.dekontSatiri), findsNothing);
  });
}
