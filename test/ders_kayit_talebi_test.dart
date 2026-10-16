// Ders kayıt talebi (2026-10-16): antrenör salt-okunur tüm programdan talep
// açar, ofis notu görüp haftalık programın formuyla kaydı oluşturur.
//
// Pinlenenler:
// - talep modeli ve programdaki `talepler` / `benim_antrenor_id` ayrıştırması;
// - formun açılış değerleri (kort, en yakın 30 dk, kendi dersinin süresi);
// - kayıt isteği talep_id'yi taşır, talepsiz istek taşımaz;
// - ızgara bekleyen talebi kesik çizgili blok olarak çizer, dokunuşu iletir,
//   kendi dersini vurgular; boş hücre dokunuşu bağlanmadıysa hiçbir şey olmaz;
// - antrenör formu açıklama olmadan göndermez;
// - ofis Ana Sayfa satırı talep listesini açar.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/program/program_izgara.dart';
import 'package:fitcall/screens/1_common/program/program_talep_blok.dart';
import 'package:fitcall/screens/3_antrenor/program/widgets/ders_kayit_talebi_sheet.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/widgets/ofis_ana_sayfa_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/ders_kayit_talepleri_gorunumu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/ofis_ornekleri.dart';

Widget _uygulama(Widget govde) => MaterialApp(
      locale: const Locale('tr', 'TR'),
      theme: FitcallTema.acik,
      home: Scaffold(body: govde),
    );

Map<String, dynamic> _ders({
  required int id,
  required int kortId,
  required int antrenorId,
  required String bas,
  required String bit,
  bool iptal = false,
}) =>
    {
      'id': id,
      'tarih': '2026-07-23',
      'kort_id': kortId,
      'kort_adi': 'Kort $kortId',
      'antrenor_id': antrenorId,
      'antrenor_adi': 'Antrenör $antrenorId',
      'antrenor_renk': '#2563EB',
      'baslangic_tarih_saat': '2026-07-23T$bas:00+03:00',
      'bitis_tarih_saat': '2026-07-23T$bit:00+03:00',
      'saat': bas,
      'bitis_saat': bit,
      'iptal_mi': iptal,
      'katilimci_sayisi': 2,
      'katilimcilar': [],
    };

