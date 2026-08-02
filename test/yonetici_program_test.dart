// Yönetici haftalık program: model parse + ızgara yerleşimi/taşma testleri.
//
// Taşma testleri özellikle önemli: ızgara dar telefon ekranında çok sayıda kort
// ve uzun isimlerle çalışıyor. Flutter test ortamında RenderFlex overflow bir
// istisna olarak raporlanır; aşağıdaki testler o istisnanın oluşmadığını doğrular.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/program_gun_seridi.dart';
import 'package:fitcall/screens/7_yonetici/program/widgets/program_izgara.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _dersJson({
  required int id,
  required int kortId,
  String tarih = '2026-07-23',
  String bas = '10:00',
  String bit = '11:00',
  bool iptal = false,
  List<String> katilimcilar = const ['Ali Veli'],
}) {
  return {
    'id': id,
    'tarih': tarih,
    'kort_id': kortId,
    'kort_adi': 'Kort $kortId',
    'antrenor_id': 1,
    'antrenor_adi': 'Ayşe Yılmaz',
    'antrenor_renk': '#2563EB',
    'urun_id': 1,
    'urun_adi': 'Grup Dersi',
    'seviye': 'Kirmizi',
    'seviye_renk': '#e74c3c',
    'baslangic_tarih_saat': '${tarih}T$bas:00+03:00',
    'bitis_tarih_saat': '${tarih}T$bit:00+03:00',
    'saat': bas,
    'bitis_saat': bit,
    'iptal_mi': iptal,
    'sabit_plan_mi': false,
    'durum': iptal ? 'iptal' : 'planli',
    'katilimci_sayisi': katilimcilar.length,
    'katilimcilar': [
      for (var i = 0; i < katilimcilar.length; i++)
        {'id': i + 1, 'ad_soyad': katilimcilar[i]}
    ],
    'aciklama': null,
  };
}

Map<String, dynamic> _programJson({
  int kortSayisi = 3,
  List<Map<String, dynamic>>? dersler,
}) {
  return {
    'hafta_baslangic': '2026-07-20',
    'hafta_bitis': '2026-07-26',
    'bugun': '2026-07-23',
    'gunler': [
      for (var i = 0; i < 7; i++)
        {
          'tarih': '2026-07-${(20 + i).toString().padLeft(2, '0')}',
          'gun_adi': 'Gün $i',
          'gun_kisa': 'G$i',
          'ders_sayisi': i,
        }
    ],
    'kortlar': [
      for (var i = 1; i <= kortSayisi; i++)
        {'id': i, 'adi': 'Kort $i', 'sira': i, 'max_etkinlik_sayisi': 3}
    ],
    'dersler': dersler ?? [_dersJson(id: 1, kortId: 1)],
  };
}

