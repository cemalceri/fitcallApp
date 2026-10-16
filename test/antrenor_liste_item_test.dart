// Antrenörler satırı: iki ayrı dokunma alanı.
//
// Sol taraf (ad, oklu) hakediş saatlerine, sağdaki puan hücresi ("Yorumlar ›")
// değerlendirmelere gider. Önceki alt sayfa (iki seçenek) kaldırıldı
// (kullanıcı kararı 2026-10-16).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AntrenorListeItem _antrenor({double? puan = 4.8, int sayi = 23}) =>
    AntrenorListeItem.fromJson({
      'id': 7,
      'adi': 'Can',
      'soyadi': 'ALTINER',
      'ad_soyad': 'Can ALTINER',
      'renk': '#2438C8',
      'aktif_mi': true,
      'bugunki_ders_sayisi': 3,
      'haftalik_ders_sayisi': 17,
      'ortalama_puan': puan,
      'degerlendirme_sayisi': sayi,
      'ogrenci_sayisi': 25,
    });

void main() {
  Future<List<String>> kur(WidgetTester tester, AntrenorListeItem a) async {
    final secilen = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(
        body: AntrenorListeItemWidget(
          antrenor: a,
          onHakedis: () => secilen.add('hakedis'),
          onDegerlendirmeler: () => secilen.add('degerlendirmeler'),
        ),
      ),
    ));
    return secilen;
  }

  testWidgets('ad hakedişe, puan hücresi değerlendirmelere gider',
      (tester) async {
    final secilen = await kur(tester, _antrenor());
    await tester.tap(find.text('Can ALTINER'));
    await tester.tap(find.text('Yorumlar'));
    expect(secilen, ['hakedis', 'degerlendirmeler']);
  });

  testWidgets('iki hedefin de oku var, hücre ortalama ve sayıyı yazar',
      (tester) async {
    await kur(tester, _antrenor());
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    expect(find.text('4.8 (23)', findRichText: true), findsOneWidget);
  });

  testWidgets('değerlendirmesi olmayanda hücre "Puan yok" yazar ve gitmez',
      (tester) async {
    final secilen = await kur(tester, _antrenor(puan: null, sayi: 0));
    expect(find.text('Puan yok'), findsOneWidget);
    expect(find.text('Yorumlar'), findsNothing);
    await tester.tap(find.text('Puan yok'));
    expect(secilen, isEmpty);
  });

  testWidgets('sayıyı göndermeyen sunucuda ortalama yine görünür ve gider',
      (tester) async {
    final eski = AntrenorListeItem.fromJson({
      'id': 7,
      'ad_soyad': 'Can ALTINER',
      'aktif_mi': true,
      'ortalama_puan': '4.80',
      'ogrenci_sayisi': 25,
    });
    expect(eski.degerlendirmeSayisi, isNull);
    final secilen = await kur(tester, eski);
    expect(find.text('Puan yok'), findsNothing);
    expect(find.text('4.8', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Yorumlar'));
    expect(secilen, ['degerlendirmeler']);
  });

  test('büyük sayı kısaltılır', () {
    expect(PuanRozeti.sayiMetni(999), '999');
    expect(PuanRozeti.sayiMetni(1500), '1B+');
  });
}
