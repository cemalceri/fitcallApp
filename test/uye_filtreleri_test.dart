// Yönetici Üyeler: birlikte çalışan filtre + sıralama (MOBIL_GELISTIRMELER
// #12, 2026-10-18). İstek sözleşmesi (`filtreler`, `siralama`, `yon`)
// backend'deki api/yonetici/metots.py ile aynı olmalı; ön ayar eşleşmesi kart
// vurgusunu, çipler "×" davranışını belirler.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_filtre_sheet.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_siralama_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _bugun = DateTime(2026, 10, 18);

Widget _sar(Widget w) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: w),
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('UyeFiltreleri.toJson', () {
    test('boş filtre boş nesne gönderir', () {
      expect(UyeFiltreleri.bos.toJson(), isEmpty);
      expect(UyeFiltreleri.bos.bosMu, isTrue);
      expect(UyeFiltreleri.bos.aktifSayisi, 0);
    });

    test('her alan sunucunun anahtarı ve biçimiyle', () {
      final f = UyeFiltreleri(
        durum: UyeDurumFiltresi.pasif,
        borc: BorcDurumFiltresi.fazlaOdemis,
        borcMin: 500,
        borcMax: 2000,
        kesinlesti: false,
        kontrolSonra: DateTime(2026, 9, 1),
        kontrolOnce: DateTime(2026, 9, 30),
        odemeSonra: DateTime(2026, 1, 5),
        odemeOnce: DateTime(2026, 2, 5),
        dersOnce: DateTime(2026, 8, 1),
        kayitSonra: DateTime(2026, 10, 1),
      );
      expect(f.toJson(), {
        'durum': 'pasif',
        'borc': 'fazla_odemis',
        'borc_min': 500,
        'borc_max': 2000,
        'kesinlesti': false,
        'kontrol_sonra': '2026-09-01',
        'kontrol_once': '2026-09-30',
        'odeme_sonra': '2026-01-05',
        'odeme_once': '2026-02-05',
        'ders_once': '2026-08-01',
        'kayit_sonra': '2026-10-01',
      });
    });

    test('"hiç" seçenekleri yalnız true iken gider', () {
      expect(
        const UyeFiltreleri(kontrolYok: true, odemeYok: true).toJson(),
        {'kontrol_yok': true, 'odeme_yok': true},
      );
    });
  });

  group('copyWith ve çipler', () {
    test('verilmeyen alan korunur, açık null alanı temizler', () {
      const f = UyeFiltreleri(
          durum: UyeDurumFiltresi.aktif, borc: BorcDurumFiltresi.borclu);
      expect(f.copyWith(kesinlesti: true).durum, UyeDurumFiltresi.aktif);
      expect(f.copyWith(durum: null),
          const UyeFiltreleri(borc: BorcDurumFiltresi.borclu));
    });

    test('her çip yalnız kendi filtresini kaldırır', () {
      final f = UyeFiltreleri(
        durum: UyeDurumFiltresi.aktif,
        borcMin: 500,
        kontrolYok: true,
        odemeSonra: DateTime(2026, 9, 1),
        dersOnce: DateTime(2026, 8, 1),
      );
      final cipler = {for (final c in f.cipler) c.etiket: c.kaldirilmis};
      expect(cipler.keys, [
        'Aktif',
        'Borç ≥ 500 ₺',
        'Hiç kontrol edilmedi',
        'Ödeme: 01.09.2026 ve sonrası',
        '01.08.2026 beri derse gelmeyen',
      ]);
      expect(f.aktifSayisi, 5);
      expect(cipler['Aktif']!.durum, isNull);
      expect(cipler['Aktif']!.borcMin, 500);
      expect(cipler['Borç ≥ 500 ₺']!.borcMin, isNull);
      expect(cipler['Hiç kontrol edilmedi']!.kontrolYok, isFalse);
      expect(cipler['Ödeme: 01.09.2026 ve sonrası']!.odemeSonra, isNull);
    });

    test('tutar ve tarih aralığı tek çip', () {
      final f = UyeFiltreleri(
        borcMin: 1000,
        borcMax: 25000,
        kontrolSonra: DateTime(2026, 9, 1),
        kontrolOnce: DateTime(2026, 9, 30),
      );
      expect(f.cipler.map((c) => c.etiket), [
        'Borç 1.000–25.000 ₺',
        'Kontrol: 01.09.2026–30.09.2026',
      ]);
      expect(f.cipler.last.kaldirilmis,
          const UyeFiltreleri(borcMin: 1000, borcMax: 25000));
    });
  });

  group('ön ayarlar', () {
    test('her kart kendi filtresine eşleşir', () {
      for (final o in UyeOnAyari.values) {
        expect(eslesenOnAyar(o.filtreler(_bugun), _bugun), o);
      }
    });

    test('Borçlu = borçlu + en borçlu önce; Yeni = bu ayın ilk günü + yeni kayıt',
        () {
      expect(UyeOnAyari.borclu.filtreler(_bugun).toJson(), {'borc': 'borclu'});
      expect(UyeOnAyari.borclu.siralama.apiAlani, 'borc');
      expect(UyeOnAyari.borclu.siralama.apiYonu, 'azalan');
      expect(UyeOnAyari.yeni.filtreler(_bugun).toJson(),
          {'kayit_sonra': '2026-10-01'});
      expect(UyeOnAyari.yeni.siralama.apiAlani, 'uye_no');
      expect(UyeOnAyari.yeni.siralama.apiYonu, 'azalan');
      expect(UyeOnAyari.tumu.siralama, UyeSiralama.varsayilan);
    });

    test('ek bir filtre vurguyu kaldırır', () {
      final f = UyeOnAyari.borclu
          .filtreler(_bugun)
          .copyWith(kesinlesti: true);
      expect(eslesenOnAyar(f, _bugun), isNull);
    });
  });

  group('UyeSiralama', () {
    test('12 seçenek, hepsi farklı; varsayılan ad A→Z', () {
      expect(UyeSiralama.secenekler.length, 12);
      expect(UyeSiralama.secenekler.toSet().length, 12);
      expect(UyeSiralama.varsayilan.apiAlani, 'ad');
      expect(UyeSiralama.varsayilan.apiYonu, 'artan');
      expect(
        UyeSiralama.secenekler.map((s) => s.apiAlani).toSet(),
        {'ad', 'uye_no', 'borc', 'son_kontrol', 'son_odeme', 'son_ders'},
      );
    });
  });

  group('yanıt modelleri', () {
    test('liste satırı yeni alanları okur; eski sunucuda varsayılan', () {
      final yeni = UyeListeItem.fromJson({
        'id': 1,
        'borc_kesinlesti': true,
        'son_kontrol_tarihi': '2026-10-12',
        'son_odeme_tarihi': '2026-09-01',
      });
      expect(yeni.borcKesinlesti, isTrue);
      expect(yeni.sonKontrolTarihi, DateTime(2026, 10, 12));
      expect(yeni.sonOdemeTarihi, DateTime(2026, 9, 1));

      final eski = UyeListeItem.fromJson({'id': 1});
      expect(eski.borcKesinlesti, isFalse);
      expect(eski.sonKontrolTarihi, isNull);
      expect(eski.sonOdemeTarihi, isNull);
    });

    test('filtre özeti yalnız ilk sayfada; sayı ya da metin tutar', () {
      final ilk = UyelerData.fromJson({
        'uyeler': [],
        'filtre_ozeti': {'uye_sayisi': 37, 'toplam_borc': 48200.5},
      });
      expect(ilk.filtreOzeti!.uyeSayisi, 37);
      expect(ilk.filtreOzeti!.toplamBorc, 48200.5);
      expect(
        UyeFiltreOzeti.fromJson({'uye_sayisi': 1, 'toplam_borc': '750.00'})
            .toplamBorc,
        750,
      );
      expect(UyelerData.fromJson({'uyeler': []}).filtreOzeti, isNull);
    });

    test('detay: borç kontrol satırı', () {
      UyeDetayData detay(Map<String, dynamic> ek) =>
          UyeDetayData.fromJson(
              {'profil': <String, dynamic>{}, 'bakiye': '-750', ...ek});

      expect(detay({}).borcKontrolMetni, isNull); // eski sunucu
      expect(
        detay({'borc_kesinlesti': true, 'son_kontrol_tarihi': '2026-10-12'})
            .borcKontrolMetni,
        'Borç kesinleşti · son kontrol 12.10.2026',
      );
      expect(
        detay({'borc_kesinlesti': true, 'son_kontrol_tarihi': null})
            .borcKontrolMetni,
        'Borç kesinleşti',
      );
      expect(
        detay({'borc_kesinlesti': false, 'son_kontrol_tarihi': '2026-10-12'})
            .borcKontrolMetni,
        'Kesinleşmedi · son kontrol 12.10.2026',
      );
      expect(
        detay({'borc_kesinlesti': false, 'son_kontrol_tarihi': null})
            .borcKontrolMetni,
        'Borç henüz kontrol edilmedi',
      );
    });
  });

  group('filtre sayfası', () {
    testWidgets('canlı sayı, seçim ve Uygula seçilen filtreyi döndürür',
        (tester) async {
      final sorulanlar = <UyeFiltreleri>[];
      UyeFiltreleri? sonuc;
      await tester.pumpWidget(_sar(Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            sonuc = await UyeFiltreSheet.ac(
              context,
              baslangic: UyeFiltreleri.bos,
              sayac: (f) async {
                sorulanlar.add(f);
                return f.borc == null ? 1240 : 124;
              },
            );
          },
          child: const Text('aç'),
        ),
      )));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('1.240 üyeyi göster'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Borçlu'));
      await tester.pump();
      expect(find.text('Uygula'), findsOneWidget); // sayılıyor
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('124 üyeyi göster'), findsOneWidget);
      expect(sorulanlar.last,
          const UyeFiltreleri(borc: BorcDurumFiltresi.borclu));

      await tester.tap(find.text('124 üyeyi göster'));
      await tester.pumpAndSettle();
      expect(sonuc, const UyeFiltreleri(borc: BorcDurumFiltresi.borclu));
    });

    testWidgets('ters tutar aralığında Uygula kapalı, hata görünür',
        (tester) async {
      await tester.pumpWidget(_sar(UyeFiltreSheet(
        baslangic: const UyeFiltreleri(borcMin: 5000, borcMax: 100),
        sayac: (_) async => 0,
        bugun: _bugun,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Borç: "en az" tutarı "en çok"tan büyük olamaz.'),
          findsOneWidget);
      final dugme = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(dugme.onPressed, isNull);
    });

    testWidgets('son kontrol: "Hiç" seçilince aralık temizlenir, hızlı çip tarih yazar',
        (tester) async {
      final sorulanlar = <UyeFiltreleri>[];
      await tester.pumpWidget(_sar(UyeFiltreSheet(
        baslangic: UyeFiltreleri(kontrolSonra: DateTime(2026, 1, 1)),
        sayac: (f) async {
          sorulanlar.add(f);
          return 3;
        },
        bugun: _bugun,
      )));
      await tester.pumpAndSettle();
      // Aralık modunda açılır: hızlı çipler görünür.
      expect(find.text('30 günden eski'), findsWidgets);

      Future<void> dokun(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
      }

      await dokun(find.widgetWithText(ChoiceChip, 'Hiç kontrol edilmedi'));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(sorulanlar.last, const UyeFiltreleri(kontrolYok: true));

      await dokun(find.widgetWithText(ChoiceChip, 'Tarihe göre').first);
      await tester.pumpAndSettle();
      await dokun(find.widgetWithText(ChoiceChip, 'Son 30 gün').first);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(sorulanlar.last,
          UyeFiltreleri(kontrolSonra: _bugun.subtract(const Duration(days: 30))));
    });

    testWidgets('Temizle hepsini sıfırlar', (tester) async {
      final sorulanlar = <UyeFiltreleri>[];
      await tester.pumpWidget(_sar(UyeFiltreSheet(
        baslangic: const UyeFiltreleri(
          durum: UyeDurumFiltresi.aktif,
          borcMin: 100,
        ),
        sayac: (f) async {
          sorulanlar.add(f);
          return 5;
        },
        bugun: _bugun,
      )));
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      await tester.tap(find.text('Temizle'));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(sorulanlar.last, UyeFiltreleri.bos);
      expect(find.text('100'), findsNothing);
    });
  });

  testWidgets('sıralama sayfası seçileni işaretler, dokunulanı döndürür',
      (tester) async {
    UyeSiralama? sonuc;
    await tester.pumpWidget(_sar(Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          sonuc = await UyeSiralamaSheet.ac(context,
              secili: UyeSiralama.varsayilan);
        },
        child: const Text('aç'),
      ),
    )));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    final secili = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Ad (A→Z)'));
    expect(secili.selected, isTrue);

    await tester.tap(find.text('Son ödeme (en eski önce)'));
    await tester.pumpAndSettle();
    expect(sonuc,
        const UyeSiralama(UyeSiralamaAlani.sonOdeme, SiralamaYonu.artan));
  });
}
