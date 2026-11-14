// Üye bildirim tercihleri: model ayrıştırma, görünüm ve kapatma onayı.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/bildirim_tercihi_models.dart';
import 'package:fitcall/screens/2_uye/bildirim_tercihleri/widgets/bildirim_tercihleri_gorunumu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bildirim_tercihi_ornekleri.dart';

Widget _uygulama(Widget govde) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: govde),
    );

BildirimTercihleriGorunumu _gorunum({
  BildirimTercihleri? veri,
  String? hata,
  Set<String> kaydedilenler = const {},
  void Function(BildirimTercihGrubu, bool)? onDegistir,
}) =>
    BildirimTercihleriGorunumu(
      veri: veri,
      hata: hata,
      kaydedilenler: kaydedilenler,
      onYenile: () async {},
      onYenidenDene: () {},
      onDegistir: onDegistir ?? (_, __) {},
    );

void main() {
  group('Model', () {
    test('ayrıştırma: boş uyarı null, açık varsayılan true', () {
      final v =
          ornekBildirimTercihleri(profilSayisi: 2, kapali: {'odeme_paket'});
      expect(v.uyeProfilSayisi, 2);
      expect(v.gruplar.map((g) => g.kod),
          ['ders_teyit', 'ders_degisiklik', 'odeme_paket', 'talep']);
      expect(v.gruplar[0].kapatmaUyarisi, isNotNull);
      expect(v.gruplar[2].kapatmaUyarisi, isNull);
      expect(v.gruplar[3].kapatmaUyarisi, isNull); // '' → null
      expect(v.gruplar[2].acik, isFalse);
      expect(
          BildirimTercihGrubu.fromJson(const {'kod': 'x', 'baslik': 'X'}).acik,
          isTrue);
    });

    test('ileGuncelle yalnız o grubu değiştirir', () {
      final v = ornekBildirimTercihleri().ileGuncelle('ders_teyit', false);
      expect(v.gruplar[0].acik, isFalse);
      expect(v.gruplar[0].kapatmaUyarisi, isNotNull);
      expect(v.gruplar.skip(1).every((g) => g.acik), isTrue);
    });

    test('kodsuz grup atılır, eksik alanlar varsayılan', () {
      final v = BildirimTercihleri.fromJson(const {
        'gruplar': [
          {'baslik': 'Kodsuz'}
        ]
      });
      expect(v.gruplar, isEmpty);
      expect(v.uyeProfilSayisi, 1);
    });
  });

  group('Görünüm', () {
    testWidgets('gruplar anahtarlarıyla, dokununca yeni değer gider',
        (tester) async {
      final cagrilar = <(String, bool)>[];
      await tester.pumpWidget(_uygulama(_gorunum(
        veri: ornekBildirimTercihleri(kapali: {'odeme_paket'}),
        onDegistir: (g, d) => cagrilar.add((g.kod, d)),
      )));
      expect(find.text('Ders hatırlatma ve teyit'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(find.textContaining('üye profilinin'), findsNothing);

      await tester.tap(find.text('Ders değişiklikleri'));
      await tester.tap(find.text('Ödeme, paket ve haklar'));
      expect(cagrilar, [('ders_degisiklik', false), ('odeme_paket', true)]);
    });

    testWidgets('kaydı süren grubun anahtarı pasif', (tester) async {
      final cagrilar = <String>[];
      await tester.pumpWidget(_uygulama(_gorunum(
        veri: ornekBildirimTercihleri(),
        kaydedilenler: const {'talep'},
        onDegistir: (g, _) => cagrilar.add(g.kod),
      )));
      await tester.tap(find.text('Talepler ve başvurular'));
      expect(cagrilar, isEmpty);
    });

    testWidgets('çok profilli hesapta hepsine uygulandığı yazılır',
        (tester) async {
      await tester.pumpWidget(
          _uygulama(_gorunum(veri: ornekBildirimTercihleri(profilSayisi: 3))));
      expect(find.textContaining('3 üye profilinin hepsine'), findsOneWidget);
    });

    testWidgets('hata durumunda tekrar dene', (tester) async {
      await tester
          .pumpWidget(_uygulama(_gorunum(hata: 'Sunucuya ulaşılamadı')));
      expect(find.text('Tercihler açılamadı'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsOneWidget);
    });
  });

  testWidgets('kapatma onayı: Kapat true, Vazgeç false döner', (tester) async {
    final grup = ornekBildirimTercihleri().gruplar.first;
    bool? sonuc;
    await tester.pumpWidget(_uygulama(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          sonuc = await BildirimKapatmaOnayi.goster(context, grup);
        },
        child: const Text('aç'),
      ),
    )));

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(
        find.text('Ders hatırlatma ve teyit kapatılsın mı?'), findsOneWidget);
    expect(find.textContaining('ofis seni arayabilir'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(sonuc, isTrue);

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(sonuc, isFalse);
  });
}
