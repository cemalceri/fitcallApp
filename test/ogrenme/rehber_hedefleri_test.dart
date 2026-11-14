// Telefonda bulunan üç rehber açığı:
// - Okuma adımından sonra gelen eylemin hedefi yoksa rehber başlamaz (ofis üye
//   aramasında boş listede «bir üyeye dokun» adımı takılıyordu).
// - Ofis programında "yeni ders" rehberi bütün ızgarayı değil bir boş saati
//   gösterir (dokunuş derse düşünce form açılmıyordu).
// - Üye takviminde aynı günde cevap bekleyen ve iptalli ders varsa gün iki
//   rehberin de hedefidir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/program/program_izgara.dart';
import 'package:fitcall/screens/1_common/takvim/hafta_gun_secici.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _bul = OgrenmeGorevi(
  id: 'test.bul',
  sayfa: OgrenmeSayfasi.ofisUyeler,
  baslik: 'Bir üyeyi nasıl bulurum?',
  kosulMetni: 'Listede üye olunca',
  adimlar: [
    OgrenmeAdimi(
      hedef: Secici.hedef('test.arama'),
      metin: 'İsimle ararsın.',
      bilgi: true,
    ),
    OgrenmeAdimi(
      hedef: Secici.hedef('test.satir'),
      metin: 'Listeden bir üyeye dokun.',
    ),
  ],
);

final _kortlar = [
  SecenekKort(id: 1, adi: 'Kort 1', sira: 1),
  SecenekKort(id: 2, adi: 'Kort 2', sira: 2),
];

ProgramDersi _ders(int kortId, int basSaat) => ProgramDersi(
      id: kortId * 100 + basSaat,
      baslangic: DateTime(2026, 7, 23, basSaat),
      bitis: DateTime(2026, 7, 23, basSaat + 1),
      tarih: '2026-07-23',
      saat: '$basSaat:00',
      bitisSaat: '${basSaat + 1}:00',
      kortId: kortId,
      antrenorRenk: Colors.blue,
      seviyeRenk: Colors.red,
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('okuma adımından sonraki eylemin hedefi yoksa rehber başlamaz',
      (tester) async {
    final satirVar = ValueNotifier(false);
    addTearDown(satirVar.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      builder: (context, child) => OgrenmeKatmani(child: child!),
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: satirVar,
          builder: (_, varMi, __) => Column(
            children: [
              const OgrenmeHedefi(
                id: 'test.arama',
                child: SizedBox(height: 48, width: 300),
              ),
              if (varMi)
                OgrenmeHedefi(
                  id: 'test.satir',
                  child: ListTile(title: const Text('Ayşe'), onTap: () {}),
                ),
            ],
          ),
        ),
      ),
    ));
    final bulucu = OgrenmeModu.ornek.bulucu!;

    expect(bulucu.baslatilabilir(_bul), isFalse);

    satirVar.value = true;
    await tester.pump();
    expect(bulucu.baslatilabilir(_bul), isTrue);
  });

  group('ofis programında boş saat hedefi', () {
    Future<void> kur(
      WidgetTester tester, {
      required List<ProgramDersi> dersler,
      void Function(SecenekKort, DateTime)? onBosSlotTap,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgramIzgara(
            kortlar: _kortlar,
            dersler: dersler,
            secilenGun: DateTime(2026, 7, 23),
            onDersTap: (_) {},
            onBosSlotTap: onBosSlotTap,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('derse değil boş saate konur, dokunuş yeni ders açar',
        (tester) async {
      SecenekKort? kort;
      DateTime? saat;
      // 07:00'de Kort 1 dolu: ilk boş saat aynı saatte Kort 2.
      await kur(
        tester,
        dersler: [_ders(1, 7)],
        onBosSlotTap: (k, t) {
          kort = k;
          saat = t;
        },
      );

      final hedef = find.byWidgetPredicate(
          (w) => w is OgrenmeHedefi && w.id == Hedef.programBosSaat);
      expect(hedef, findsOneWidget);

      await tester.tapAt(tester.getRect(hedef).topCenter + const Offset(0, 10));
      expect(kort?.id, 2);
      expect(saat, DateTime(2026, 7, 23, 7));
    });

    testWidgets('salt-okunur ızgarada (antrenör) boş saat hedefi yok',
        (tester) async {
      await kur(tester, dersler: [_ders(1, 7)]);
      expect(OgrenmeHedefi.kayitlilar(Hedef.programBosSaat), isEmpty);
    });
  });

  testWidgets('bir gün birden çok rehberin hedefi olabilir', (tester) async {
    final gun = DateTime(2026, 7, 23);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HaftaGunSecici(
          selectedDay: gun,
          focusedDay: gun,
          lessonCounts: {gun: 2},
          onDaySelected: (_) {},
          onPageChanged: (_) {},
          ogrenmeHedefleri: (g) => DateUtils.isSameDay(g, gun)
              ? const [Hedef.takvimDersliGun, Hedef.uyeIptalGunu]
              : const [],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(OgrenmeHedefi.kayitlilar(Hedef.takvimDersliGun), hasLength(1));
    expect(OgrenmeHedefi.kayitlilar(Hedef.uyeIptalGunu), hasLength(1));
  });
}
