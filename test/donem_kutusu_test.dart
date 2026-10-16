// Yönetici panosu dönem gruplaması (kullanıcı kararı 2026-10-16, "A").
//
// Dönem seçimi yalnız ona bağlı kartlarla aynı kutuda; aktif üye ve toplam
// alacak o anki durum olarak ayrı grupta. Raporlar'da sunucunun özet kart
// listesindeki aktif üye kartı dönem kartlarından ayrılır.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

DashboardData _pano() => DashboardData.fromJson({
      'ciro': {'toplam_ciro': '8400', 'ders_sayisi': 14},
      'tahsilat': {'toplam_tahsilat': '5250', 'islem_sayisi': 6},
      'ders': {'toplam_ders': 18, 'tamamlanan_ders': 14, 'iptal_edilen_ders': 2},
      'uye': {'aktif_uye_sayisi': 212},
      'toplam_alacak': {'toplam_borc': '41300', 'borclu_uye_sayisi': 9},
    });

Widget _sar(Widget w) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: SingleChildScrollView(child: w)),
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('dönem grubu ciro/tahsilat/ders/iptal, şu an grubu üye/alacak',
      (tester) async {
    await tester.pumpWidget(_sar(Column(children: [
      StatCardsGrid(data: _pano(), grup: PanoKartGrubu.donem),
      const Divider(key: Key('ayrac')),
      StatCardsGrid(data: _pano(), grup: PanoKartGrubu.anlik),
    ])));

    final ayracY = tester.getTopLeft(find.byKey(const Key('ayrac'))).dy;
    for (final b in ['Ciro', 'Tahsilat', 'İptal Edilen']) {
      expect(tester.getTopLeft(find.text(b)).dy, lessThan(ayracY), reason: b);
    }
    for (final b in ['Aktif Üye', 'Toplam Alacak']) {
      expect(tester.getTopLeft(find.text(b)).dy, greaterThan(ayracY),
          reason: b);
    }
  });

  testWidgets('dönem kutusu seçiciyi ve seçimi taşır', (tester) async {
    DonemFiltresi? secilen;
    await tester.pumpWidget(_sar(DonemKutusu(
      seciliDonem: DonemFiltresi.bugun,
      onDonemChanged: (d) => secilen = d,
      yukleniyor: false,
      child: StatCardsGrid(data: _pano(), grup: PanoKartGrubu.donem),
    )));
    await tester.tap(find.text(DonemFiltresi.buAy.label));
    expect(secilen, DonemFiltresi.buAy);
  });

  testWidgets('yüklenirken kartlar yerine aynı boyda iskelet', (tester) async {
    Future<double> yukseklik(bool yukleniyor) async {
      await tester.pumpWidget(_sar(DonemKutusu(
        key: ValueKey(yukleniyor),
        seciliDonem: DonemFiltresi.bugun,
        onDonemChanged: (_) {},
        yukleniyor: yukleniyor,
        child: StatCardsGrid(data: _pano(), grup: PanoKartGrubu.donem),
      )));
      await tester.pump(const Duration(milliseconds: 400));
      return tester.getSize(find.byType(DonemKutusu)).height;
    }

    final dolu = await yukseklik(false);
    final bos = await yukseklik(true);
    expect(find.text('Ciro'), findsNothing);
    expect(bos, closeTo(dolu, 1));
  });

  test('raporlarda yalnız aktif üye kartı dönemden bağımsız', () {
    RaporOzetKarti k(String b) =>
        RaporOzetKarti.fromJson({'baslik': b, 'deger': '1', 'ikon': 'x'});
    expect(k('Aktif Üye').anlikMi, isTrue);
    for (final b in ['Toplam Ciro', 'Toplam Tahsilat', 'Toplam Ders']) {
      expect(k(b).anlikMi, isFalse, reason: b);
    }
  });
}
