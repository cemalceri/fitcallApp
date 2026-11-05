// Rehberin yarım görünen hedefi: adım başında ortaya kaydırılır, sonra
// kullanıcının kaydırmasına karışılmaz (sayfanın altındaki kart yalnız
// ince bir şerit olarak parlıyor, balon tek başına kalıyordu).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _gorev = OgrenmeGorevi(
  id: 'test.kesik',
  sayfa: OgrenmeSayfasi.uyeAnaSayfa,
  baslik: 'Alttaki kart ne?',
  kosulMetni: 'Sayfa açılınca',
  adimlar: [
    OgrenmeAdimi(
      hedef: Secici.hedef('test.kart'),
      metin: 'Bu kart sayfanın altında.',
      bilgi: true,
    ),
  ],
);

void main() {
  final modu = OgrenmeModu.ornek;

  tearDown(() {
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  Future<void> tur(WidgetTester tester, [int kez = 8]) async {
    for (var i = 0; i < kez; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('yarım görünen hedef bir kez ortaya kaydırılır', (tester) async {
    final kaydirma = ScrollController();
    addTearDown(kaydirma.dispose);
    late BuildContext sayfa;
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: Scaffold(
        body: Builder(builder: (context) {
          sayfa = context;
          return ListView(
            controller: kaydirma,
            children: const [
              // 800×600 test yüzeyinde kartın yalnız üst 40 pikseli görünür.
              SizedBox(height: 560),
              OgrenmeHedefi(id: 'test.kart', child: SizedBox(height: 120)),
              SizedBox(height: 800),
            ],
          );
        }),
      ),
    ));

    modu.baslat(
      _gorev,
      navigator: Navigator.of(sayfa),
      baslangic: ModalRoute.of(sayfa)!,
    );
    await tur(tester);

    expect(kaydirma.offset, greaterThan(0));
    final kart = tester.getRect(find.byType(OgrenmeHedefi));
    expect(kart.bottom, lessThanOrEqualTo(600));
    expect(modu.delik!.height, greaterThanOrEqualTo(120));

    // Kullanıcı kartı yarıya kadar yukarı kaydırırsa geri çekilmez.
    kaydirma.jumpTo(kaydirma.offset + 300);
    final kaydirilan = kaydirma.offset;
    await tur(tester, 15);
    expect(tester.getRect(find.byType(OgrenmeHedefi)).top, lessThan(0));
    expect(kaydirma.offset, kaydirilan);

    modu.kapat();
    await tur(tester);
  });
}
