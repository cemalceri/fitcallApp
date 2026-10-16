// Sürüm notu ("Neler yeni?") popup'ı ve arşiv sayfası.
//
// Kurallar (kullanıcı kararı, 2026-10-15):
//   - Kurulu sürümün notu gösterilir; sürüm penceresi/birikim yok (sunucu
//     tarafı: tests/api/test_surum_yenilikleri.py).
//   - Her profil yalnız kendi bloğunu alır; istemci ayrıca süzmez.
//   - Popup'ta en çok [surumNotuPopupMaddeSiniri] madde; fazlası sayfada.
//   - İlk madde açık gelir ve ölçüme girer (kapatan da "gördü" sayılır).
//
// Taşma matrisi: tasma_ekranlar_test.dart · kontrast: tema_kontrast_test.dart.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/surum_notu_popup.dart';
import 'package:fitcall/screens/1_common/neler_yeni_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test verisi: maddeler "1. yenilik" / "1. yenilik açıklaması" / "Ana Sayfa > 1"
/// biçiminde numaralı — hangi maddenin çizildiği tek `find.text` ile görünür.
SurumNotuBlogu _blok({required int maddeSayisi, String surum = '3.12.0'}) =>
    SurumNotuBlogu.fromJson({
      'id': 7,
      'surum': surum,
      'rol': 'uye',
      'baslik': 'Neler yeni?',
      'maddeler': [
        for (var i = 1; i <= maddeSayisi; i++)
          {
            'id': i,
            'baslik': '$i. yenilik',
            'aciklama': '$i. yenilik açıklaması',
            'yol': 'Ana Sayfa > $i',
            'ikon': 'photo_camera_rounded',
            'sira': i,
          }
      ],
    });

/// Accordion gövdesinin çizilen yüksekliği. Kapalı kartın metni ağaçta KALIR
/// (`SizeTransition` yalnız yüksekliği 0'a indirir), bu yüzden "kapalı" testi
/// `findsNothing` ile değil yükseklikle yapılır.
double _govdeYuksekligi(WidgetTester tester, String aciklama) {
  final gecis = find.ancestor(
    of: find.text(aciklama),
    matching: find.byType(SizeTransition),
  );
  expect(gecis, findsOneWidget, reason: '"$aciklama" agacta yok');
  return tester.getSize(gecis).height;
}

