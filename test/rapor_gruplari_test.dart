// Raporlar (kullanıcı isteği 2026-10-16): ciro/tahsilat ile kort/antrenör
// gruplarının kendi dönem seçicisi var; ısı haritası en altta, hep bu hafta.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_gruplari.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

RaporlarData _rapor() => RaporlarData.fromJson({
      'ozet_kartlar': [
        {
          'baslik': 'Toplam Ciro',
          'deger': '₺8.400',
          'alt_baslik': '14 ders',
          'ikon': 'trending_up',
          'renk': '#4CAF50'
        },
      ],
      'doluluk_raporu': [
        {
          'kort_adi': 'Merkez Kort',
          'kort_id': 1,
          'toplam_saat': 16,
          'dolu_saat': 9,
          'doluluk_yuzdesi': 56.3
        },
      ],
      'antrenor_performans': [
        {
          'antrenor_id': 1,
          'antrenor_adi': 'Ayşe Yılmaz',
          'toplam_ders': 12,
          'tamamlanan_ders': 10,
          'iptal_ders': 1,
          'ortalama_puan': 4.7
        },
      ],
    });

Widget _sar(Widget w) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: SingleChildScrollView(child: w)),
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('iki grubun seçicisi birbirinden bağımsız', (tester) async {
    DonemFiltresi? ciroSecimi;
    DonemFiltresi? kortSecimi;
    await tester.pumpWidget(_sar(Column(children: [
      RaporDonemGrubu(
        donem: DonemFiltresi.buAy,
        onDonemChanged: (d) => ciroSecimi = d,
        yukleniyor: false,
        data: _rapor(),
      ),
      RaporKortAntrenorGrubu(
        donem: DonemFiltresi.buHafta,
        onDonemChanged: (d) => kortSecimi = d,
        yukleniyor: false,
        data: _rapor(),
      ),
    ])));

    final kortGrubu = find.byType(RaporKortAntrenorGrubu);
    expect(
      find.descendant(of: kortGrubu, matching: find.text('Kort ve antrenör')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: kortGrubu, matching: find.text('Merkez Kort')),
      findsOneWidget,
    );
    // Ciro özeti kort grubunda yok.
    expect(
      find.descendant(of: kortGrubu, matching: find.text('Toplam Ciro')),
      findsNothing,
    );

    final kortBugun =
        find.descendant(of: kortGrubu, matching: find.text('Bugün'));
    await tester.ensureVisible(kortBugun);
    await tester.tap(kortBugun);
    await tester.pump();
    expect(kortSecimi, DonemFiltresi.bugun);
    expect(ciroSecimi, isNull);
  });

  testWidgets('ısı haritası etiketi haftanın tamamı: Pzt–Paz', (tester) async {
    await tester.pumpWidget(_sar(RaporHaftalikYogunluk(
      data: DolulukHaritasi.fromJson(const {
        'gunler': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
        'saatler': [10],
        'hucreler': [
          {
            'saat': 10,
            'degerler': [1, 0, 0, 0, 0, 0, 2]
          },
        ],
        'max_sayi': 2,
        'toplam_ders': 3,
      }),
      bugun: DateTime(2026, 10, 16), // Cuma
    )));

    expect(find.text('Bu hafta · 12 – 18 Eki'), findsOneWidget);
    expect(find.text('3 ders'), findsOneWidget);
  });

  test('ay dönen hafta aralığı', () {
    expect(RaporHaftalikYogunluk.haftaAraligi(DateTime(2026, 10, 1)),
        '28 Eyl – 4 Eki');
    expect(RaporHaftalikYogunluk.haftaAraligi(DateTime(2026, 10, 18)),
        '12 – 18 Eki');
  });
}
