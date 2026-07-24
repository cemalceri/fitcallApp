// Yönetici program ekranındaki sheet/dialog'ların dar ekranda taşmadığını ve
// temel etkileşimlerinin çalıştığını doğrular.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/ders_iptal_dialog.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/ders_sil_dialog.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/etkinlik_form_sheet.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/uye_secim_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

EtkinlikFormVerileri _formVerileri({
  bool duzenleme = false,
  int uyeSayisi = 3,
  bool urunKilitli = false,
}) {
  return EtkinlikFormVerileri.fromJson({
    'kortlar': [
      {'id': 1, 'adi': 'Kort 1', 'sira': 1},
      {'id': 2, 'adi': 'Çok Uzun İsimli Kapalı Kort Numara İki', 'sira': 2},
    ],
    'antrenorler': [
      {'id': 1, 'ad_soyad': 'Ayşe Yılmaz', 'renk': '#2563EB', 'pasif': false},
      {'id': 2, 'ad_soyad': 'Pasif Antrenör', 'renk': '#999999', 'pasif': true},
    ],
    'urunler': [
      {'id': 1, 'adi': 'Grup Dersi', 'urun_tipi': 'PAKET', 'telafi_mi': false},
      {'id': 2, 'adi': 'Telafi Ders', 'urun_tipi': 'PAKET', 'telafi_mi': true},
    ],
    'seviyeler': [
      {'kod': 'Kirmizi', 'ad': 'Kırmızı', 'renk': '#e74c3c'},
      {'kod': 'Yesil', 'ad': 'Yeşil', 'renk': '#2ecc71'},
    ],
    'uyeler': [
      for (var i = 1; i <= uyeSayisi; i++)
        {
          'id': i,
          'ad_soyad': 'Üye $i Çok Uzun Soyadıyla Birlikte',
          'uye_no': 'U-$i',
          'telefon': '555000000$i',
          'pasif': i == uyeSayisi,
        }
    ],
    'iptal_sebepleri': [
      {'kod': 'HASTALIK', 'ad': 'Hastalık'},
      {'kod': 'DIGER', 'ad': 'Diğer'},
    ],
    'iptal_modlari': [
      {'kod': 'STANDART', 'ad': 'Standart', 'aciklama': '24 saat kuralı işler.'},
      {'kod': 'TELAFI_VER', 'ad': 'Telafi ver', 'aciklama': 'Telafi tanımlanır.'},
      {'kod': 'HAKKI_IADE_ET', 'ad': 'Hakkı iade et', 'aciklama': 'Düşüm yapılmaz.'},
      {'kod': 'BORC_YAZMA', 'ad': 'Borç yazma', 'aciklama': 'Borç yansıtılmaz.'},
    ],
    'secili_uye_idler': duzenleme ? [1, 2] : <int>[],
    'etkinlik': duzenleme
        ? {
            'id': 7,
            'urun_id': 1,
            'kort_id': 1,
            'antrenor_id': 1,
            'yardimci_antrenor_id': null,
            'seviye': 'Kirmizi',
            'antrenor_katsayisi': '1.50',
            'ucret': '25',
            'aciklama': 'Not',
            'baslangic_tarih_saat': '2026-07-23T10:00:00+03:00',
            'bitis_tarih_saat': '2026-07-23T11:00:00+03:00',
            'iptal_mi': false,
            'sabit_plan_mi': urunKilitli,
            'urun_kilitli_mi': urunKilitli,
          }
        : null,
  });
}

/// Dar ekran: taşma (overflow) kontrolleri için.
Future<void> _kucukEkran(WidgetTester tester, Widget cocuk) async {
  await _ekran(tester, cocuk, const Size(360, 640));
}

/// Uzun ekran: içerik doğrulamaları için. Sheet'ler DraggableScrollableSheet
/// içinde tembel çizildiğinden, kaydırmaya gerek kalmadan tüm alanlar oluşsun.
Future<void> _uzunEkran(WidgetTester tester, Widget cocuk) async {
  await _ekran(tester, cocuk, const Size(400, 2200));
}

