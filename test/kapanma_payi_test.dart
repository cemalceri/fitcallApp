// KapanmaPayi: içerik kısa olsa da genişleyen başlık tam kapanabilmeli.

import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sayfa({required bool payli}) => MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              expandedHeight: 224,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(background: SizedBox()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
            if (payli) const KapanmaPayi(acikYukseklik: 224),
          ],
        ),
      ),
    );

double _maksKaydirma(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .maxScrollExtent;

void main() {
  testWidgets('kısa içerikte pay yoksa başlık kapanamıyor', (tester) async {
    await tester.pumpWidget(_sayfa(payli: false));
    expect(_maksKaydirma(tester), lessThan(224 - kToolbarHeight));
  });

  testWidgets('pay ile başlık tam kapanır', (tester) async {
    await tester.pumpWidget(_sayfa(payli: true));
    expect(_maksKaydirma(tester), closeTo(224 - kToolbarHeight, 0.01));
  });

  testWidgets('uzun içerikte pay eklenmez', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: const [
            SliverAppBar(expandedHeight: 224, pinned: true),
            SliverToBoxAdapter(child: SizedBox(height: 3000)),
            KapanmaPayi(acikYukseklik: 224),
          ],
        ),
      ),
    ));
    final maks = _maksKaydirma(tester);
    // 224 başlık + 3000 içerik − 600 ekran.
    expect(maks, closeTo(224 + 3000 - 600, 0.01));
  });
}