Widget _izgarayiSar(HaftalikProgram program, {Size boyut = const Size(360, 640)}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: boyut),
      child: Scaffold(
        body: SizedBox(
          width: boyut.width,
          height: boyut.height,
          child: ProgramIzgara(
            kortlar: program.kortlar,
            dersler: program.gununDersleri(DateTime(2026, 7, 23)),
            secilenGun: DateTime(2026, 7, 23),
            onDersTap: (_) {},
            onBosSlotTap: (_, __) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HaftalikProgram.fromJson', () {
    test('temel alanları parse eder', () {
      final p = HaftalikProgram.fromJson(_programJson());

      expect(p.haftaBaslangic, DateTime(2026, 7, 20));
      expect(p.haftaBitis, DateTime(2026, 7, 26));
      expect(p.gunler.length, 7);
      expect(p.kortlar.length, 3);
      expect(p.dersler.length, 1);
    });

    test('ders saati kulüp duvar saati olarak okunur', () {
      // Sunucu +03:00 gönderiyor; ham DateTime.parse 07:00 verirdi.
      // Beklenti CİHAZIN saat diliminden bağımsız yazılmıştır: eskiden
      // millisecondsSinceEpoch ile karşılaştırılıyordu, o da yalnızca +03:00
      // makinede geçiyordu (bkz. 2026-08-02 saat kayması düzeltmesi).
      final p = HaftalikProgram.fromJson(_programJson());
      final ders = p.dersler.first;

      expect(ders.saat, '10:00');
      expect(ders.baslangic.isUtc, isFalse);
      expect(ders.baslangic.hour, 10);
      expect(ders.baslangic.minute, 0);
      expect(ders.baslangic.day, 23);
      // Gerçek an (telefon takvimi/alarm için) her cihazda aynı olmalı.
      expect(
        kulupAnI(ders.baslangic).millisecondsSinceEpoch,
        DateTime.parse('2026-07-23T10:00:00+03:00').millisecondsSinceEpoch,
      );
    });

    test('süre dakikası doğru hesaplanır', () {
      final p = HaftalikProgram.fromJson(_programJson(
        dersler: [_dersJson(id: 1, kortId: 1, bas: '10:00', bit: '11:30')],
      ));
      expect(p.dersler.first.sureDakika, 90);
    });

    test('gununDersleri yalnızca o günü verir ve sıralar', () {
      final p = HaftalikProgram.fromJson(_programJson(dersler: [
        _dersJson(id: 1, kortId: 1, bas: '14:00', bit: '15:00'),
        _dersJson(id: 2, kortId: 1, bas: '09:00', bit: '10:00'),
        _dersJson(id: 3, kortId: 1, tarih: '2026-07-24'),
      ]));

      final gun = p.gununDersleri(DateTime(2026, 7, 23));
      expect(gun.map((d) => d.id), [2, 1]);
    });

    test('renk kodları Color olarak parse edilir', () {
      final p = HaftalikProgram.fromJson(_programJson());
      expect(p.dersler.first.antrenorRenk, const Color(0xFF2563EB));
    });

    test('boş/eksik alanlarda güvenli varsayılanlar', () {
      final p = HaftalikProgram.fromJson({});
      expect(p.gunler, isEmpty);
      expect(p.kortlar, isEmpty);
      expect(p.dersler, isEmpty);
    });
  });

  group('SilmeEtkisi uyarı satırları', () {
    test('yalnızca dolu kalemler listelenir ve telafi öne çıkar', () {
      final e = SilmeEtkisi.fromJson({
        'katilimci_sayisi': 2,
        'paket_kullanimi': 0,
        'telafi_kaybolacak': 1,
        'telafi_serbest_kalacak': 0,
        'teyit_sayisi': 0,
        'onay_sayisi': 0,
        'degerlendirme_sayisi': 0,
        'ders': {'tarih': '23.07.2026', 'saat': '10:00', 'kort_adi': 'Kort 1'},
      });

      final satirlar = e.uyariSatirlari;
      expect(satirlar.length, 2);
      expect(satirlar.first, contains('telafi hakkı'));
      expect(satirlar.any((s) => s.contains('paket')), isFalse);
    });

    test('bağlı kayıt yoksa liste boş', () {
      final e = SilmeEtkisi.fromJson({'ders': {}});
      expect(e.uyariSatirlari, isEmpty);
    });
  });

  group('SecenekUye arama', () {
    final uye = SecenekUye(
      id: 1,
      adSoyad: 'Ahmet Yılmaz',
      uyeNo: 'U-1234',
      telefon: '5551112233',
    );

    test('ad, üye no ve telefon üzerinden eşleşir', () {
      expect(uye.eslesiyorMu('ahmet'), isTrue);
      expect(uye.eslesiyorMu('1234'), isTrue);
      expect(uye.eslesiyorMu('5551'), isTrue);
      expect(uye.eslesiyorMu('mehmet'), isFalse);
    });

    test('boş sorgu herkesi geçirir', () {
      expect(uye.eslesiyorMu(''), isTrue);
      expect(uye.eslesiyorMu('   '), isTrue);
    });
  });

  group('ProgramIzgara yerleşimi', () {
    testWidgets('dar ekranda çok kortla taşma vermez', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final program = HaftalikProgram.fromJson(_programJson(
        kortSayisi: 8,
        dersler: [
          for (var k = 1; k <= 8; k++) _dersJson(id: k, kortId: k),
        ],
      ));

      await tester.pumpWidget(_izgarayiSar(program));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('uzun katılımcı adları bloğu taşırmaz', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final program = HaftalikProgram.fromJson(_programJson(
        dersler: [
          _dersJson(
            id: 1,
            kortId: 1,
            katilimcilar: List.generate(
                12, (i) => 'Çok Uzun İsimli Katılımcı Numara $i'),
          ),
        ],
      ));

      await tester.pumpWidget(_izgarayiSar(program));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('çok kısa ders bloğu taşma vermez', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final program = HaftalikProgram.fromJson(_programJson(
        dersler: [_dersJson(id: 1, kortId: 1, bas: '10:00', bit: '10:30')],
      ));

      await tester.pumpWidget(_izgarayiSar(program));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('aynı kortta çakışan dersler yan yana yerleşir', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final program = HaftalikProgram.fromJson(_programJson(
        kortSayisi: 1,
        dersler: [
          _dersJson(id: 1, kortId: 1, bas: '10:00', bit: '11:00'),
          _dersJson(id: 2, kortId: 1, bas: '10:00', bit: '11:00'),
          _dersJson(id: 3, kortId: 1, bas: '10:30', bit: '11:30'),
        ],
      ));

      await tester.pumpWidget(_izgarayiSar(program));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Üç blok da çizilmeli (üst üste binip kaybolmamalı)
      expect(find.textContaining('10:00 ·'), findsNWidgets(2));
      expect(find.textContaining('10:30 ·'), findsOneWidget);
    });

    testWidgets('derse dokunma geri çağrımı tetikler', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      ProgramDersi? dokunulan;
      final program = HaftalikProgram.fromJson(_programJson());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgramIzgara(
            kortlar: program.kortlar,
            dersler: program.dersler,
            secilenGun: DateTime(2026, 7, 23),
            onDersTap: (d) => dokunulan = d,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('10:00 ·').first);
      await tester.pumpAndSettle();

      expect(dokunulan?.id, 1);
    });

    testWidgets('boş slota dokunma kort ve saati verir', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SecenekKort? secilenKort;
      DateTime? secilenSaat;
      final program = HaftalikProgram.fromJson(
        _programJson(kortSayisi: 1, dersler: []),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgramIzgara(
            kortlar: program.kortlar,
            dersler: const [],
            secilenGun: DateTime(2026, 7, 23),
            onDersTap: (_) {},
            onBosSlotTap: (k, t) {
              secilenKort = k;
              secilenSaat = t;
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Izgaranın en üst hücresi = 07:00 (varsayılan başlangıç saati)
      await tester.tapAt(const Offset(100, 60));
      await tester.pumpAndSettle();

      expect(secilenKort?.id, 1);
      expect(secilenSaat, isNotNull);
      expect(secilenSaat!.minute % 30, 0);
    });

    testWidgets('saat etiketleri görünür', (tester) async {
      // Saat kolonu yalnızca Positioned çocuklardan oluşan bir Stack; yükseklik
      // açıkça verilmezse sıfıra çöküyor ve etiketler hiç çizilmiyordu.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final program = HaftalikProgram.fromJson(_programJson());
      await tester.pumpWidget(_izgarayiSar(program, boyut: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ProgramGunSeridi', () {
    Widget sar(HaftalikProgram program, {double yaziOlcegi = 1.0, Size boyut = const Size(360, 640)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: boyut,
            textScaler: TextScaler.linear(yaziOlcegi),
          ),
          child: Scaffold(
            body: SizedBox(
              width: boyut.width,
              child: ProgramGunSeridi(
                gunler: program.gunler,
                seciliTarih: '2026-07-23',
                bugunTarih: '2026-07-23',
                onGunSec: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('normal yazı ölçeğinde taşma vermez', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(sar(HaftalikProgram.fromJson(_programJson())));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('büyük yazı ölçeğinde de taşma vermez', (tester) async {
      // Erişilebilirlik ayarıyla yazı büyüyünce hücre içeriği sığmayabilir;
      // FittedBox küçültmeli, taşma hatası ATMAMALI.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        sar(HaftalikProgram.fromJson(_programJson()), yaziOlcegi: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('gün seçimi geri çağrımı tetikler', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      DateTime? secilen;
      final program = HaftalikProgram.fromJson(_programJson());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgramGunSeridi(
            gunler: program.gunler,
            seciliTarih: '2026-07-20',
            bugunTarih: '2026-07-23',
            onGunSec: (g) => secilen = g,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();

      expect(secilen?.day, 22);
    });
  });

  group('ProgramIzgara boş durum', () {
    testWidgets('kort yoksa bilgilendirme gösterir', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProgramIzgara(
            kortlar: const [],
            dersler: const [],
            secilenGun: DateTime(2026, 7, 23),
            onDersTap: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tanımlı kort bulunamadı.'), findsOneWidget);
    });
  });
}