Future<void> _ekran(WidgetTester tester, Widget cocuk, Size boyut) async {
  tester.view.physicalSize = boyut;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: cocuk)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('EtkinlikFormSheet', () {
    testWidgets('yeni kayıt dar ekranda taşma vermez', (tester) async {
      await _kucukEkran(tester, EtkinlikFormSheet(veriler: _formVerileri()));
      expect(tester.takeException(), isNull);
      expect(find.text('Yeni ders'), findsOneWidget);
    });

    testWidgets('düzenleme modunda mevcut değerleri gösterir', (tester) async {
      await _uzunEkran(
        tester,
        EtkinlikFormSheet(veriler: _formVerileri(duzenleme: true)),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Dersi düzenle'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
      expect(find.text('1.50'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Güncelle'), findsOneWidget);
    });

    testWidgets('sabit plan uyarısı gösterilir', (tester) async {
      await _kucukEkran(
        tester,
        EtkinlikFormSheet(veriler: _formVerileri(duzenleme: true, urunKilitli: true)),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('sabit plandan üretilmiş'), findsOneWidget);
    });

    testWidgets('yeni kayıtta eksik zorunlu alanlar uyarı verir', (tester) async {
      // Yeni kayıtta ürün ve antrenör ön seçili gelmez (web'deki modal da böyle)
      await _uzunEkran(tester, EtkinlikFormSheet(veriler: _formVerileri()));

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('ürün, antrenör seçilmeli.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('alanlar dolu ama üye yoksa uyarı çıkar', (tester) async {
      // Düzenleme modunda tüm alanlar dolu; katılımcı listesi boşaltılmış
      final veriler = EtkinlikFormVerileri.fromJson({
        ..._formVerileriHam(),
        'etkinlik': {
          'id': 7,
          'urun_id': 1,
          'kort_id': 1,
          'antrenor_id': 1,
          'seviye': 'Kirmizi',
          'antrenor_katsayisi': '1.0',
          'ucret': '0',
          'aciklama': '',
          'baslangic_tarih_saat': '2026-07-23T10:00:00+03:00',
          'bitis_tarih_saat': '2026-07-23T11:00:00+03:00',
          'iptal_mi': false,
          'sabit_plan_mi': false,
          'urun_kilitli_mi': false,
        },
        'secili_uye_idler': <int>[],
      });

      await _uzunEkran(tester, EtkinlikFormSheet(veriler: veriler));

      await tester.tap(find.text('Güncelle'));
      await tester.pumpAndSettle();

      expect(
          find.text('Kayıt için en az bir üye seçmelisiniz.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('çok sayıda seçili üyede katılımcı kutusu taşmaz',
        (tester) async {
      final veriler = EtkinlikFormVerileri.fromJson({
        ..._formVerileriHam(uyeSayisi: 15),
        'secili_uye_idler': List.generate(15, (i) => i + 1),
      });

      await _kucukEkran(tester, EtkinlikFormSheet(veriler: veriler));
      expect(tester.takeException(), isNull);
    });
  });

  group('UyeSecimSheet', () {
    testWidgets('arama listeyi filtreler', (tester) async {
      final veriler = _formVerileri(uyeSayisi: 5);

      await _kucukEkran(
        tester,
        UyeSecimSheet(uyeler: veriler.uyeler, seciliIdler: const [1]),
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(5));

      await tester.enterText(find.byType(TextField), 'U-3');
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pasif üye etiketli gösterilir', (tester) async {
      final veriler = _formVerileri(uyeSayisi: 3);
      await _kucukEkran(
        tester,
        UyeSecimSheet(uyeler: veriler.uyeler, seciliIdler: const []),
      );

      expect(find.text('Pasif'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('seçim sayacı güncellenir', (tester) async {
      final veriler = _formVerileri(uyeSayisi: 3);
      await _kucukEkran(
        tester,
        UyeSecimSheet(uyeler: veriler.uyeler, seciliIdler: const []),
      );

      expect(find.text('0 seçili'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('1 seçili'), findsOneWidget);
    });
  });

  group('DersIptalDialog', () {
    testWidgets('sebep seçilmeden onay butonu pasif', (tester) async {
      final veriler = _formVerileri();
      await _kucukEkran(
        tester,
        DersIptalDialog(
          sebepler: veriler.iptalSebepleri,
          modlar: veriler.iptalModlari,
          dersOzeti: '23.07.2026 10:00 · Kort 1',
        ),
      );

      final buton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Dersi iptal et'),
      );
      expect(buton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dört mod da listelenir ve taşma olmaz', (tester) async {
      final veriler = _formVerileri();
      await _kucukEkran(
        tester,
        DersIptalDialog(
          sebepler: veriler.iptalSebepleri,
          modlar: veriler.iptalModlari,
          dersOzeti: '23.07.2026 10:00 · Kort 1',
        ),
      );

      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('DersSilDialog', () {
    testWidgets('telafi uyarısı en üstte gösterilir', (tester) async {
      final etki = SilmeEtkisi.fromJson({
        'katilimci_sayisi': 3,
        'paket_kullanimi': 3,
        'telafi_kaybolacak': 2,
        'telafi_serbest_kalacak': 0,
        'teyit_sayisi': 1,
        'onay_sayisi': 1,
        'degerlendirme_sayisi': 0,
        'ders': {'tarih': '23.07.2026', 'saat': '10:00', 'kort_adi': 'Kort 1'},
      });

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: DersSilDialog(etki: etki)));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 telafi hakkı silinecek'), findsOneWidget);
      expect(find.textContaining('geri alınamaz'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('çok kalemli etkide dialog taşmaz', (tester) async {
      final etki = SilmeEtkisi.fromJson({
        'katilimci_sayisi': 12,
        'paket_kullanimi': 12,
        'telafi_kaybolacak': 5,
        'telafi_serbest_kalacak': 4,
        'teyit_sayisi': 12,
        'onay_sayisi': 2,
        'degerlendirme_sayisi': 9,
        'ders': {'tarih': '23.07.2026', 'saat': '10:00', 'kort_adi': 'Kort 1'},
      });

      tester.view.physicalSize = const Size(320, 520);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: DersSilDialog(etki: etki)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// _formVerileri ile aynı ham JSON (üye sayısı değiştirilebilsin diye ayrıldı).
Map<String, dynamic> _formVerileriHam({int uyeSayisi = 3}) {
  return {
    'kortlar': [
      {'id': 1, 'adi': 'Kort 1', 'sira': 1},
    ],
    'antrenorler': [
      {'id': 1, 'ad_soyad': 'Ayşe Yılmaz', 'renk': '#2563EB', 'pasif': false},
    ],
    'urunler': [
      {'id': 1, 'adi': 'Grup Dersi', 'urun_tipi': 'PAKET', 'telafi_mi': false},
    ],
    'seviyeler': [
      {'kod': 'Kirmizi', 'ad': 'Kırmızı', 'renk': '#e74c3c'},
    ],
    'uyeler': [
      for (var i = 1; i <= uyeSayisi; i++)
        {
          'id': i,
          'ad_soyad': 'Üye $i Çok Uzun Soyadıyla Birlikte',
          'uye_no': 'U-$i',
          'telefon': '555000000$i',
          'pasif': false,
        }
    ],
    'iptal_sebepleri': <Map<String, dynamic>>[],
    'iptal_modlari': <Map<String, dynamic>>[],
    'secili_uye_idler': <int>[],
    'etkinlik': null,
  };
}
