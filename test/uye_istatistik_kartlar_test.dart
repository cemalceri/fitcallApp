// Yönetici Üyeler: sayılı kartlar filtrenin kendisi (kullanıcı kararı
// 2026-10-16). Tümü/Aktif/Pasif/Borçlular butonları kalktı; Toplam · Aktif ·
// Pasif · Borçlu · Yeni kartına dokununca liste süzülür.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

UyeIstatistik _istatistik({bool borcluVar = true}) => UyeIstatistik.fromJson({
      'toplam_uye': 184,
      'aktif_uye': 161,
      'pasif_uye': 23,
      'bu_ay_yeni_kayit': 7,
      if (borcluVar) 'borclu_uye': 12,
    });

UyeListeItem _uye(int no) => UyeListeItem.fromJson({
      'id': no,
      'uye_no': 10400 + no,
      'adi': 'Deniz',
      'soyadi': 'Yılmaz $no',
      'ad_soyad': 'Deniz Yılmaz $no',
      'telefon': '5551112233',
      'seviye_rengi': '',
      'aktif_mi': true,
      'uye_tipi': 1,
      'uye_turu': 'Yetişkin',
      'bakiye': 0,
    });

Widget _sar(Widget w) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: w),
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('beş kart sayısıyla; dokunulan kartın filtresi seçilir',
      (tester) async {
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: 'tumu',
      onSec: secilenler.add,
    )));

    for (final (etiket, sayi) in [
      ('Toplam', '184'),
      ('Aktif', '161'),
      ('Pasif', '23'),
      ('Borçlu', '12'),
      ('Yeni', '7'),
    ]) {
      expect(find.text(etiket), findsOneWidget);
      expect(find.text(sayi), findsOneWidget, reason: etiket);
    }

    await tester.tap(find.text('Borçlu'));
    await tester.tap(find.text('Yeni'));
    await tester.tap(find.text('Pasif'));
    await tester.tap(find.text('Aktif'));
    expect(secilenler, ['borclu', 'yeni', 'pasif', 'aktif']);
  });

  testWidgets('seçili karta dokunmak listeyi yeniden yüklemez', (tester) async {
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: 'borclu',
      onSec: secilenler.add,
    )));

    await tester.tap(find.text('Borçlu'));
    expect(secilenler, isEmpty);
    await tester.tap(find.text('Toplam'));
    expect(secilenler, ['tumu']);
  });

  testWidgets('istatistik gelmeden "–" yazılır, kartlar yine seçilir',
      (tester) async {
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: null,
      secili: 'tumu',
      onSec: secilenler.add,
    )));

    expect(find.text('–'), findsNWidgets(5));
    await tester.tap(find.text('Yeni'));
    expect(secilenler, ['yeni']);
  });

  testWidgets('borclu_uye göndermeyen eski sunucuda Borçlu "–", 0 değil',
      (tester) async {
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(borcluVar: false),
      secili: 'tumu',
      onSec: (_) {},
    )));

    expect(find.text('–'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('ekran okuyucu kartı okur, seçili durumu bilir ve seçebilir',
      (tester) async {
    final semantik = tester.ensureSemantics();
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: 'tumu',
      onSec: secilenler.add,
    )));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Toplam 184 üye')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Borçlu 12 üye')),
      isSemantics(isButton: true, isSelected: false, hasTapAction: true),
    );

    tester.semantics.tap(find.semantics.byLabel('Borçlu 12 üye'));
    expect(secilenler, ['borclu']);
    semantik.dispose();
  });

  testWidgets('liste görünümü: başlıktaki kart filtreyi değiştirir',
      (tester) async {
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyelerGorunumu(
      istatistik: _istatistik(),
      uyeler: [_uye(1), _uye(2)],
      toplam: 2,
      yukleniyor: false,
      hata: null,
      filtre: 'yeni',
      aramaDenetleyicisi: TextEditingController(),
      onFiltre: secilenler.add,
      onYenile: () async {},
      onYenidenDene: () {},
      onUyeSec: (_) {},
      onAra: (_) {},
      onWhatsapp: (_) {},
    )));

    // "Yeni" filtresinde liste harf grubu değil, tek grup.
    expect(find.text('Bu ay kaydolanlar'), findsOneWidget);
    // Eski Tümü/Aktif/Pasif/Borçlular butonları yok.
    expect(find.text('Tümü'), findsNothing);
    expect(find.text('Borçlular'), findsNothing);

    await tester.tap(find.text('Borçlu'));
    expect(secilenler, ['borclu']);
  });

  testWidgets('liste boşken de kartlar seçilebilir', (tester) async {
    final secilenler = <String>[];
    await tester.pumpWidget(_sar(UyelerGorunumu(
      istatistik: _istatistik(),
      uyeler: const [],
      toplam: 0,
      yukleniyor: false,
      hata: null,
      filtre: 'borclu',
      aramaDenetleyicisi: TextEditingController(),
      onFiltre: secilenler.add,
      onYenile: () async {},
      onYenidenDene: () {},
      onUyeSec: (_) {},
      onAra: (_) {},
      onWhatsapp: (_) {},
    )));

    expect(find.text('Bu filtreye uyan üye bulunmuyor.'), findsOneWidget);
    await tester.tap(find.text('Toplam'));
    expect(secilenler, ['tumu']);
  });
}
