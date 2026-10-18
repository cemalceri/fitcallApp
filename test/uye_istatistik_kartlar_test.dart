// Yönetici Üyeler: sayılı kartlar hızlı ön ayar (2026-10-18). Toplam · Aktif
// · Pasif · Borçlu · Yeni kartına dokununca filtre ve sıralama o ön ayara
// geçer; kart yalnız filtreler tam ön ayara eşitken vurgulu.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
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

UyeListeItem _uye(int no, {Map<String, dynamic> ek = const {}}) =>
    UyeListeItem.fromJson({
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
      ...ek,
    });

Widget _sar(Widget w) => MaterialApp(
      theme: FitcallTema.acik,
      home: Scaffold(body: w),
    );

Widget _gorunum({
  List<UyeListeItem>? uyeler,
  UyeFiltreleri filtreler = UyeFiltreleri.bos,
  UyeSiralama siralama = UyeSiralama.varsayilan,
  UyeOnAyari? seciliOnAyar = UyeOnAyari.tumu,
  UyeFiltreOzeti? ozet,
  ValueChanged<UyeOnAyari>? onOnAyar,
  ValueChanged<UyeFiltreleri>? onFiltreDegistir,
  VoidCallback? onFiltrele,
  VoidCallback? onSirala,
}) =>
    _sar(UyelerGorunumu(
      istatistik: _istatistik(),
      uyeler: uyeler ?? [_uye(1), _uye(2)],
      toplam: uyeler?.length ?? 2,
      yukleniyor: false,
      hata: null,
      filtreler: filtreler,
      siralama: siralama,
      seciliOnAyar: seciliOnAyar,
      filtreOzeti: ozet,
      aramaDenetleyicisi: TextEditingController(),
      onOnAyar: onOnAyar ?? (_) {},
      onFiltrele: onFiltrele ?? () {},
      onSirala: onSirala ?? () {},
      onFiltreDegistir: onFiltreDegistir ?? (_) {},
      onYenile: () async {},
      onYenidenDene: () {},
      onUyeSec: (_) {},
      onAra: (_) {},
      onWhatsapp: (_) {},
    ));

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('beş kart sayısıyla; dokunulan kartın ön ayarı seçilir',
      (tester) async {
    final secilenler = <UyeOnAyari>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: UyeOnAyari.tumu,
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
    expect(secilenler, [
      UyeOnAyari.borclu,
      UyeOnAyari.yeni,
      UyeOnAyari.pasif,
      UyeOnAyari.aktif,
    ]);
  });

  testWidgets('seçili karta dokunmak listeyi yeniden yüklemez', (tester) async {
    final secilenler = <UyeOnAyari>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: UyeOnAyari.borclu,
      onSec: secilenler.add,
    )));

    await tester.tap(find.text('Borçlu'));
    expect(secilenler, isEmpty);
    await tester.tap(find.text('Toplam'));
    expect(secilenler, [UyeOnAyari.tumu]);
  });

  testWidgets('filtre hiçbir ön ayara eşit değilse hiçbir kart seçili değil',
      (tester) async {
    final semantik = tester.ensureSemantics();
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: null,
      onSec: (_) {},
    )));
    for (final etiket in [
      'Toplam 184 üye',
      'Aktif 161 üye',
      'Pasif 23 üye',
      'Borçlu 12 üye',
      'Yeni 7 üye',
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(etiket)),
        isSemantics(isButton: true, isSelected: false, hasTapAction: true),
        reason: etiket,
      );
    }
    semantik.dispose();
  });

  testWidgets('istatistik gelmeden "–" yazılır, kartlar yine seçilir',
      (tester) async {
    final secilenler = <UyeOnAyari>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: null,
      secili: UyeOnAyari.tumu,
      onSec: secilenler.add,
    )));

    expect(find.text('–'), findsNWidgets(5));
    await tester.tap(find.text('Yeni'));
    expect(secilenler, [UyeOnAyari.yeni]);
  });

  testWidgets('borclu_uye göndermeyen eski sunucuda Borçlu "–", 0 değil',
      (tester) async {
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(borcluVar: false),
      secili: UyeOnAyari.tumu,
      onSec: (_) {},
    )));

    expect(find.text('–'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('ekran okuyucu kartı okur, seçili durumu bilir ve seçebilir',
      (tester) async {
    final semantik = tester.ensureSemantics();
    final secilenler = <UyeOnAyari>[];
    await tester.pumpWidget(_sar(UyeIstatistikKartlar(
      data: _istatistik(),
      secili: UyeOnAyari.tumu,
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
    expect(secilenler, [UyeOnAyari.borclu]);
    semantik.dispose();
  });

  testWidgets('liste görünümü: kart ön ayarı, Filtrele ve Sırala düğmeleri',
      (tester) async {
    final secilenler = <UyeOnAyari>[];
    var filtreAcildi = 0, siralamaAcildi = 0;
    await tester.pumpWidget(_gorunum(
      filtreler: const UyeFiltreleri(borc: BorcDurumFiltresi.borclu),
      siralama: const UyeSiralama(UyeSiralamaAlani.borc, SiralamaYonu.azalan),
      seciliOnAyar: UyeOnAyari.borclu,
      onOnAyar: secilenler.add,
      onFiltrele: () => filtreAcildi++,
      onSirala: () => siralamaAcildi++,
    ));

    expect(find.text('Filtrele (1)'), findsOneWidget);
    expect(find.text('Sırala: En borçlu'), findsOneWidget);
    // Ada göre değilken harf grubu yok, düz liste.
    expect(find.text('D'), findsNothing);
    expect(find.text('Deniz Yılmaz 1'), findsOneWidget);

    await tester.tap(find.text('Filtrele (1)'));
    await tester.tap(find.text('Sırala: En borçlu'));
    await tester.tap(find.text('Toplam'));
    expect(filtreAcildi, 1);
    expect(siralamaAcildi, 1);
    expect(secilenler, [UyeOnAyari.tumu]);
  });

  testWidgets('ada göre sıralıyken harf grupları', (tester) async {
    await tester.pumpWidget(_gorunum());
    expect(find.text('D'), findsOneWidget);
    expect(find.text('Filtrele'), findsOneWidget);
    expect(find.text('Sırala: A→Z'), findsOneWidget);
  });

  testWidgets('etkin filtre çipleri: × tek filtreyi, "Tümünü temizle" hepsini kaldırır',
      (tester) async {
    final degisenler = <UyeFiltreleri>[];
    const filtreler = UyeFiltreleri(
      durum: UyeDurumFiltresi.aktif,
      kesinlesti: false,
    );
    await tester.pumpWidget(_gorunum(
      filtreler: filtreler,
      seciliOnAyar: null,
      ozet: const UyeFiltreOzeti(uyeSayisi: 37, toplamBorc: 48200),
      onFiltreDegistir: degisenler.add,
    ));

    expect(find.text('37 üye · ₺48.200 borç'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Aktif'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Kesinleşmedi'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.widgetWithText(InputChip, 'Kesinleşmedi'),
      matching: find.byTooltip('Kaldır'),
    ));
    await tester.tap(find.text('Tümünü temizle'));
    expect(degisenler, [
      const UyeFiltreleri(durum: UyeDurumFiltresi.aktif),
      UyeFiltreleri.bos,
    ]);
  });

  testWidgets('satır: kesin rozeti ve tarih sıralamasında o tarih',
      (tester) async {
    await tester.pumpWidget(_gorunum(
      siralama:
          const UyeSiralama(UyeSiralamaAlani.sonKontrol, SiralamaYonu.artan),
      uyeler: [
        _uye(1),
        _uye(2, ek: {
          'borc_kesinlesti': true,
          'son_kontrol_tarihi': '2026-10-12',
          'aktif_mi': false,
        }),
      ],
    ));

    expect(find.text('Hiç kontrol edilmedi'), findsOneWidget);
    expect(find.text('Son kontrol: 12.10.2026'), findsOneWidget);
    expect(find.text('Kesin'), findsOneWidget);
    expect(find.text('Pasif'), findsWidgets); // kart + rozet
  });

  testWidgets('liste boşken filtre varsa "Filtreleri temizle", kartlar seçilir',
      (tester) async {
    final secilenler = <UyeOnAyari>[];
    final degisenler = <UyeFiltreleri>[];
    await tester.pumpWidget(_gorunum(
      uyeler: const [],
      filtreler: const UyeFiltreleri(borc: BorcDurumFiltresi.borclu),
      seciliOnAyar: UyeOnAyari.borclu,
      onOnAyar: secilenler.add,
      onFiltreDegistir: degisenler.add,
    ));

    expect(find.text('Bu filtrelere uyan üye bulunmuyor.'), findsOneWidget);
    await tester.tap(find.text('Filtreleri temizle'));
    expect(degisenler, [UyeFiltreleri.bos]);
    await tester.tap(find.text('Toplam'));
    expect(secilenler, [UyeOnAyari.tumu]);
  });
}
