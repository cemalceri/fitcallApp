// Kabuğun sol menüsü her sekmeden açılır; kabuktan itilen sayfada menü
// butonu çıkmaz, geri oku kalır.

import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kabuk sekmesinde menü butonu drawer\'ı açar', (tester) async {
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: key,
        drawer: const Drawer(child: Text('Sol menü')),
        body: KabukMenusu(
          menuyuAc: () => key.currentState?.openDrawer(),
          // Sekmenin kendi Scaffold'u: Scaffold.of kabuğa ulaşamaz.
          child: Scaffold(
            appBar: AppBar(
              leading: Builder(builder: (c) => kabukMenuLeading(c)!),
            ),
            body: const KabukMenuButonu(),
          ),
        ),
      ),
    ));

    expect(find.byTooltip('Menü'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Menü').last);
    await tester.pumpAndSettle();
    expect(find.text('Sol menü'), findsOneWidget);
  });

  testWidgets('itilen sayfada menü butonu yok, geri oku var', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: KabukMenusu(
        menuyuAc: () {},
        child: Builder(
          builder: (c) => TextButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (c) => Scaffold(
                  appBar: AppBar(leading: kabukMenuLeading(c)),
                  body: const KabukMenuButonu(),
                ),
              ),
            ),
            child: const Text('Aç'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Menü'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
