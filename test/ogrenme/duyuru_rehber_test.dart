// "?" rehberinin sürücü testi: yönetici/ofis Duyurular sayfasının
// "Bir duyuruyu kimler görmüş, nasıl anlarım?" ve "Ana sayfadan açan ile
// popup'ta gören farkı ne?" rehberleri. Sayfaların API çağıran kabukları
// yerine veriyle beslenen gerçek görünümleri (DuyuruYonetimListesi,
// OkumaDurumuGorunumu) aynı geçişle (listeden satıra dokununca okuma durumu
// sayfası açılır) pompalanır; rehber duyurunun farklı durumlarında yürünür.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_yonetim_listesi.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/okuma_durumu_gorunumu.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/duyuru_ornekleri.dart';

OgrenmeGorevi _rehber(String id) =>
    ogrenmeGorevleri.firstWhere((g) => g.id == id);

DuyuruYonetimSatiri _satir(String durum) => DuyuruYonetimSatiri.fromJson({
      'id': 7,
      'baslik': 'Kort bakımı',
      'hedef_kitle': 'herkes',
      'durum': durum,
      'yayin_baslangic': '2026-10-03T09:00:00+03:00',
      'yayin_bitis': '2026-10-17T23:59:00+03:00',
      'goren_sayisi': durum == 'planli' ? 0 : 54,
      'hedef_sayisi': 142,
    });

/// Örnek okuma durumu; [gordu] / [gormedi] false ise o liste boş.
DuyuruOkumaDurumu _okuma({
  String durum = 'yayinda',
  bool gordu = true,
  bool gormedi = true,
}) {
  final j = okumaDurumuJson(durum: durum);
  if (!gordu) j['gordu'] = <Object>[];
  if (!gormedi) j['gormedi'] = <Object>[];
  return DuyuruOkumaDurumu.fromJson(j);
}

class _Sayfa extends StatelessWidget {
  final DuyuruYonetimSatiri satir;
  final DuyuruOkumaDurumu okuma;

  const _Sayfa({required this.satir, required this.okuma});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Duyurular')),
        body: DuyuruYonetimListesi(
          duyurular: [satir],
          onYenile: () async {},
          onSec: (_) => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Okuma durumu')),
              body: OkumaDurumuGorunumu(
                veri: okuma,
                onIcerikGor: () {},
                onYenile: () async {},
              ),
            ),
          )),
        ),
      );
}

void main() {
  final modu = OgrenmeModu.ornek;
  late List<int> adimGecmisi;

  void kaydet() {
    if (modu.durum == RehberDurumu.adim) adimGecmisi.add(modu.adimNo);
  }

  setUpAll(() => initializeDateFormatting('tr', null));

  setUp(() {
    adimGecmisi = [];
    modu.addListener(kaydet);
  });

  tearDown(() {
    modu.removeListener(kaydet);
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  /// Sayfayı kurar; rehber "?" listesinde ekranda başlatılabiliyorsa
  /// başlatır ve true döner (değilse uygulama okuma görünümünü açardı).
  Future<bool> kur(
    WidgetTester tester,
    OgrenmeGorevi gorev, {
    required DuyuruYonetimSatiri satir,
    required DuyuruOkumaDurumu okuma,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: _Sayfa(satir: satir, okuma: okuma),
    ));
    await tester.pump();
    if (!modu.bulucu!.baslatilabilir(gorev)) return false;
    modu.baslat(
      gorev,
      navigator: navigator.currentState!,
      baslangic: ModalRoute.of(tester.element(find.byType(_Sayfa)))!,
    );
    await bekle(tester, 5);
    return true;
  }

  Future<void> adimda(WidgetTester tester, int beklenen, {int tur = 40}) async {
    for (var i = 0; i < tur && modu.adimNo != beklenen; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(modu.durum, RehberDurumu.adim);
    expect(modu.adimNo, beklenen,
        reason: 'Adım ${modu.adimNo + 1}/${modu.gorev?.adimlar.length}; '
            'hedefYok=${modu.hedefYok}, sonrakiYok=${modu.sonrakiYok}, '
            'geçmiş=$adimGecmisi');
  }

  Future<void> deligeDokun(WidgetTester tester) async {
    expect(modu.delik, isNotNull,
        reason: 'Parlayan yer yok (adım ${modu.adimNo + 1})');
    await tester.tapAt(modu.delik!.center);
    await bekle(tester, 8);
  }

  Future<void> anladim(WidgetTester tester) async {
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 6);
  }

  Future<void> bitti(WidgetTester tester) async {
    expect(modu.durum, RehberDurumu.bitis);
    for (var i = 1; i < adimGecmisi.length; i++) {
      expect(adimGecmisi[i], greaterThanOrEqualTo(adimGecmisi[i - 1]),
          reason: 'Adım geri gitti: $adimGecmisi');
    }
    modu.kapat();
    await bekle(tester, 3);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  /// "Kimler görmüş" rehberini baştan sona yürür.
  Future<void> gorenleriYuru(WidgetTester tester) async {
    await adimda(tester, 0);
    await deligeDokun(tester); // satır → okuma durumu
    await adimda(tester, 1);
    await anladim(tester); // özet
    await adimda(tester, 2);
    await anladim(tester); // «Gördü»
    await adimda(tester, 3);
    await anladim(tester); // satır
    await adimda(tester, 4);
    await deligeDokun(tester); // «Görmedi»
    await bekle(tester, 20);
    await adimda(tester, 5);
    await anladim(tester); // görmeyen satırı
    await adimda(tester, 6);
    await anladim(tester); // arama, son adım
  }

  group('duyuru.gorenler', () {
    testWidgets('gören de görmeyen de varken sonuna kadar yürür',
        (tester) async {
      expect(
          await kur(tester, _rehber('duyuru.gorenler'),
              satir: _satir('yayinda'), okuma: _okuma()),
          isTrue);
      await gorenleriYuru(tester);
      await bitti(tester);
    });

    group('düzeltilen hata', () {
      testWidgets('kimse görmemişken (yeni duyuru) sonuna kadar yürür',
          (tester) async {
        expect(
            await kur(tester, _rehber('duyuru.gorenler'),
                satir: _satir('yayinda'), okuma: _okuma(gordu: false)),
            isTrue);
        await gorenleriYuru(tester);
        await bitti(tester);
      });

      testWidgets('herkes görmüşken «Görmedi»den sonra geri sekmez',
          (tester) async {
        expect(
            await kur(tester, _rehber('duyuru.gorenler'),
                satir: _satir('yayinda'), okuma: _okuma(gormedi: false)),
            isTrue);
        await gorenleriYuru(tester);
        await bitti(tester);
      });
    });
  });

  group('düzeltilen hata', () {
    for (final id in ['duyuru.gorenler', 'duyuru.kaynak']) {
      testWidgets('$id: yalnız planlanan duyuru varken ya başlamaz ya biter',
          (tester) async {
        final gorev = _rehber(id);
        final basladi = await kur(tester, gorev,
            satir: _satir('planli'), okuma: _okuma(durum: 'planli'));
        if (!basladi) return;
        await adimda(tester, 0);
        await deligeDokun(tester);
        await adimda(tester, 1);
        await anladim(tester);
        await adimda(tester, 2, tur: 30); // «Gördü» sekmesi / kaynaklar satırı
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}

/// Rehberin sürekli animasyonu yüzünden pumpAndSettle bitmez; adım adım ilerlet.
Future<void> bekle(WidgetTester tester, int tur) async {
  for (var i = 0; i < tur; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