Future<void> _ac(WidgetTester tester, Widget ekran) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: FitcallTema.acik,
    home: Scaffold(body: ekran),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('SurumNotuBlogu', () {
    test('maddeler sıraya dizilir, başlık boşsa varsayılan', () {
      final blok = SurumNotuBlogu.fromJson(const {
        'id': 7,
        'surum': '3.12.0',
        'baslik': '',
        'maddeler': [
          {'id': 2, 'baslik': 'İkinci', 'aciklama': 'b', 'sira': 2},
          {'id': 1, 'baslik': 'Birinci', 'aciklama': 'a', 'sira': 1},
        ],
      });
      expect(blok.baslik, 'Neler yeni?');
      expect([for (final m in blok.maddeler) m.id], [1, 2]);
      expect(blok.bos, isFalse);
    });

    test('alt başlık boşsa özet madde sayısını yazar', () {
      expect(_blok(maddeSayisi: 3).ozet, 'Sizin için 3 yenilik');
      expect(
        SurumNotuBlogu.fromJson(const {
          'id': 1,
          'surum': '3.12.0',
          'alt_baslik': 'Ofis ekranları yenilendi',
          'maddeler': [
            {'id': 1, 'baslik': 'a', 'aciklama': 'b'}
          ],
        }).ozet,
        'Ofis ekranları yenilendi',
      );
    });

    test('maddesiz blok boş sayılır (popup çıkmaz)', () {
      final blok = SurumNotuBlogu.fromJson(
          const {'id': 1, 'surum': '3.12.0', 'maddeler': []});
      expect(blok.bos, isTrue);
      expect(blok.ozet, '');
    });

    test('eksik/bozuk alanlar çökertmez', () {
      final blok = SurumNotuBlogu.fromJson(const {'id': 1});
      expect(blok.surum, '');
      expect(blok.baslik, 'Neler yeni?');
      expect(blok.bos, isTrue);
    });

    test('ikon adı beyaz listeden çözülür, bilinmeyen varsayılana düşer', () {
      expect(surumNotuIkonu('photo_camera_rounded'),
          surumNotuIkonlari['photo_camera_rounded']);
      // Tanınmayan ad: tree-shake edilmiş boş kare yerine nötr ikon.
      expect(surumNotuIkonu('olmayan_ikon'), surumNotuVarsayilanIkon);
      expect(surumNotuIkonu(''), surumNotuVarsayilanIkon);
    });

    test('yol boşsa çip çizilmez (yolVar false)', () {
      final blok = SurumNotuBlogu.fromJson(const {
        'id': 1,
        'surum': '3.12.0',
        'maddeler': [
          {'id': 1, 'baslik': 'Hata düzeltmeleri', 'aciklama': 'x', 'yol': ''}
        ],
      });
      expect(blok.maddeler.first.yolVar, isFalse);
    });
  });

  group('SurumNotuGovdesi', () {
    testWidgets('sürüm rozeti, başlık ve ilk madde açık gelir', (tester) async {
      final acilanlar = <int>[];
      await _ac(
        tester,
        SurumNotuGovdesi(
          blok: _blok(maddeSayisi: 3),
          onKapat: () {},
          onMaddeAcildi: acilanlar.add,
        ),
      );

      expect(find.text('3.12.0'), findsOneWidget);
      expect(find.text('Neler yeni?'), findsOneWidget);
      expect(find.text('Sizin için 3 yenilik'), findsOneWidget);
      expect(find.text('Anladım'), findsOneWidget);

      // İlk maddenin açıklaması ve yolu çizilir, diğerleri kapalı durur.
      expect(_govdeYuksekligi(tester, '1. yenilik açıklaması'), greaterThan(0));
      expect(find.text('Ana Sayfa > 1'), findsOneWidget);
      expect(_govdeYuksekligi(tester, '2. yenilik açıklaması'), 0);

      // Açık başlayan madde de ölçüme girer.
      expect(acilanlar, [1]);
    });

    testWidgets('maddeye dokununca açılır ve ölçüme yazılır', (tester) async {
      final acilanlar = <int>[];
      await _ac(
        tester,
        SurumNotuGovdesi(
          blok: _blok(maddeSayisi: 3),
          onKapat: () {},
          onMaddeAcildi: acilanlar.add,
        ),
      );

      expect(_govdeYuksekligi(tester, '2. yenilik açıklaması'), 0);
      await tester.tap(find.text('2. yenilik'));
      await tester.pumpAndSettle();
      expect(_govdeYuksekligi(tester, '2. yenilik açıklaması'), greaterThan(0));
      expect(acilanlar, [1, 2]);
    });

    testWidgets('Anladım kapatır', (tester) async {
      var kapat = 0;
      await _ac(
        tester,
        SurumNotuGovdesi(
          blok: _blok(maddeSayisi: 1),
          onKapat: () => kapat++,
        ),
      );
      await tester.tap(find.text('Anladım'));
      expect(kapat, 1);
    });

    testWidgets('sınır üstü maddeler popupta değil, Tümünü gör ile sayfada',
        (tester) async {
      var tumunuGor = 0;
      await _ac(
        tester,
        SurumNotuGovdesi(
          blok: _blok(maddeSayisi: 7),
          onKapat: () {},
          onTumunuGor: () => tumunuGor++,
        ),
      );

      expect(surumNotuPopupMaddeSiniri, 4);
      expect(find.text('4. yenilik'), findsOneWidget);
      expect(find.text('5. yenilik'), findsNothing);

      await tester.tap(find.text('Tümünü gör (7)'));
      expect(tumunuGor, 1);
    });

    testWidgets('sınır aşılmazsa Tümünü gör çıkmaz', (tester) async {
      await _ac(
        tester,
        SurumNotuGovdesi(blok: _blok(maddeSayisi: 4), onKapat: () {}),
      );
      expect(find.textContaining('Tümünü gör'), findsNothing);
    });

    testWidgets('sürüm boşsa rozet çizilmez', (tester) async {
      await _ac(
        tester,
        SurumNotuGovdesi(
          blok: _blok(maddeSayisi: 1, surum: ''),
          onKapat: () {},
        ),
      );
      expect(find.text('Neler yeni?'), findsOneWidget);
      expect(find.text('3.12.0'), findsNothing);
    });
  });

  group('NelerYeniPage', () {
    testWidgets('sürümler başlıklarıyla listelenir, maddeler kapalı başlar',
        (tester) async {
      await _ac(
        tester,
        NelerYeniPage(
          surum: '3.12.0',
          yukleyici: (_) async => [_blok(maddeSayisi: 2)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sürüm 3.12.0'), findsOneWidget);
      expect(find.text('1. yenilik'), findsOneWidget);
      expect(find.text('2. yenilik'), findsOneWidget);
      // Arşivde hiçbir madde açık gelmez (popup'tan farkı bu).
      expect(_govdeYuksekligi(tester, '1. yenilik açıklaması'), 0);
    });

    testWidgets('arşivde kurulu sürüm yükleyiciye geçer', (tester) async {
      String? istenen;
      await _ac(
        tester,
        NelerYeniPage(
          surum: '3.11.0',
          yukleyici: (s) async {
            istenen = s;
            return const [];
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(istenen, '3.11.0');
    });

    testWidgets('boş arşivde bilgi metni', (tester) async {
      await _ac(
        tester,
        NelerYeniPage(surum: '3.12.0', yukleyici: (_) async => const []),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bu sürüm için not yok.'), findsOneWidget);
    });

    // Ağ hatası ayrı testte: aynı tipte ikinci `pumpWidget` State'i yeniden
    // kurmaz (initState çalışmaz), yükleyici hiç çağrılmazdı.
    testWidgets('ağ hatasında ayrı metin', (tester) async {
      await _ac(
        tester,
        NelerYeniPage(
          surum: '3.12.0',
          yukleyici: (_) async => throw Exception('ağ yok'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sürüm notları şu an yüklenemedi.'), findsOneWidget);
    });
  });
}
