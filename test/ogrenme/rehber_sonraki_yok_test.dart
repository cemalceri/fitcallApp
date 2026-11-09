// «Anladım»a basılınca sonraki adımın hedefi açık sayfada yoksa adım geçmez.
//
// Telefonda: antrenör takviminde "Yoklamayı yanlış girdiysem nasıl
// düzeltirim?" 1/4'te (gün şeridi: okuma + dokunulur + atlanabilir)
// «Anladım»a basınca 2/4'e geçip hedef (yoklaması girilmiş ders) seçili günde
// olmadığı için yarım saniye sonra 1/4'e geri iniyordu. Artık adım yerinde
// kalır, balonda adımın `yoksa` yazısı çıkar; kullanıcı uygun güne geçince
// rehber kendiliğinden 2/4'e ilerler.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _gunYoksa = 'Bu günde uygun ders yok; başka gün seç.';

/// Antrenör takvimindeki gibi: gün şeridi okunur ve dokunulur, seçili günde
/// ders varsa atlanır.
const _gunluRehber = OgrenmeGorevi(
  id: 'test.gunlu',
  sayfa: OgrenmeSayfasi.antrenorTakvim,
  baslik: 'Dersi nasıl düzeltirim?',
  kosulMetni: 'Ders olunca',
  adimlar: [
    OgrenmeAdimi(
      hedef: Secici.hedef('test.gunler'),
      metin: 'Dersin gününü seç.',
      bilgi: true,
      dokunulur: true,
      atlanabilir: true,
      yoksa: _gunYoksa,
    ),
    OgrenmeAdimi(hedef: Secici.hedef('test.ders'), metin: 'Derse dokun.'),
    OgrenmeAdimi(
      hedef: Secici.hedef('test.gonder'),
      metin: '«Gönder»e dokun.',
      kalici: true,
      sonuc: 'gönderilir',
    ),
  ],
);

/// Okuma adımı atlanmaz; `yoksa` yazılmamış (varsayılan yazı çıkar).
const _okumaRehberi = OgrenmeGorevi(
  id: 'test.okuma',
  sayfa: OgrenmeSayfasi.antrenorTakvim,
  baslik: 'Gün nasıl seçilir?',
  kosulMetni: 'Ders olunca',
  adimlar: [
    OgrenmeAdimi(
      hedef: Secici.hedef('test.gunler'),
      metin: 'Bir gün seç.',
      bilgi: true,
      dokunulur: true,
    ),
    OgrenmeAdimi(hedef: Secici.hedef('test.ders'), metin: 'Derse dokun.'),
    OgrenmeAdimi(
      hedef: Secici.hedef('test.gonder'),
      metin: '«Gönder»e dokun.',
      kalici: true,
      sonuc: 'gönderilir',
    ),
  ],
);

/// Gün şeridi ve seçili günün dersi; derse dokununca detay sayfası açılır.
class _SahteTakvim extends StatefulWidget {
  final Set<int> dersliGunler;
  final int ilkGun;

  const _SahteTakvim({required this.dersliGunler, required this.ilkGun});

  @override
  State<_SahteTakvim> createState() => _SahteTakvimState();
}

