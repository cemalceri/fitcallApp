// Renk temaları: tercih, tema altyapısı ve ortak tasarım bileşenleri.
//
// tema_kontrast_test.dart renklerin okunurluğunu ölçer; bu dosya davranışı
// sınar: seçim cihazda saklanıyor ve çıkışta korunuyor mu, sayfa yıkaması her
// rotanın altına geliyor mu, kimlik yüzeyi/kapsül/yıkıcı buton tasarım
// kurallarına uyuyor mu.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/screens/1_common/ayarlar/widgets/renk_temasi_secici.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_stil.dart';
import 'package:fitcall/screens/1_common/takvim/iptal_taramasi.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/core/tema_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gradyan.dart';

Widget _uygulama(Widget govde,
    {TakimTemasi takim = TakimTemasi.sariKirmizi,
    Brightness mod = Brightness.light}) {
  return MaterialApp(
    theme: FitcallTema.temasi(takim, mod),
    home: Scaffold(body: govde),
  );
}

void main() {
  group('TakimTemasi', () {
    test('kodlar benzersiz ve geri çözülür', () {
      final kodlar = TakimTemasi.values.map((t) => t.kod).toSet();
      expect(kodlar.length, TakimTemasi.values.length);
      for (final t in TakimTemasi.values) {
        expect(TakimTemasi.cozumle(t.kod), t);
      }
    });

    test('kayıt yoksa ya da tanınmıyorsa Binay', () {
      expect(TakimTemasi.cozumle(null), TakimTemasi.binay);
      expect(TakimTemasi.cozumle('bilinmeyen'), TakimTemasi.binay);
    });

    test('ana etiket renk adı, kulüp adı yalnız alt etikette', () {
      const kulupler = ['Galatasaray', 'Fenerbahçe', 'Trabzonspor', 'Beşiktaş'];
      for (final t in TakimTemasi.values) {
        expect(t.etiket, isNotEmpty);
        expect(t.altEtiket, isNotEmpty);
        for (final k in kulupler) {
          expect(t.etiket.contains(k), isFalse, reason: t.etiket);
        }
      }
      expect(TakimTemasi.sariKirmizi.altEtiket, 'Galatasaray renkleri');
      expect(TakimTemasi.ayYildiz.altEtiket, 'Türkiye renkleri');
    });
  });

  group('FitcallTema', () {
    test('her tema ve modda iki ThemeExtension da var', () {
      for (final t in TakimTemasi.values) {
        for (final b in Brightness.values) {
          final tema = FitcallTema.temasi(t, b);
          expect(tema.extension<FitcallRenkleri>(), isNotNull);
          expect(tema.extension<TemaGecisleri>(), isNotNull);
          expect(tema.brightness, b);
          // Zemin sayfanın altındaki SayfaZemini'nden gelir.
          expect(tema.scaffoldBackgroundColor.a, 0);
        }
      }
    });

    test('tema önbelleklenir; acik/koyu Binay temasıdır', () {
      expect(
          identical(FitcallTema.temasi(TakimTemasi.bordoMavi, Brightness.dark),
              FitcallTema.temasi(TakimTemasi.bordoMavi, Brightness.dark)),
          isTrue);
      expect(
          identical(FitcallTema.acik,
              FitcallTema.temasi(TakimTemasi.binay, Brightness.light)),
          isTrue);
    });

    test('başlık çubuğu dolu takım renginde, yazı ve ikonlar onBaslik', () {
      for (final t in TakimTemasi.values) {
        for (final mod in Brightness.values) {
          final tema = FitcallTema.temasi(t, mod);
          final g = tema.extension<TemaGecisleri>()!;
          final ab = tema.appBarTheme;
          expect(ab.backgroundColor, g.baslik, reason: '${t.kod} $mod');
          expect(ab.foregroundColor, g.onBaslik);
          expect(ab.iconTheme?.color, g.onBaslik);
          // Eylem ikonları da: verilmezse IconButton teması (ikincil yazı
          // rengi) renkli çubukta koyu kalıyordu.
          expect(ab.actionsIconTheme?.color, g.onBaslik);
          expect(ab.titleTextStyle?.color, g.onBaslik);
        }
      }
    });

    test(
        'durum çubuğu şeffaf, ikonlar başlık rengine göre, gezinme '
        'çubuğuna dokunulmaz', () {
      for (final t in TakimTemasi.values) {
        for (final mod in Brightness.values) {
          final tema = FitcallTema.temasi(t, mod);
          final g = tema.extension<TemaGecisleri>()!;
          final stil = tema.appBarTheme.systemOverlayStyle!;
          // Verilmezse Android 14 ve altı başlığın üstüne gri örtü koyar.
          expect(stil.statusBarColor, Colors.transparent);
          final beyazIkon = uzerineYazi(g.baslik) == Colors.white;
          expect(stil.statusBarIconBrightness,
              beyazIkon ? Brightness.light : Brightness.dark,
              reason: '${t.kod} $mod');
          expect(stil.systemNavigationBarColor, isNull);
          expect(stil.systemNavigationBarIconBrightness, isNull);
        }
      }
    });

    test('TemaGecisleri lerp uçlarda kaynak/hedefi verir', () {
      final a = takimPaleti(TakimTemasi.binay, Brightness.light).gecisler;
      final b = takimPaleti(TakimTemasi.sariKirmizi, Brightness.light).gecisler;
      // Durak sayıları farklı olabilir; görüntü örnek noktalarda aynı olmalı.
      expect(gradyanlarAyni(a.lerp(b, 0).kimlik, a.kimlik), isTrue);
      expect(gradyanlarAyni(a.lerp(b, 1).kimlik, b.kimlik), isTrue);
      expect(a.lerp(b, 1).sayfaRengi, b.sayfaRengi);
      expect(a.lerp(b, 0).baslik, a.baslik);
      expect(a.lerp(b, 1).altBar, b.altBar);
      expect(a.lerp(b, 0.5).onKimlik, isNotNull);
    });
  });

  group('SayfaZemini', () {
    testWidgets('her rotanın altında takım tonuyla çizilir', (tester) async {
      await tester.pumpWidget(_uygulama(const Text('icerik')));
      expect(find.byType(SayfaZemini), findsOneWidget);
      final gecis =
          takimPaleti(TakimTemasi.sariKirmizi, Brightness.light).gecisler;
      final zemin = tester.widget<ColoredBox>(find
          .descendant(
              of: find.byType(SayfaZemini), matching: find.byType(ColoredBox))
          .first);
      expect(zemin.color, gecis.sayfaRengi);
      // Beyaz değil: renk sayfanın her yerinde görünsün diye.
      expect(zemin.color, isNot(Colors.white));
    });

    testWidgets('itilen sayfa da kendi zeminini getirir', (tester) async {
      final anahtar = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: anahtar,
        theme: FitcallTema.temasi(TakimTemasi.siyahBeyaz, Brightness.dark),
        home: const Scaffold(body: Text('bir')),
      ));
      anahtar.currentState!.push(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('iki'))));
      await tester.pumpAndSettle();
      expect(find.text('iki'), findsOneWidget);
      // Önceki rota opak, yeni rota kendi zeminiyle çizilir (üst üste binme yok).
      expect(find.byType(SayfaZemini, skipOffstage: false), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    // iOS/macOS geçişi varsayılan haritadan geliyor (Flutter 3.44'te
    // CupertinoPageTransitionsBuilder kütüphane değiştirdi); sarmalayıcı yine
    // zemini koymalı.
    testWidgets('iOS ve macOS geçişinde de zemin çizilir', (tester) async {
      final anahtar = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: anahtar,
        theme: FitcallTema.temasi(TakimTemasi.bordoMavi, Brightness.light),
        home: const Scaffold(body: Text('bir')),
      ));
      anahtar.currentState!.push(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('iki'))));
      await tester.pumpAndSettle();
      expect(find.text('iki'), findsOneWidget);
      expect(find.byType(SayfaZemini, skipOffstage: false), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
        variant: const TargetPlatformVariant(
            {TargetPlatform.iOS, TargetPlatform.macOS}));
  });

  group('TemaKontrol', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      TemaKontrol.takim.value = TakimTemasi.binay;
      TemaKontrol.modu.value = ThemeMode.system;
    });

    test('kayıt yokken Binay + sistem modu', () async {
      await TemaKontrol.yukle();
      expect(TemaKontrol.takim.value, TakimTemasi.binay);
      expect(TemaKontrol.modu.value, ThemeMode.system);
    });

    test('takım seçimi saklanır ve yeniden açılışta okunur', () async {
      await TemaKontrol.takimAyarla(TakimTemasi.bordoMavi);
      expect(TemaKontrol.takim.value, TakimTemasi.bordoMavi);
      expect(await SecureStorageService.getValue<String>('tema_takim'),
          'bordo_mavi');

      TemaKontrol.takim.value = TakimTemasi.binay;
      await TemaKontrol.yukle();
      expect(TemaKontrol.takim.value, TakimTemasi.bordoMavi);
    });

    test('mod ve takım birbirinden bağımsız', () async {
      await TemaKontrol.takimAyarla(TakimTemasi.sariLacivert);
      await TemaKontrol.ayarla(ThemeMode.dark);
      await TemaKontrol.yukle();
      expect(TemaKontrol.takim.value, TakimTemasi.sariLacivert);
      expect(TemaKontrol.modu.value, ThemeMode.dark);
    });

    test('çıkışta (depo temizlenince) tema tercihi korunur', () async {
      FlutterSecureStorage.setMockInitialValues({
        'token': 'abc',
        'tema_takim': 'ay_yildiz',
        'tema_modu': 'koyu',
      });
      await StorageService.clearAll();
      expect(await SecureStorageService.getValue<String>('token'), isNull);
      expect(await SecureStorageService.getValue<String>('tema_takim'),
          'ay_yildiz');
      expect(await SecureStorageService.getValue<String>('tema_modu'), 'koyu');
    });
  });

  group('KimlikYuzeyi', () {
    testWidgets('renk vermeyen yazı kimlik yazı rengini alır', (tester) async {
      await tester.pumpWidget(_uygulama(
        const KimlikYuzeyi(child: Text('Sonraki ders')),
        takim: TakimTemasi.sariLacivert,
      ));
      final gecis =
          takimPaleti(TakimTemasi.sariLacivert, Brightness.light).gecisler;
      final stil = tester
          .widget<RichText>(find.descendant(
              of: find.byType(KimlikYuzeyi), matching: find.byType(RichText)))
          .text
          .style;
      expect(stil?.color, gecis.onKimlik);
    });

    testWidgets('gradyan ve geçiş şeridi temadan', (tester) async {
      await tester.pumpWidget(_uygulama(
        const KimlikYuzeyi(child: SizedBox(height: 40)),
        takim: TakimTemasi.bordoMavi,
        mod: Brightness.dark,
      ));
      final gecis =
          takimPaleti(TakimTemasi.bordoMavi, Brightness.dark).gecisler;
      final gradyanlar = tester
          .widgetList<Container>(find.descendant(
              of: find.byType(KimlikYuzeyi), matching: find.byType(Container)))
          .map((c) => (c.decoration as BoxDecoration?)?.gradient)
          .toList();
      expect(gradyanlar, contains(gecis.kimlik));
      final seritler = tester
          .widgetList<DecoratedBox>(find.descendant(
              of: find.byType(KimlikYuzeyi),
              matching: find.byType(DecoratedBox)))
          .map((k) => (k.decoration as BoxDecoration?)?.gradient);
      expect(seritler, contains(gecis.serit));
    });

    testWidgets('dokunma geri çağrısı çalışır', (tester) async {
      var sayac = 0;
      await tester.pumpWidget(_uygulama(
        KimlikYuzeyi(onTap: () => sayac++, child: const Text('dokun')),
      ));
      await tester.tap(find.text('dokun'));
      expect(sayac, 1);
    });

    testWidgets('KimlikBaslik baş harfleri ve kapsülleri gösterir',
        (tester) async {
      await tester.pumpWidget(_uygulama(const KimlikBaslik(
        baslik: 'Deniz Yılmaz',
        basHarfler: 'DY',
        altBaslik: 'Üye No: 1042',
        kapsuller: ['Sarı top', 'Aktif'],
      )));
      expect(find.text('DY'), findsOneWidget);
      expect(find.text('Sarı top'), findsOneWidget);
      expect(find.byType(KimlikKapsulu), findsNWidgets(2));
    });
  });

  group('basHarfleri', () {
    test('Türkçe harfler ve tek kelime', () {
      expect(basHarfleri('Deniz Yılmaz'), 'DY');
      expect(basHarfleri('ismail çelik'), 'IÇ');
      expect(basHarfleri('Ece'), 'E');
      expect(basHarfleri('  Ali  Rıza  Kaya '), 'AK');
      expect(basHarfleri(''), '?');
    });
  });

  group('GecisCubugu', () {
    testWidgets('değer 0–1 aralığına sıkıştırılır', (tester) async {
      for (final (deger, beklenen) in [(1.7, 1.0), (-0.4, 0.0), (0.35, 0.35)]) {
        await tester.pumpWidget(
            _uygulama(SizedBox(width: 200, child: GecisCubugu(deger: deger))));
        final kutu = tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
        expect(kutu.widthFactor, beklenen);
      }
    });
  });

  group('YikiciButon', () {
    testWidgets('kenarlıklı ve hata renginde', (tester) async {
      await tester
          .pumpWidget(_uygulama(YikiciButon(etiket: 'Sil', onPressed: () {})));
      final buton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final cs = FitcallTema.temasi(TakimTemasi.sariKirmizi, Brightness.light)
          .colorScheme;
      expect(buton.style!.foregroundColor!.resolve({}), cs.error);
      expect(buton.style!.side!.resolve({})!.color, cs.error);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('pasifken ve yüklenirken basılamaz', (tester) async {
      await tester.pumpWidget(
          _uygulama(const YikiciButon(etiket: 'Sil', onPressed: null)));
      expect(
          tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
          isNull);

      await tester.pumpWidget(_uygulama(
          YikiciButon(etiket: 'Sil', onPressed: () {}, yukleniyor: true)));
      expect(
          tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
          isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sil'), findsNothing);
    });
  });

  group('ButonYukleniyorGostergesi', () {
    testWidgets('dolgulu butonun yazı rengini alır', (tester) async {
      await tester.pumpWidget(_uygulama(
        FilledButton(
          onPressed: () {},
          child: const SizedBox(
              width: 20, height: 20, child: ButonYukleniyorGostergesi()),
        ),
        takim: TakimTemasi.sariLacivert,
        mod: Brightness.dark,
      ));
      final cs = FitcallTema.temasi(TakimTemasi.sariLacivert, Brightness.dark)
          .colorScheme;
      final gosterge = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      // Koyu Sarı-Lacivert'te buton sarı: gösterge beyaz değil lacivert.
      expect(gosterge.color, cs.onPrimary);
      expect(gosterge.color, isNot(Colors.white));
    });
  });

  group('RenkTemasiSecici', () {
    testWidgets('altı tema listelenir, dokununca seçilir', (tester) async {
      TakimTemasi? secilen;
      await tester.pumpWidget(_uygulama(
        SingleChildScrollView(
          child: RenkTemasiSecici(
            secili: TakimTemasi.binay,
            onSec: (t) => secilen = t,
          ),
        ),
      ));
      for (final t in TakimTemasi.values) {
        expect(find.text(t.etiket), findsOneWidget);
        expect(find.text(t.altEtiket), findsOneWidget);
      }
      // Seçili karoda onay işareti tek tane.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Bordo-Mavi'));
      expect(secilen, TakimTemasi.bordoMavi);
    });

    // Üç sütunda karo ~110 dp kalıyor ve "Trabzonspor renkleri" kesiliyordu.
    Future<double> ikinciSatirX(WidgetTester tester, double genislik) async {
      await tester.pumpWidget(_uygulama(
        Center(
          child: SizedBox(
            width: genislik,
            child: RenkTemasiSecici(secili: TakimTemasi.binay, onSec: (_) {}),
          ),
        ),
      ));
      // Wrap soldan sağa dizer: 2 sütunda 3. karo (Sarı-Lacivert), 3 sütunda
      // 4. karo (Bordo-Mavi) ikinci satırın başına, ilk karonun hizasına düşer.
      final ilk = tester.getTopLeft(find.text('Binay Akademi')).dx;
      return (tester.getTopLeft(find.text('Sarı-Lacivert')).dx - ilk).abs();
    }

    testWidgets('telefon genişliğinde iki sütun', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      expect(await ikinciSatirX(tester, 348), lessThan(0.5));
    });

    testWidgets('geniş alanda üç sütun', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      expect(await ikinciSatirX(tester, 600), greaterThan(100));
    });
  });

  group('IptalTaramasi', () {
    testWidgets('pasifken yalnız çocuğu döner', (tester) async {
      await tester.pumpWidget(
          _uygulama(const IptalTaramasi(aktif: false, child: Text('ders'))));
      expect(
          find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is IptalTaramaBoyaci),
          findsNothing);
    });

    testWidgets('aktifken hata renginde tarama çizer', (tester) async {
      await tester.pumpWidget(_uygulama(
          const IptalTaramasi(child: SizedBox(width: 80, height: 40))));
      final boya = tester
          .widget<CustomPaint>(find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is IptalTaramaBoyaci))
          .painter as IptalTaramaBoyaci;
      final hata = FitcallTema.temasi(TakimTemasi.sariKirmizi, Brightness.light)
          .extension<FitcallRenkleri>()!
          .hata;
      expect(boya.renk.r, closeTo(hata.r, 0.001));
      expect(boya.renk.a, lessThan(0.3));
    });
  });

  group('KabukAltBar QR butonu', () {
    testWidgets('QR gradyanı ve ikon rengi temadan', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: FitcallTema.temasi(TakimTemasi.sariLacivert, Brightness.dark),
        home: Scaffold(
          bottomNavigationBar: KabukAltBar(
            aktifIndeks: 0,
            onSekme: (_) {},
            onMerkez: () {},
            sekmeler: const [
              KabukSekmesi(
                  ikon: Icons.home_outlined,
                  seciliIkon: Icons.home_rounded,
                  etiket: 'Ana Sayfa'),
              KabukSekmesi(
                  ikon: Icons.calendar_month_outlined,
                  seciliIkon: Icons.calendar_month_rounded,
                  etiket: 'Takvim'),
              KabukSekmesi(
                  ikon: Icons.wallet_outlined,
                  seciliIkon: Icons.wallet_rounded,
                  etiket: 'Hareketler'),
              KabukSekmesi(
                  ikon: Icons.person_outline,
                  seciliIkon: Icons.person,
                  etiket: 'Hesabım'),
            ],
          ),
        ),
      ));
      final gecis =
          takimPaleti(TakimTemasi.sariLacivert, Brightness.dark).gecisler;
      final ikon = tester.widget<Icon>(find.byIcon(Icons.qr_code_rounded));
      expect(ikon.color, gecis.onQr);
      final inkler = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((i) => (i.decoration as BoxDecoration?)?.gradient);
      expect(inkler, contains(gecis.qr));
      // Halka ile gradyan arasında zemin rengi boşluk: gradyan içeri itilmiş
      // (kenarlık çocuğu itmediği için eskiden boşluğun üstüne boyanıyordu).
      expect(tester.getSize(find.byType(Ink)), const Size(38, 38));
    });

    testWidgets('etikete dokununca da QR açılır', (tester) async {
      var acildi = 0;
      await tester.pumpWidget(MaterialApp(
        theme: FitcallTema.acik,
        home: Scaffold(
          bottomNavigationBar: KabukAltBar(
            aktifIndeks: 0,
            onSekme: (_) {},
            onMerkez: () => acildi++,
            sekmeler: const [
              KabukSekmesi(
                  ikon: Icons.home_outlined,
                  seciliIkon: Icons.home_rounded,
                  etiket: 'Ana Sayfa'),
              KabukSekmesi(
                  ikon: Icons.calendar_month_outlined,
                  seciliIkon: Icons.calendar_month_rounded,
                  etiket: 'Takvim'),
              KabukSekmesi(
                  ikon: Icons.wallet_outlined,
                  seciliIkon: Icons.wallet_rounded,
                  etiket: 'Hareketler'),
              KabukSekmesi(
                  ikon: Icons.person_outline,
                  seciliIkon: Icons.person,
                  etiket: 'Hesabım'),
            ],
          ),
        ),
      ));
      await tester.tap(find.text('QR Giriş'));
      await tester.tap(find.byIcon(Icons.qr_code_rounded));
      expect(acildi, 2);
    });
  });

  group('Hakediş renk seti', () {
    testWidgets('koyu modda gri taban gri kalır (pembeye dönmez)',
        (tester) async {
      late HakedisRenk renk;
      await tester.pumpWidget(_uygulama(
        Builder(builder: (context) {
          renk = hakedisRenkSeti(context, const Color(0xFF8C8C8C));
          return const SizedBox();
        }),
        mod: Brightness.dark,
      ));
      expect(HSLColor.fromColor(renk.metin).saturation, closeTo(0, 0.01));
    });

    testWidgets('doygun tabanın metni koyu modda en çok 0.55 doygunlukta',
        (tester) async {
      late HakedisRenk renk;
      await tester.pumpWidget(_uygulama(
        Builder(builder: (context) {
          renk = hakedisRenkSeti(context, const Color(0xFF10B981));
          return const SizedBox();
        }),
        mod: Brightness.dark,
      ));
      expect(HSLColor.fromColor(renk.metin).saturation, closeTo(0.55, 0.01));
    });
  });

  group('HomeCardModel tonu', () {
    HomeCardModel kart(HomeCardType t) =>
        HomeCardModel(id: 1, type: t, title: '', subtitle: '');

    test('durum bildiren türler durum tonu, diğerleri ana renk', () {
      expect(kart(HomeCardType.borc).ton, ListeTonu.hata);
      expect(kart(HomeCardType.cancelled).ton, ListeTonu.hata);
      expect(kart(HomeCardType.teyitBekleyen).ton, ListeTonu.uyari);
      expect(kart(HomeCardType.paketBitiyor).ton, ListeTonu.uyari);
      expect(kart(HomeCardType.success).ton, ListeTonu.basari);
      expect(kart(HomeCardType.info).ton, ListeTonu.notr);
      expect(kart(HomeCardType.earnings).ton, ListeTonu.vurgu);
      expect(kart(HomeCardType.upcomingLessons).ton, ListeTonu.vurgu);
    });
  });
}
