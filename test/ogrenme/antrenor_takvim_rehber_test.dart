// "?" rehberinin sürücü testi: antrenör takviminin gerçek sayfası
// (AntrenorTakvimPage: gün şeridi, zaman çizelgesi, ders bloğu, yoklama ve
// ders detayı alt sayfaları) sahte API ile pompalanır; takvim rehberleri
// dersin farklı durumlarında (yoklama girilmemiş / girilmiş / yapılmadı /
// kilitli, gelecek ders) adım adım sonuna kadar yürünür. Adım numarası hiç
// geri gitmemeli, rehber sırasında ağa yazma isteği çıkmamalı.
//
// Dersler geçen haftaya (hepsi bitmiş) ya da gelecek haftaya (hepsi
// başlamamış) konur; test hangi gün ve saatte çalışırsa çalışsın aynı sonuç.

import 'dart:convert';

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_katmani.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/takvim/hafta_gun_secici.dart';
import 'package:fitcall/screens/3_antrenor/takvim/antrenor_takvim_page.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/future_lesson_detail_dialog.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:fitcall/services/ogrenme/uc_siniflari.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../tool/magaza_gorselleri/demo_veri.dart' as demo;
import '../../tool/magaza_gorselleri/sahneler.dart' show uyeOturumu;

/// Geçen haftanın pazartesisi: o haftanın bütün dersleri bitmiştir.
DateTime get _gecenPzt => demo.haftaBasi.subtract(const Duration(days: 7));

/// Gelecek haftanın pazartesisi: o haftanın hiçbir dersi başlamamıştır.
DateTime get _gelecekPzt => demo.haftaBasi.add(const Duration(days: 7));

DateTime _gun(DateTime pzt, int i, [int saat = 0]) =>
    pzt.add(Duration(days: i, hours: saat));

Map<String, String> _antrenorOturumu() {
  final oturum = uyeOturumu();
  final antrenor = {
    'id': demo.antrenor.id,
    'adi': demo.antrenor.adi,
    'soyadi': demo.antrenor.soyadi,
    'renk': '#1E88E5',
    'is_active': true,
  };
  final profil = (jsonDecode(oturum['uye_profil']!) as Map<String, dynamic>)
    ..['rol'] = 'antrenor'
    ..['uye'] = null
    ..['antrenor'] = antrenor;
  return {
    ...oturum,
    'antrenor': jsonEncode(antrenor),
    'uye_profil': jsonEncode(profil),
    'kullanici_profiller': jsonEncode([profil]),
  };
}

/// Sahte takvim: gün → dersler, ders → yoklama penceresinin verisi.
class _Takvim {
  final Map<String, List<Map<String, Object?>>> gunler = {};
  final Map<int, Map<String, Object?>> katilimlar = {};

  /// [yoklama]: null girilmemiş, true yapıldı, false yapılmadı.
  void ders(
    DateTime baslangic, {
    bool? yoklama,
    bool kilitli = false,
    bool devir = false,
    List<demo.DemoKisi> uyeler = const [demo.uye, demo.DemoKisi(102, 'Ece', 'Şahin')],
  }) {
    final d = demo.ders(baslangic: baslangic, katilimcilar: uyeler);
    if (yoklama != null) {
      d['antrenor_onayi'] = {'id': 1, 'tamamlandi': yoklama};
    }
    if (kilitli) d['yonetici_onayi'] = {'id': 1, 'tamamlandi': true};
    if (devir) {
      d['aktif_devir_talebi'] = {
        'id': 77,
        'rol': 'ANA',
        'durum': 'BEKLIYOR',
        'talep_eden_antrenor_id': demo.antrenor.id,
        'talep_eden_antrenor_adi': demo.antrenor.adSoyad,
        'hedef_antrenor_id': demo.antrenorler[1].id,
        'hedef_antrenor_adi': demo.antrenorler[1].adSoyad,
        'ben_talep_edenim': true,
      };
    }
    gunler.putIfAbsent(demo.apiGun(baslangic), () => []).add(d);
    final id = d['id']! as int;
    katilimlar[id] = {
      'ders_id': id,
      'kilitli_mi': kilitli,
      'antrenor_onayi': yoklama == null ? null : {'tamamlandi': yoklama},
      'katilimlar': [
        for (final u in uyeler)
          {
            'uye_id': u.id,
            'ad_soyad': u.adSoyad,
            'planli_mi': true,
            'katildi': yoklama == true ? true : (yoklama == false ? false : null),
          },
      ],
      'misafirler': const [],
    };
  }
}

