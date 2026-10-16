// Raporlar'daki uzun listeler (aylık ciro/tahsilat günleri, kortlar,
// antrenörler) kendi kartında kayar; kısa liste içerik kadar yer kaplar.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_kaydirmali_liste.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sar(int satir) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            RaporKaydirmaliListe(
              satirlar: [
                for (var i = 0; i < satir; i++)
                  SizedBox(height: 30, child: Text('Gün $i')),
              ],
            ),
            const Text('Alttaki bölüm'),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('uzun liste sınırda durur, kendi içinde kayar', (tester) async {
    await tester.pumpWidget(_sar(31));
    final liste = tester.getSize(find.byType(RaporKaydirmaliListe));
    expect(liste.height, 186);
    // Alttaki bölüm 31 satırın (930 px) altına itilmiyor.
    expect(tester.getTopLeft(find.text('Alttaki bölüm')).dy, lessThan(200));

    expect(find.text('Gün 30'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('Gün 30'), findsOneWidget);
  });

  testWidgets('kısa liste içerik kadar yer kaplar', (tester) async {
    await tester.pumpWidget(_sar(3));
    expect(tester.getSize(find.byType(RaporKaydirmaliListe)).height, 90);
  });
}