HaftalikProgram _program({
  List<Map<String, dynamic>> dersler = const [],
  List<Map<String, dynamic>> talepler = const [],
  int? benim = 7,
}) =>
    HaftalikProgram.fromJson({
      'hafta_baslangic': '2026-07-20',
      'hafta_bitis': '2026-07-26',
      'bugun': '2026-07-23',
      'gunler': const [],
      'kortlar': [
        for (var i = 1; i <= 4; i++)
          {'id': i, 'adi': 'Kort $i', 'sira': i, 'max_etkinlik_sayisi': 4},
      ],
      'dersler': dersler,
      'talepler': talepler,
      'benim_antrenor_id': benim,
    });

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr', null);
  });

  group('Model', () {
    test('talep ve programdaki talepler ayrıştırılır', () {
      final p = _program(talepler: [ornekTalepJson(id: 9)]);
      expect(p.benimAntrenorId, 7);
      expect(p.talepler.single.id, 9);
      expect(p.talepler.single.saat, '17:30');
      expect(p.talepler.single.sureDakika, 60);
      expect(p.talepler.single.aciklama, startsWith('Kort 3 sulandı'));
      expect(p.gununTalepleri(DateTime(2026, 7, 23)), hasLength(1));
      expect(p.gununTalepleri(DateTime(2026, 7, 24)), isEmpty);
    });

    test('eski ofis yanıtı (talepsiz) da okunur', () {
      final p = HaftalikProgram.fromJson({
        'hafta_baslangic': '2026-07-20',
        'hafta_bitis': '2026-07-26',
        'kortlar': const [],
        'dersler': const [],
      });
      expect(p.talepler, isEmpty);
      expect(p.benimAntrenorId, isNull);
    });

    test('kayıt isteği talep_id taşır; talepsiz istek taşımaz', () {
      EtkinlikKaydetIstegi istek({int? talepId}) => EtkinlikKaydetIstegi(
            urunId: 1,
            kortId: 2,
            antrenorId: 3,
            baslangic: DateTime(2026, 7, 23, 17, 30),
            bitis: DateTime(2026, 7, 23, 18, 30),
            seviye: 'Kirmizi',
            uyeIdler: const [5],
            talepId: talepId,
          );
      expect(istek(talepId: 9).toJson()['talep_id'], 9);
      expect(istek().toJson().containsKey('talep_id'), isFalse);
    });
  });

  group('Formun açılış değerleri', () {
    final gun = DateTime(2026, 7, 23);

    test('bugün: o saatteki kendi dersinin kortu ve süresi, en yakın 30 dk',
        () {
      final p = _program(dersler: [
        _ders(id: 1, kortId: 3, antrenorId: 7, bas: '17:00', bit: '18:30'),
        _ders(id: 2, kortId: 1, antrenorId: 8, bas: '17:00', bit: '18:00'),
      ]);
      final v = TalepVarsayilani.hesapla(
        program: p,
        gun: gun,
        simdi: DateTime(2026, 7, 23, 17, 12),
      );
      expect(v.kortId, 3);
      expect(v.baslangic, DateTime(2026, 7, 23, 17, 0));
      expect(v.bitis, DateTime(2026, 7, 23, 18, 30));
    });

    test('bugün: biten ders atlanır, sıradaki ders alınır', () {
      final p = _program(dersler: [
        _ders(id: 1, kortId: 1, antrenorId: 7, bas: '10:00', bit: '11:00'),
        _ders(id: 2, kortId: 4, antrenorId: 7, bas: '18:00', bit: '19:00'),
      ]);
      final v = TalepVarsayilani.hesapla(
        program: p,
        gun: gun,
        simdi: DateTime(2026, 7, 23, 17, 20),
      );
      expect(v.kortId, 4);
      expect(v.baslangic, DateTime(2026, 7, 23, 17, 30));
    });

    test('başka gün: o günkü ilk dersinin saati; iptal ders sayılmaz', () {
      final p = _program(dersler: [
        _ders(
            id: 1,
            kortId: 1,
            antrenorId: 7,
            bas: '09:00',
            bit: '10:00',
            iptal: true),
        _ders(id: 2, kortId: 2, antrenorId: 7, bas: '15:00', bit: '16:30'),
      ]);
      final v = TalepVarsayilani.hesapla(
        program: p,
        gun: gun,
        simdi: DateTime(2026, 7, 21, 9, 0),
      );
      expect(v.kortId, 2);
      expect(v.baslangic, DateTime(2026, 7, 23, 15, 0));
      expect(v.bitis, DateTime(2026, 7, 23, 16, 30));
    });

    test('dersi yoksa ilk kort, 09:00, 60 dakika', () {
      final v = TalepVarsayilani.hesapla(
        program: _program(),
        gun: gun,
        simdi: DateTime(2026, 7, 21, 9, 0),
      );
      expect(v.kortId, 1);
      expect(v.baslangic, DateTime(2026, 7, 23, 9, 0));
      expect(v.bitis, DateTime(2026, 7, 23, 10, 0));
    });

    test('en yakın 30 dakika', () {
      DateTime t(int s, int d) => DateTime(2026, 7, 23, s, d);
      expect(TalepVarsayilani.yakin30Dakika(t(17, 14)), t(17, 0));
      expect(TalepVarsayilani.yakin30Dakika(t(17, 15)), t(17, 30));
      expect(TalepVarsayilani.yakin30Dakika(t(17, 50)), t(18, 0));
      expect(TalepVarsayilani.yakin30Dakika(t(23, 50)), t(23, 30));
    });
  });

  group('Izgara', () {
    testWidgets('bekleyen talep kesik çizgili blok; dokunuş iletilir',
        (tester) async {
      final p = _program(
        dersler: [
          _ders(id: 1, kortId: 2, antrenorId: 7, bas: '17:00', bit: '18:00'),
        ],
        talepler: [ornekTalepJson(id: 5, kortId: 2)],
      );
      DersKayitTalebi? dokunulan;
      await tester.pumpWidget(_uygulama(ProgramIzgara(
        kortlar: p.kortlar,
        dersler: p.gununDersleri(DateTime(2026, 7, 23)),
        talepler: p.gununTalepleri(DateTime(2026, 7, 23)),
        secilenGun: DateTime(2026, 7, 23),
        onDersTap: (_) {},
        onTalepTap: (t) => dokunulan = t,
        vurgulaAntrenorId: 7,
      )));

      expect(find.byType(ProgramTalepBlok), findsOneWidget);
      expect(find.text('Talep · 17:30'), findsOneWidget);
      // Kendi dersi kişi ikonuyla işaretli
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      await tester.ensureVisible(find.byType(ProgramTalepBlok));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProgramTalepBlok));
      expect(dokunulan?.id, 5);
    });

    testWidgets('boş hücre dokunuşu bağlanmadıysa ızgara salt-okunur',
        (tester) async {
      final p = _program();
      await tester.pumpWidget(_uygulama(ProgramIzgara(
        kortlar: p.kortlar,
        dersler: const [],
        secilenGun: DateTime(2026, 7, 23),
        onDersTap: (_) {},
      )));
      // Boş alan dokunma katmanı hiç kurulmaz
      expect(
        find.byWidgetPredicate(
            (w) => w is GestureDetector && w.onTapUp != null),
        findsNothing,
      );
    });
  });

  group('Antrenör formu', () {
    testWidgets('açıklama olmadan gönderilmez', (tester) async {
      final p = _program();
      await tester.pumpWidget(_uygulama(SingleChildScrollView(
        child: DersKayitTalebiSheet(
          kortlar: p.kortlar,
          varsayilan: TalepVarsayilani.hesapla(
            program: p,
            gun: DateTime(2026, 7, 23),
            simdi: DateTime(2026, 7, 21, 9),
          ),
        ),
      )));
      await tester.ensureVisible(find.text('Talebi gönder'));
      await tester.tap(find.text('Talebi gönder'));
      await tester.pump();
      expect(find.textContaining('Açıklama zorunludur'), findsOneWidget);
    });
  });

  group('Ofis', () {
    testWidgets('talep satırı notu ve üç eylemi gösterir', (tester) async {
      final olaylar = <String>[];
      await tester.pumpWidget(_uygulama(DersKayitTalepleriGorunumu(
        talepler: [ornekTalep()],
        yukleniyor: false,
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) => olaylar.add('kayit'),
        onReddet: (_) => olaylar.add('red'),
        onProgramdaGoster: (_) => olaylar.add('program'),
      )));
      expect(find.textContaining('Kort 3 sulandı'), findsOneWidget);
      await tester.tap(find.text('Programda göster'));
      await tester.tap(find.text('Reddet'));
      await tester.tap(find.text('Kayıt oluştur'));
      expect(olaylar, ['program', 'red', 'kayit']);
    });

    testWidgets('işlem sürerken eylemler kilitli', (tester) async {
      final olaylar = <String>[];
      await tester.pumpWidget(_uygulama(DersKayitTalepleriGorunumu(
        talepler: [ornekTalep()],
        yukleniyor: false,
        islenenTalepId: 1,
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) => olaylar.add('kayit'),
        onReddet: (_) => olaylar.add('red'),
        onProgramdaGoster: (_) => olaylar.add('program'),
      )));
      await tester.tap(find.text('Kayıt oluştur'));
      expect(olaylar, isEmpty);
    });

    testWidgets('boş liste boş durum gösterir', (tester) async {
      await tester.pumpWidget(_uygulama(DersKayitTalepleriGorunumu(
        talepler: const [],
        yukleniyor: false,
        onYenile: () async {},
        onYenidenDene: () {},
        onKayitOlustur: (_) {},
        onReddet: (_) {},
        onProgramdaGoster: (_) {},
      )));
      expect(find.text('Bekleyen talep yok'), findsOneWidget);
    });

    testWidgets('Ana Sayfa satırı talep sayısını gösterir, dokununca açar',
        (tester) async {
      var acildi = false;
      await tester.pumpWidget(_uygulama(OfisAnaSayfaGorunumu(
        ofisAdi: 'Ofis',
        profilDegistir: false,
        veri: ornekBekleyenIsler(),
        yukleniyor: false,
        hata: null,
        onYenile: () async {},
        onYenidenDene: () {},
        onOnay: () {},
        onPlanDisi: () {},
        onTeyit: () {},
        onBugununDersleri: () {},
        onDersKayitTalepleri: () => acildi = true,
        zil: const SizedBox(),
      )));
      final satir = find.text('Ders kayıt talepleri');
      await tester.ensureVisible(satir);
      await tester.tap(satir);
      expect(acildi, isTrue);
    });
  });
}
