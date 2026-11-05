// Rehber sahnesinin ekrandaki davranışı: alt sayfadaki tam genişlik, ekranın
// altına uzanan liste (yöneticide borç dökümü) görünen alana kırpılır, halka
// ekranda kalır, balon ve bitiş kartı ona bağlı durur; rehber kapanınca açık
// sol menü (çekmece) de kapanır.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_balonu.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _liste = 'test.uzunListe';

/// 390×844 ekranda durum çubuğu 47, alt çubuk 34.
const _guvenli = Rect.fromLTRB(0, 47, 390, 810);

OgrenmeGorevi _gorev(Secici hedef) => OgrenmeGorevi(
      id: 'test.sahne',
      sayfa: OgrenmeSayfasi.yoneticiUyeDetay,
      baslik: 'Test?',
      kosulMetni: 'Test',
      adimlar: [
        OgrenmeAdimi(
          hedef: hedef,
          metin: 'Her ayın borcu, ödemesi ve bakiyesi yazar.',
          bilgi: true,
        ),
      ],
      kural: 'Bakiye eksideyse üye borçludur.',
    );

class _Sayfa extends StatelessWidget {
  const _Sayfa();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayşe Demir')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(title: const Text('Ayarlar'), onTap: () {}),
          ],
        ),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const _AltSayfa(),
          ),
          child: const Text('Borç Dökümü'),
        ),
      ),
    );
  }
}

/// UyeBorcSheet gibi: 0.75 yükseklik, başlık ve tam genişlik liste.
class _AltSayfa extends StatelessWidget {
  const _AltSayfa();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (context, kontrol) => Column(
        children: [
          const SizedBox(height: 134, child: Center(child: Text('Başlık'))),
          Expanded(
            child: OgrenmeHedefi(
              id: _liste,
              child: ListView.builder(
                controller: kontrol,
                itemCount: 30,
                itemBuilder: (_, i) =>
                    SizedBox(height: 66, child: Text('Ay $i')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _bekle(WidgetTester tester, int tur) async {
  for (var i = 0; i < tur; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final modu = OgrenmeModu.ornek;

  tearDown(() {
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  Future<void> kur(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: const _Sayfa(),
    ));
    await tester.pump();
  }

  void baslat(WidgetTester tester, Secici hedef) {
    modu.baslat(
      _gorev(hedef),
      navigator: tester.state<NavigatorState>(find.byType(Navigator).first),
      baslangic: ModalRoute.of(tester.element(find.byType(_Sayfa)))!,
    );
  }

  testWidgets(
      'alt sayfadaki uzun liste: delik ve halka ekranda, balon ve bitiş '
      'kartı ona bağlı', (tester) async {
    await kur(tester);
    await tester.tap(find.text('Borç Dökümü'));
    await _bekle(tester, 8);
    baslat(tester, const Secici.hedef(_liste));
    await _bekle(tester, 6);

    expect(modu.durum, RehberDurumu.adim);
    // Görünen alan ekranın altında biter; liste kutusu ekran dışına taşıyor
    // ve halkanın yalnız üst kenarı görünüyordu.
    final gorunen = modu.delik!;
    expect(gorunen.width, 390, reason: 'hedef tam genişlik liste');
    expect(gorunen.bottom, lessThanOrEqualTo(844));
    final delik = delikHesapla(gorunen, _guvenli)!;
    const icPay = BalonOlcu.halkaAraligi + BalonOlcu.halkaKalinligi;
    expect(delik.left - icPay, greaterThanOrEqualTo(_guvenli.left));
    expect(delik.right + icPay, lessThanOrEqualTo(_guvenli.right));
    expect(delik.bottom + icPay, lessThanOrEqualTo(_guvenli.bottom));

    // Altta yer yok: balon üstte, okla deliğe bağlı.
    final balon = tester.getRect(find.byType(RehberAdimPaneli));
    expect(delik.top - balon.bottom, closeTo(BalonOlcu.dis, 0.5));
    expect(find.text('1/1'), findsNothing);

    await tester.tap(find.text('Anladım'));
    await _bekle(tester, 6);
    expect(modu.durum, RehberDurumu.bitis);
    final kart = tester.getRect(find.byType(RehberBitisKarti));
    expect(delik.top - kart.bottom, closeTo(BalonOlcu.dis, 0.5));

    await tester.tap(find.text('Üye detayına dön'));
    await _bekle(tester, 8);
    expect(modu.acik, isFalse);
    expect(find.text('Başlık'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rehber kapanınca açık sol menü de kapanır', (tester) async {
    await kur(tester);
    final iskelet = tester.state<ScaffoldState>(find.byType(Scaffold));
    iskelet.openDrawer();
    await _bekle(tester, 5);
    expect(iskelet.isDrawerOpen, isTrue);
    baslat(tester, const Secici.metin('Ayarlar'));
    await _bekle(tester, 4);
    expect(modu.delik, isNotNull);

    await tester.tap(find.text('Kapat'));
    await _bekle(tester, 6);
    expect(modu.acik, isFalse);
    expect(iskelet.isDrawerOpen, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
