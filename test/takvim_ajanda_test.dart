// test/takvim_ajanda_test.dart
//
// Ajanda (liste) görünümü hafta şeridiyle konuşuyor mu?
//
// Neden var: liste haftanın tamamını gösterdiği için üstteki şeritten bir güne
// basmak hiçbir şey değiştirmiyordu — kullanıcı "liste güncellenmiyor" diye
// bildirdi. Artık liste seçili günün başlığına kayıyor. Kaydırma hedefi ölçüyle
// değil hesapla bulunuyor (sliver'lar görüş alanı dışında layout edilmiyor), bu
// yüzden satır/başlık yüksekliği sabit; bu test o hesabın tutmasını koruyor.

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_ajanda.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Ajandanın kendi ölçüleri (bkz. takvim_ajanda.dart).
const double _baslik = 40;
const double _satir = 68; // yazı ölçeği 1.0
const double _ara = 8;
const double _altBosluk = 16;

double _bolum(int dersAdedi) =>
    _baslik + dersAdedi * _satir + (dersAdedi - 1) * _ara + _altBosluk;

EtkinlikModel _ders(
    {required int id, required DateTime gun, required int saat}) {
  String iki(int d) => d.toString().padLeft(2, '0');
  final tarih = '${gun.year}-${iki(gun.month)}-${iki(gun.day)}';
  return EtkinlikModel.fromMap({
    'id': id,
    'kort': 1,
    'kort_adi': 'Kapalı Kort 1',
    'baslangic_tarih_saat': '${tarih}T${iki(saat)}:00:00+03:00',
    'bitis_tarih_saat': '${tarih}T${iki(saat + 1)}:00:00+03:00',
    'seviye': 'Kirmizi',
    'iptal_mi': false,
    'is_active': true,
    'is_deleted': false,
    'olusturulma_zamani': '${tarih}T${iki(saat)}:00:00+03:00',
    'guncellenme_zamani': '${tarih}T${iki(saat)}:00:00+03:00',
    'urun': 1,
    'urun_adi': 'Grup Dersi',
    'antrenor': 1,
    'antrenor_adi': 'Ayşe Yılmaz',
    'ucret': 0,
    'uyeler': const [],
  });
}

/// 2026-07-20 (Pzt) → 23 (Per); her günde 4 ders.
final List<DateTime> _gunler =
    List.generate(4, (i) => DateTime(2026, 7, 20 + i));

List<EtkinlikModel> _haftaDersleri() {
  var id = 1;
  return [
    for (final gun in _gunler)
      for (var i = 0; i < 4; i++) _ders(id: id++, gun: gun, saat: 9 + i),
  ];
}

Widget _uygulama({
  required DateTime? secilenGun,
  List<EtkinlikModel>? dersler,
}) {
  return MaterialApp(
    locale: const Locale('tr', 'TR'),
    theme: FitcallTema.acik,
    home: Scaffold(
      body: TakvimAjanda(
        dersler: dersler ?? _haftaDersleri(),
        secilenGun: secilenGun,
        onLessonTap: (_) {},
      ),
    ),
  );
}

double _ofset(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byType(CustomScrollView))
    .controller!
    .offset;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr', null);
  });

  // Dört günün toplamı (4 × 352 = 1408) görüş alanını (480) aşıyor; kaydırma
  // gerçekten yapılabiliyor.
  testWidgets('seçili gün değişince liste o günün başlığına kayar',
      (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_uygulama(secilenGun: _gunler.first));
    await tester.pumpAndSettle();

    expect(_ofset(tester), 0, reason: 'ilk gün seçiliyken liste başta durmalı');

    // Üçüncü güne bas → liste o günün bölümüne kaymalı.
    await tester.pumpWidget(_uygulama(secilenGun: _gunler[2]));
    await tester.pumpAndSettle();

    expect(_ofset(tester), closeTo(_bolum(4) * 2, 0.5));

    // Başlık yazısı 40px'lik çubuğun içinde dikey ortalı; önceki günlerin
    // başlıkları tepede yığılmamalı (bkz. SliverMainAxisGroup).
    final baslikUst =
        tester.getTopLeft(find.text(TimeUtils.formatDateFull(_gunler[2]))).dy;
    expect(
      baslikUst,
      lessThan(_baslik),
      reason: 'seçili günün yapışkan başlığı ekranın tepesinde olmalı',
    );
    expect(baslikUst, greaterThanOrEqualTo(0));
  });

  testWidgets('dersi olmayan gün seçilince "ders yok" satırı gösterilir',
      (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Sadece ilk günün dersleri var; kullanıcı ikinci güne basıyor.
    final tekGun = _haftaDersleri()
        .where((d) =>
            TimeUtils.normalizeDate(d.baslangicTarihSaat) == _gunler.first)
        .toList();

    await tester.pumpWidget(
      _uygulama(secilenGun: _gunler[1], dersler: tekGun),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bu gün için ders yok'), findsOneWidget);
    expect(find.text('Ders yok'), findsOneWidget); // başlıktaki sayaç
  });

  testWidgets('seçili gün verilmezse ajanda kendiliğinden kaymaz',
      (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_uygulama(secilenGun: null));
    await tester.pumpAndSettle();

    expect(_ofset(tester), 0);
  });
}