class _SahteTakvimState extends State<_SahteTakvim> {
  late int _gun = widget.ilkGun;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: Column(
        children: [
          OgrenmeHedefi(
            id: 'test.gunler',
            child: Row(
              children: [
                for (var g = 1; g <= 3; g++)
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _gun = g),
                      child: Text('Gün $g'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 120),
          if (widget.dersliGunler.contains(_gun))
            OgrenmeHedefi(
              id: 'test.ders',
              child: ListTile(
                title: Text('Ders $_gun'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Detay')),
                    body: Center(
                      child: OgrenmeHedefi(
                        id: 'test.gonder',
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('Gönder'),
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  final modu = OgrenmeModu.ornek;
  late List<int> adimlar;

  void kaydet() {
    if (modu.durum == RehberDurumu.adim) adimlar.add(modu.adimNo);
  }

  setUp(() {
    adimlar = [];
    modu.addListener(kaydet);
  });

  tearDown(() {
    modu.removeListener(kaydet);
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  Future<void> kur(
    WidgetTester tester,
    OgrenmeGorevi gorev, {
    required Set<int> dersliGunler,
    int ilkGun = 1,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: _SahteTakvim(dersliGunler: dersliGunler, ilkGun: ilkGun),
    ));
    await tester.pump();
    modu.baslat(
      gorev,
      navigator: navigator.currentState!,
      baslangic: ModalRoute.of(tester.element(find.byType(_SahteTakvim)))!,
    );
    await bekle(tester, 3);
  }

  Future<void> bitir(WidgetTester tester) async {
    modu.kapat();
    await bekle(tester, 3);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  /// Adım numarası hiç geri gitmedi.
  void geriGitmedi() {
    for (var i = 1; i < adimlar.length; i++) {
      expect(adimlar[i], greaterThanOrEqualTo(adimlar[i - 1]),
          reason: 'Adım geri gitti: $adimlar');
    }
  }

  testWidgets(
      'sonraki hedef yokken «Anladım» adımı geçirmez, yoksa yazısı çıkar, '
      'saniyeler sonra da geri inmez', (tester) async {
    await kur(tester, _gunluRehber, dersliGunler: {2});
    expect(modu.durum, RehberDurumu.adim);
    expect(modu.adimNo, 0);
    expect(modu.sonrakiYok, isFalse);
    expect(find.text(_gunYoksa), findsNothing);
    final sallanma = modu.yanlisSayaci;

    await tester.tap(find.text('Anladım'));
    await bekle(tester, 2);
    expect(modu.adimNo, 0);
    expect(modu.sonrakiYok, isTrue);
    expect(modu.yanlisSayaci, sallanma + 1, reason: 'balon sallanmalı');
    expect(find.text(_gunYoksa), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    // Eski hatada 4 tur (400 ms) sonra 2/3 → 1/3 iniş görülürdü.
    await bekle(tester, 50);
    expect(modu.adimNo, 0);
    expect(modu.sonrakiYok, isTrue);
    expect(modu.hedefYok, isFalse);
    expect(adimlar.toSet(), {0}, reason: 'Adım hiç değişmemeli: $adimlar');

    // Dersi olmayan başka güne geçmek de bir şey değiştirmez.
    await tester.tap(find.text('Gün 3'));
    await bekle(tester, 10);
    expect(modu.adimNo, 0);
    expect(find.text(_gunYoksa), findsOneWidget);

    // Dersli güne geçince atlanabilir adım kendiliğinden geçer.
    await tester.tap(find.text('Gün 2'));
    await bekle(tester, 5);
    expect(modu.adimNo, 1);
    expect(modu.sonrakiYok, isFalse);
    expect(find.text(_gunYoksa), findsNothing);
    expect(find.text('2/3'), findsOneWidget);

    // Rehber sonuna kadar yürür.
    await tester.tapAt(modu.delik!.center);
    await bekle(tester, 8);
    expect(modu.adimNo, 2);
    await tester.tapAt(modu.delik!.center);
    await bekle(tester, 3);
    expect(modu.durum, RehberDurumu.bitis);
    geriGitmedi();
    await bitir(tester);
  });

  testWidgets('seçili günde ders varken gün adımı hiç görünmez',
      (tester) async {
    await kur(tester, _gunluRehber, dersliGunler: {1});
    expect(modu.adimNo, 1);
    expect(find.text('2/3'), findsOneWidget);
    await bitir(tester);
  });

  testWidgets('sonraki hedef varken «Anladım» adımı olağan geçirir',
      (tester) async {
    await kur(tester, _okumaRehberi, dersliGunler: {1});
    expect(modu.adimNo, 0, reason: 'atlanabilir olmayan okuma adımı beklemeli');
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 3);
    expect(modu.adimNo, 1);
    expect(modu.sonrakiYok, isFalse);
    await bekle(tester, 30);
    expect(modu.adimNo, 1);
    geriGitmedi();
    await bitir(tester);
  });

  testWidgets(
      '`yoksa` yazılmamış adımda varsayılan yazı çıkar; hedef belirince '
      '«Anladım» geçirir', (tester) async {
    await kur(tester, _okumaRehberi, dersliGunler: {2});
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 2);
    expect(modu.adimNo, 0);
    expect(modu.sonrakiYok, isTrue);
    expect(find.text(OgrenmeAdimi.varsayilanYoksa), findsOneWidget);
    await bekle(tester, 30);
    expect(modu.adimNo, 0);

    // Atlanabilir olmayan okuma adımı kendiliğinden geçmez; seçim yapılınca
    // «Anladım» geçirir, uyarı kalkar.
    await tester.tap(find.text('Gün 2'));
    await bekle(tester, 5);
    expect(modu.adimNo, 0);
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 3);
    expect(modu.adimNo, 1);
    expect(modu.sonrakiYok, isFalse);
    expect(find.text(OgrenmeAdimi.varsayilanYoksa), findsNothing);
    geriGitmedi();
    await bitir(tester);
  });
}

/// Rehberin sürekli animasyonu yüzünden pumpAndSettle bitmez; adım adım ilerlet.
Future<void> bekle(WidgetTester tester, int tur) async {
  for (var i = 0; i < tur; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
