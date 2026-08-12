// Geçici doğrulama: iskelet 300 ms'den önce çizilmiyor, sonra çiziliyor.
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IskeletGecikmeli 300 ms sonra görünür', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: IskeletListe(satirSayisi: 2, kaydirilabilir: false)),
    ));
    await tester.pump();
    expect(find.byType(IskeletKutu), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(IskeletKutu), findsWidgets);
  });
}
