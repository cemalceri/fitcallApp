// Ekip: "Bu ay" seçiliyken kartlar "Bugün giriş yok" demez; dönemde kaç gün
// gelindiğini yazar (Bugün seçiliyken ilk giriş saati).

import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EkipData _veri(String donem) => EkipData.fromJson({
      'donem': donem,
      'ozet': {'kisi_sayisi': 2, 'gelen_sayisi': 1},
      'kisiler': [
        {'id': 1, 'ad_soyad': 'Ayşe Ofis', 'bugun_giris': null, 'giris_gun_sayisi': 9},
        {'id': 2, 'ad_soyad': 'Ece Su', 'bugun_giris': null, 'giris_gun_sayisi': 0},
      ],
      'antrenorler': [
        {'id': 7, 'ad_soyad': 'Can Hoca', 'bugun_giris': null, 'giris_gun_sayisi': 4},
      ],
    });

Future<void> _ciz(WidgetTester tester, String donem) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EkipGorunumu(data: _veri(donem), onKisi: (_) {}),
          ),
        ),
      ),
    );

void main() {
  testWidgets('bu ay: gelinen gün yazar, "Bugün giriş yok" demez', (tester) async {
    await _ciz(tester, 'bu_ay');
    expect(find.text('Bu ay 9 gün geldi'), findsOneWidget);
    expect(find.text('Bu ay 4 gün geldi'), findsOneWidget);
    expect(find.text('Bu ay giriş yok'), findsOneWidget);
    expect(find.text('Bugün giriş yok'), findsNothing);
    expect(find.text('Bu ay gelen'), findsNWidgets(2));
  });

  testWidgets('bugün: giriş yoksa "Bugün giriş yok"', (tester) async {
    await _ciz(tester, 'bugun');
    expect(find.text('Bugün giriş yok'), findsNWidgets(3));
    expect(find.text('Bugün giriş yapan'), findsNWidgets(2));
  });
}