http.Response _json(Object? veri) => http.Response.bytes(
    utf8.encode(jsonEncode({'data': veri})), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  final modu = OgrenmeModu.ornek;
  late List<String> istekler;
  late _Takvim takvim;
  late List<int> adimGecmisi;

  void kaydet() {
    if (modu.durum == RehberDurumu.adim) adimGecmisi.add(modu.adimNo);
  }

  final istemci = MockClient((istek) async {
    final uc = ucAdi(istek.url.toString());
    istekler.add(uc);
    final govde = istek.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(istek.body) as Map<String, dynamic>;
    switch (uc) {
      case 'getAntrenorGunlukEtkinlikler':
        final gun = (govde['start'] as String).split('T').first;
        return _json(takvim.gunler[gun] ?? const []);
      case 'getDersKatilimlari':
        return _json(takvim.katilimlar[govde['ders_id']]);
      case 'getAktifUyeListesi':
        return _json([
          {'id': 150, 'ad_soyad': 'Kemal Ay', 'uye_no': 7, 'telefon': ''},
        ]);
      case 'getDersIcinAntrenorListesi':
        return _json({
          'rol': 'ANA',
          'antrenorler': [
            {
              'id': demo.antrenorler[1].id,
              'adi': demo.antrenorler[1].adi,
              'soyadi': demo.antrenorler[1].soyadi,
              'ad_soyad': demo.antrenorler[1].adSoyad,
              'devralabilir_mi': true,
            },
          ],
        });
    }
    return http.Response('{"detail": "yok"}', 404,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });

  /// Pencerelerin kendi çizim uyarıları (test yazı tipinde taşma, mürekkebi
  /// örtülen ListTile) rehber mantığından ayrı konular; burada yalnız
  /// toplanır, rehber yürüyüşünü düşürmez.
  final ekranUyarilari = <String>{};
  const tolere = ['overflowed', 'ink splashes may be invisible'];

  Future<void> yuru(Future<void> Function() govde) async {
    final eski = FlutterError.onError;
    FlutterError.onError = (ayrinti) {
      final mesaj = ayrinti.exceptionAsString();
      if (tolere.any(mesaj.contains)) {
        ekranUyarilari.add(mesaj.split('\n').first);
        return;
      }
      eski?.call(ayrinti);
    };
    try {
      await http.runWithClient(govde, () => istemci);
    } finally {
      FlutterError.onError = eski;
    }
  }

  setUpAll(() => initializeDateFormatting('tr', null));

  setUp(() {
    istekler = [];
    takvim = _Takvim();
    adimGecmisi = [];
    modu.addListener(kaydet);
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues(_antrenorOturumu());
  });

  tearDown(() {
    modu.removeListener(kaydet);
    modu.kapat();
    OgrenmeKapisi.acik = false;
  });

  /// Sayfayı [gun] seçili açar (bildirimden gelişteki `tarih` argümanı).
  Future<void> kur(WidgetTester tester, DateTime gun) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => OgrenmeKatmani(child: child!),
      onGenerateRoute: (ayar) => MaterialPageRoute(
        settings: RouteSettings(
            name: ayar.name, arguments: {'tarih': demo.apiGun(gun)}),
        builder: (_) => const AntrenorTakvimPage(),
      ),
    ));
    await bekle(tester, 15);
  }

  Future<void> rehberiBaslat(WidgetTester tester, String baslik) async {
    await tester.tap(find.byTooltip('Nasıl yapılır?'));
    await bekle(tester, 5);
    final satir = find.text(baslik);
    expect(satir, findsOneWidget);
    await tester.tap(satir);
    await bekle(tester, 8);
    expect(modu.durum, RehberDurumu.adim,
        reason: '"$baslik" ekranda başlamadı (okuma görünümü açıldı)');
  }

  /// [beklenen] adıma gelene kadar en çok [tur] tur bekler.
  Future<void> adimda(WidgetTester tester, int beklenen, {int tur = 40}) async {
    for (var i = 0; i < tur && modu.adimNo != beklenen; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(modu.durum, RehberDurumu.adim);
    expect(modu.adimNo, beklenen,
        reason: 'Adım ${modu.adimNo + 1}/${modu.gorev?.adimlar.length}; '
            'hedefYok=${modu.hedefYok}, sonrakiYok=${modu.sonrakiYok}, '
            'geçmiş=$adimGecmisi');
  }

  Future<void> deligeDokun(WidgetTester tester) async {
    final delik = modu.delik;
    expect(delik, isNotNull,
        reason: 'Parlayan yer yok (adım ${modu.adimNo + 1}, '
            'hedefYok=${modu.hedefYok})');
    await tester.tapAt(delik!.center);
    await bekle(tester, 8);
  }

  Future<void> anladim(WidgetTester tester) async {
    await tester.tap(find.text('Anladım'));
    await bekle(tester, 6);
  }

  Future<void> gunSec(WidgetTester tester, DateTime gun) async {
    await tester.tap(find.descendant(
        of: find.byType(HaftaGunSecici), matching: find.text('${gun.day}')));
    await bekle(tester, 10);
  }

  /// Bitti; adım hiç geri gitmedi, ağa yazma isteği çıkmadı.
  Future<void> bittiVeTemiz(WidgetTester tester) async {
    expect(modu.durum, RehberDurumu.bitis);
    for (var i = 1; i < adimGecmisi.length; i++) {
      expect(adimGecmisi[i], greaterThanOrEqualTo(adimGecmisi[i - 1]),
          reason: 'Adım geri gitti: $adimGecmisi');
    }
    expect(OgrenmeKapisi.engellenenler, isEmpty);
    expect(istekler.where((u) => !okumaUclari.contains(u)), isEmpty,
        reason: 'Rehber sırasında yalnız okuma isteği gider: $istekler');
    modu.kapat();
    await bekle(tester, 6);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  Future<void> temizle(WidgetTester tester) async {
    modu.kapat();
    await bekle(tester, 6);
    await tester.pumpWidget(const SizedBox.shrink());
  }

  group('antrenor.yoklamaDuzelt', () {
    const baslik = 'Yoklamayı yanlış girdiysem nasıl düzeltirim?';

    testWidgets(
        'telefondaki hata: seçili günde uygun ders yokken «Anladım» 1/4\'te '
        'kalır, uygun güne geçince sürer ve sona kadar yürür', (tester) async {
      takvim.ders(_gun(_gecenPzt, 0, 10)); // yoklaması girilmemiş
      takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: true);
      await yuru(() async {
        await kur(tester, _gecenPzt);
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 0);
        expect(find.text('1/4'), findsOneWidget);

        await anladim(tester);
        expect(modu.sonrakiYok, isTrue);
        expect(
            find.text('Bu günde uygun ders yok; başka gün seç.'), findsOneWidget);
        await bekle(tester, 30);
        expect(modu.adimNo, 0, reason: 'Eski hata: 2/4 → 1/4 sekmesi');

        await gunSec(tester, _gun(_gecenPzt, 1));
        await adimda(tester, 1);
        expect(modu.sonrakiYok, isFalse);

        await deligeDokun(tester); // ders → yoklama penceresi (ayrıntı)
        expect(find.byType(LessonApprovalDialog), findsOneWidget);
        await adimda(tester, 2);
        await anladim(tester);
        await adimda(tester, 3);
        await deligeDokun(tester); // son «Kaydet»: basılmaz
        await bittiVeTemiz(tester);
      });
    });

    testWidgets('seçili günde yoklaması girilmiş ders varken gün adımı atlanır',
        (tester) async {
      takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: true);
      await yuru(() async {
        await kur(tester, _gun(_gecenPzt, 1));
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 1);
        await deligeDokun(tester);
        await adimda(tester, 2);
        await anladim(tester);
        await adimda(tester, 3);
        await deligeDokun(tester);
        await bittiVeTemiz(tester);
      });
    });

    // Düzeltme ister ders bloğunda ister pencerede olsun: parlatılan derse
    // dokununca yoklama satırına gelinmeli ya da ders hiç parlatılmamalı.
    group('düzeltilen hata', () {
      testWidgets(
          '«Ders yapılmadı» girilmiş ders parlatılırsa yoklama satırına ulaşır',
          (tester) async {
        takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: false);
        await yuru(() async {
          await kur(tester, _gun(_gecenPzt, 1));
          await rehberiBaslat(tester, baslik);
          if (modu.adimNo == 0) {
            // Ders bu rehbere uygun sayılmadı: gün adımında kalınır.
            await anladim(tester);
            expect(modu.sonrakiYok, isTrue);
            return temizle(tester);
          }
          await adimda(tester, 1);
          await deligeDokun(tester);
          await adimda(tester, 2);
          await anladim(tester);
          await adimda(tester, 3);
          await deligeDokun(tester);
          await bittiVeTemiz(tester);
        });
      });
    });

    group('düzeltilen hata', () {
      testWidgets(
          'ajanda görünümünde rehber ya başlamaz ya yoklaması girilmiş '
          'derse ulaşır', (tester) async {
        takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: true);
        await yuru(() async {
          await kur(tester, _gun(_gecenPzt, 1));
          await tester.tap(find.byTooltip('Ajanda görünümü'));
          await bekle(tester, 15);
          await tester.tap(find.byTooltip('Nasıl yapılır?'));
          await bekle(tester, 5);
          await tester.tap(find.text(baslik));
          await bekle(tester, 8);
          if (modu.durum != RehberDurumu.adim) return temizle(tester);
          await adimda(tester, 1, tur: 20);
          await deligeDokun(tester);
          await adimda(tester, 2);
          await anladim(tester);
          await adimda(tester, 3);
          await deligeDokun(tester);
          await bittiVeTemiz(tester);
        });
      });
    });
  });

  group('antrenor.gecmisYoklama', () {
    const baslik = 'Geçmiş derse yoklamayı nasıl girerim?';

    testWidgets(
        'yoklamasız ders başka günde: gün seçilir, hızlı onay kartına kadar '
        'yürür', (tester) async {
      takvim.ders(_gun(_gecenPzt, 0, 10), yoklama: true);
      takvim.ders(_gun(_gecenPzt, 2, 12));
      await yuru(() async {
        await kur(tester, _gecenPzt);
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 0);
        await anladim(tester);
        expect(modu.adimNo, 0);
        expect(modu.sonrakiYok, isTrue);
        await gunSec(tester, _gun(_gecenPzt, 2));
        await adimda(tester, 1);
        await deligeDokun(tester); // → hızlı onay
        expect(find.byType(LessonApprovalDialog), findsOneWidget);
        await adimda(tester, 2);
        expect(find.text('Ders yapıldı, herkes geldi'), findsOneWidget);
        await deligeDokun(tester); // kalıcı: basılmaz
        expect(find.text('Denemeydi, herhangi bir işlem yapılmadı.'),
            findsOneWidget);
        await bittiVeTemiz(tester);
      });
    });
  });

  group('antrenor.kilitliDers', () {
    const baslik = 'Dersim neden kilitli?';

    testWidgets('kilitli derste kilit kutusu okunur, rehber biter',
        (tester) async {
      takvim.ders(_gun(_gecenPzt, 1, 10)); // yoklamasız, kilitsiz
      takvim.ders(_gun(_gecenPzt, 1, 14), yoklama: true, kilitli: true);
      await yuru(() async {
        await kur(tester, _gun(_gecenPzt, 1));
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 1);
        await deligeDokun(tester);
        await adimda(tester, 2);
        expect(find.text('Tamam'), findsOneWidget, reason: 'kilitli görünüm');
        await anladim(tester);
        await bittiVeTemiz(tester);
      });
    });

    testWidgets('yoklama girilmeden kilitlenen derste de biter',
        (tester) async {
      takvim.ders(_gun(_gecenPzt, 1, 10), kilitli: true);
      await yuru(() async {
        await kur(tester, _gun(_gecenPzt, 1));
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 1);
        await deligeDokun(tester);
        await adimda(tester, 2);
        await anladim(tester);
        await bittiVeTemiz(tester);
      });
    });
  });

  group('antrenor.renkler', () {
    testWidgets('bitmiş ders bloğu okunur', (tester) async {
      takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: true);
      await yuru(() async {
        await kur(tester, _gun(_gecenPzt, 1));
        await rehberiBaslat(tester, 'Ders bloklarındaki yazılar ne demek?');
        await adimda(tester, 1);
        await anladim(tester);
        await bittiVeTemiz(tester);
      });
    });
  });

  group('antrenor.planDisi', () {
    const baslik = 'Derse planda olmayan birini nasıl eklerim?';

    testWidgets(
        'yoklamasız derste hızlı onaydan plan dışı üye notuna ve son '
        '«Kaydet»e kadar yürür', (tester) async {
      takvim.ders(_gun(_gecenPzt, 1, 10));
      await yuru(() async {
        await kur(tester, _gun(_gecenPzt, 1));
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 1);
        await deligeDokun(tester); // ders → hızlı onay
        await adimda(tester, 2);
        await deligeDokun(tester); // «Eksik ya da fazla var» → ayrıntı
        await adimda(tester, 3);
        await deligeDokun(tester); // «Üye» → üye listesi
        await adimda(tester, 4);
        await deligeDokun(tester); // üye → not penceresi
        await adimda(tester, 5);
        await anladim(tester);
        await adimda(tester, 6);
        await deligeDokun(tester); // notun «Kaydet»i
        await adimda(tester, 7);
        await deligeDokun(tester); // yoklamanın «Kaydet»i: basılmaz
        await bittiVeTemiz(tester);
      });
    });

    // Pencere ayrıntıda açılınca «Eksik ya da fazla var» adımı atlanır:
    // motor hedefi olmayan atlanabilir adımın ardındakine de bakar.
    // antrenor.misafir aynı kalıpta.
    group('düzeltilen hata', () {
      for (final (rehber, sonraki) in const [
        (baslik, 'Üye'),
        ('Kayıtsız misafiri nasıl eklerim?', 'Misafir'),
      ]) {
        testWidgets(
            '$rehber: yoklaması girilmiş ders parlatılırsa «$sonraki» '
            'adımına geçer', (tester) async {
          takvim.ders(_gun(_gecenPzt, 1, 10), yoklama: true);
          await yuru(() async {
            await kur(tester, _gun(_gecenPzt, 1));
            await rehberiBaslat(tester, rehber);
            if (modu.adimNo == 0) return temizle(tester);
            await adimda(tester, 1);
            await deligeDokun(tester); // ders → yoklama penceresi (ayrıntı)
            expect(find.text('Yoklamayı Güncelle'), findsOneWidget);
            await bekle(tester, 30);
            expect(modu.adimNo, 3,
                reason: 'adım ${modu.adimNo + 1}, hedefYok=${modu.hedefYok}');
            expect(modu.hedefYok, isFalse);
            await temizle(tester);
          });
        });
      }
    });
  });

  group('antrenor.devir', () {
    testWidgets('gelecek dersi devretme son «Devir Talebi Gönder»e kadar yürür',
        (tester) async {
      takvim.ders(_gun(_gelecekPzt, 1, 10));
      await yuru(() async {
        await kur(tester, _gun(_gelecekPzt, 1));
        await rehberiBaslat(tester, 'Dersimi başka hocaya nasıl veririm?');
        await adimda(tester, 1);
        await deligeDokun(tester); // ders → detay
        await adimda(tester, 2);
        await deligeDokun(tester); // «Devret» → devir penceresi
        await adimda(tester, 3);
        await deligeDokun(tester); // antrenör kutusu → aday listesi
        await adimda(tester, 4);
        await deligeDokun(tester); // aday → seçilir, liste kapanır
        await adimda(tester, 5);
        await deligeDokun(tester); // son buton: basılmaz
        await bittiVeTemiz(tester);
      });
    });

    testWidgets('devir talebini geri çekme sonuna kadar yürür',
        (tester) async {
      takvim.ders(_gun(_gelecekPzt, 1, 10)); // devirsiz gelecek ders
      takvim.ders(_gun(_gelecekPzt, 1, 14), devir: true);
      await yuru(() async {
        await kur(tester, _gun(_gelecekPzt, 1));
        await rehberiBaslat(tester, 'Devir talebimi nasıl geri çekerim?');
        await adimda(tester, 1);
        await deligeDokun(tester); // devirli ders → detay
        await adimda(tester, 2);
        await deligeDokun(tester); // «Talebi Gör» → devir penceresi
        await adimda(tester, 3);
        await deligeDokun(tester); // «Talebi Geri Çek»: basılmaz
        await bittiVeTemiz(tester);
      });
    });
  });

  group('antrenor.katilimcilar', () {
    const baslik = 'Derse kimlerin geleceğini nerede görürüm?';

    testWidgets('gelecek dersin katılımcı listesi okunur', (tester) async {
      takvim.ders(_gun(_gelecekPzt, 1, 10));
      await yuru(() async {
        await kur(tester, _gun(_gelecekPzt, 1));
        await rehberiBaslat(tester, baslik);
        await adimda(tester, 1);
        await deligeDokun(tester);
        expect(find.byType(FutureLessonDetailDialog), findsOneWidget);
        await adimda(tester, 2);
        await anladim(tester);
        await bittiVeTemiz(tester);
      });
    });

    group('düzeltilen hata', () {
      testWidgets(
          'henüz kimsenin yazılmadığı gelecek ders parlatılırsa rehber biter',
          (tester) async {
        takvim.ders(_gun(_gelecekPzt, 1, 10), uyeler: const []);
        await yuru(() async {
          await kur(tester, _gun(_gelecekPzt, 1));
          await rehberiBaslat(tester, baslik);
          if (modu.adimNo == 0) return temizle(tester);
          await adimda(tester, 1);
          await deligeDokun(tester);
          await adimda(tester, 2);
          await anladim(tester);
          await bittiVeTemiz(tester);
        });
      });
    });
  });
}

/// Rehberin sürekli animasyonu yüzünden pumpAndSettle bitmez; adım adım ilerlet.
Future<void> bekle(WidgetTester tester, int tur) async {
  for (var i = 0; i < tur; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
