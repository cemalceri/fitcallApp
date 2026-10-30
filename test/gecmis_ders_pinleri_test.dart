// Üye geçmiş derslerinde iki ayrı pin (kullanıcı kararı 2026-10-30).
//
// "Ders" pini antrenörün ders onayından, "Yoklama" pini yalnız yoklamadan
// gelir: grup dersinde ders yapıldı demek üyenin katıldığı anlamına gelmez.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/screens/2_uye/gecmis_dersler/widgets/gecmis_dersler_listesi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

GecmisDersModel _ders({
  bool iptal = false,
  bool? dersYapildi,
  Map<String, dynamic>? katilim,
}) =>
    GecmisDersModel.fromJson({
      'id': 1,
      'baslangic_tarih_saat': '2026-10-20T10:00:00+03:00',
      'bitis_tarih_saat': '2026-10-20T11:00:00+03:00',
      'iptal_mi': iptal,
      'ders_yapildi': dersYapildi,
      'katilim': katilim,
    });

Future<void> _goster(WidgetTester tester, GecmisDersModel ders) =>
    tester.pumpWidget(MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(
        body: GecmisDerslerListesi(dersler: [ders], onDegerlendir: (_) {}),
      ),
    ));

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('yapılmış derste katılım yoklamadan okunur', (tester) async {
    await _goster(
      tester,
      _ders(dersYapildi: true, katilim: {'katildi': false}),
    );
    expect(find.text('Ders: Yapıldı'), findsOneWidget);
    expect(find.text('Yoklama: Katılmadı'), findsOneWidget);
  });

  testWidgets('yoklama yoksa ders onayından "katıldı" türetilmez',
      (tester) async {
    await _goster(tester, _ders(dersYapildi: true));
    expect(find.text('Ders: Yapıldı'), findsOneWidget);
    expect(find.text('Yoklama: Girilmedi'), findsOneWidget);
    expect(find.textContaining('Katıldı'), findsNothing);
  });

  testWidgets('plan dışı katılım yoklama pininde belirtilir', (tester) async {
    await _goster(
      tester,
      _ders(dersYapildi: true, katilim: {'katildi': true, 'plan_disi_mi': true}),
    );
    expect(find.text('Yoklama: Katıldı (plan dışı)'), findsOneWidget);
  });

  testWidgets('yapılmamış derste otomatik "katılmadı" gösterilmez',
      (tester) async {
    await _goster(
      tester,
      _ders(dersYapildi: false, katilim: {'katildi': false}),
    );
    expect(find.text('Ders: Yapılmadı'), findsOneWidget);
    expect(find.textContaining('Yoklama'), findsNothing);
  });

  testWidgets('onay bekleyen derste yalnız ders pini var', (tester) async {
    await _goster(tester, _ders());
    expect(find.text('Ders: Onay bekliyor'), findsOneWidget);
    expect(find.textContaining('Yoklama'), findsNothing);
  });

  testWidgets('iptal derste yalnız iptal pini var', (tester) async {
    await _goster(
      tester,
      _ders(iptal: true, katilim: {'katildi': false}),
    );
    expect(find.text('İptal'), findsOneWidget);
    expect(find.textContaining('Yoklama'), findsNothing);
  });
}
