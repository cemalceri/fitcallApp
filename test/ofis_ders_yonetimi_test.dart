// Ofis Ana Sayfa (bekleyen işler), Dersler (onay/hakediş/teyit/paket) ve
// plan dışı karar formu: model türetmeleri, süzgeçler ve ekran davranışı.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/widgets/ofis_ana_sayfa_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ders_yonetim_sheet.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/widgets/plan_disi_karar_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/ofis_ornekleri.dart';

Widget _uygulama(Widget govde) => MaterialApp(
      locale: const Locale('tr', 'TR'),
      theme: FitcallTema.acik,
      home: Scaffold(body: govde),
    );

DersYonetimGovdesi _govde(
  YonetimDersi ders, {
  VoidCallback? onYapildi,
  VoidCallback? onYapilmadi,
  ValueChanged<YonetimKatilimci>? onKatilacak,
  ValueChanged<YonetimKatilimci>? onHatirlat,
  ValueChanged<YonetimKatilimci>? onPaketDusum,
}) =>
    DersYonetimGovdesi(
      ders: ders,
      mesgul: false,
      onYapildi: onYapildi ?? () {},
      onYapilmadi: onYapilmadi ?? () {},
      onKarariKaldir: () {},
      onHakedis: (_, __) {},
      onKatilacak: onKatilacak ?? (_) {},
      onHatirlat: onHatirlat ?? (_) {},
      onPaketDusum: onPaketDusum ?? (_) {},
      onPlanDisi: () {},
    );

void main() {
  setUpAll(() => initializeDateFormatting('tr', null));

  group('Model türetmeleri', () {
    test('onay bekleyen, toplu onay ve cevapsız sayıları', () {
      final gun = ornekGun();
      // 1 (antrenör yapıldı) ve 2 (antrenör yapılmadı) bekliyor; 3 kararlı,
      // 4 iptal, 5 gelecek.
      expect(gun.onayBekleyen, 2);
      expect(gun.topluOnaylanabilir, 1);
      // Gelecek derste bekliyor + bildirim yok; katılacak/katılmayacak sayılmaz.
      expect(gun.cevapsiz, 2);
      expect(gun.iptal, 1);
      expect(gun.yapilmadiNedenleri.map((n) => n.kod), contains('YMD_HAVA'));
    });

    test('katılımcı alanları', () {
      final ders = ornekGun().dersler.first;
      expect(ders.katilimcilar[0].paketDusumu, PaketDusumu.dus);
      expect(ders.katilimcilar[1].paketDusumu, PaketDusumu.geriAl);
      expect(ders.katilimcilar[1].katildi, isFalse);
      expect(ders.katilimcilar[2].planDisiMi, isTrue);
      expect(ders.planDisiBekleyen, 2);
    });

    test('bekleyen işler', () {
      final v = ornekBekleyenIsler();
      expect(v.onayBekleyen, 137);
      expect(v.onayGunleri.first.antrenorOnayli, 5);
      expect(v.isYok, isFalse);
      expect(ornekBekleyenIsler(bos: true).isYok, isTrue);
    });

    test('katılım cevabı: günler ve açılacak ilk gün', () {
      final v = ornekBekleyenIsler();
      expect(v.teyitGunleri.map((g) => g.$2), [5, 7]);
      expect(v.ilkTeyitGunu, bugunKulup());
      // Bugün herkes cevapladıysa ekran yarını açar.
      final yarin = bugunKulup().add(const Duration(days: 1));
      final yalnizYarin = OfisBekleyenIsler.fromJson({
        'teyit_bekleyen': {
          'kisi': 3,
          'ders': 1,
          'gunler': [
            {'tarih': formatApiGun(yarin), 'kisi': 3},
          ],
        },
      });
      expect(yalnizYarin.ilkTeyitGunu, yarin);
      // Eski sunucu (gün listesi yok): bugün.
      expect(
          OfisBekleyenIsler.fromJson({
            'teyit_bekleyen': {'kisi': 2, 'ders': 1},
          }).ilkTeyitGunu,
          bugunKulup());
    });

    test('süzgeçler ve durum etiketleri', () {
      final d = ornekGun().dersler;
      expect(d.where(DersSuzgeci.onayBekleyen.uyar).map((x) => x.id), [1, 2]);
      expect(d.where(DersSuzgeci.cevapsiz.uyar).map((x) => x.id), [5]);
      expect(d.where(DersSuzgeci.iptal.uyar).map((x) => x.id), [4]);
      expect(dersDurumu(d[0]).$1, 'Onay bekliyor');
      expect(dersDurumu(d[2]).$1, 'Yapıldı');
      expect(dersDurumu(d[3]).$1, 'İptal');
      expect(dersDurumu(d[4]).$1, '2 cevap bekliyor');
    });

    test('plan dışı kişinin karar anahtarı', () {
      final k = ornekPlanDisi().first.kisiler.first;
      expect(k.misafirMi, isTrue);
      expect(k.anahtar, 'misafir:3');
    });
  });

  group('Dersler görünümü', () {
    Widget gorunum({
      DersSuzgeci suzgec = DersSuzgeci.tumu,
      VoidCallback? onTopluOnay,
      ValueChanged<YonetimDersi>? onDersSec,
    }) =>
        OfisDerslerGorunumu(
          tarih: DateTime(2026, 10, 12),
          gun: ornekGun(),
          yukleniyor: false,
          hata: null,
          suzgec: suzgec,
          onOnceki: () {},
          onSonraki: () {},
          onTarihSec: () {},
          onBugun: () {},
          onSuzgec: (_) {},
          onDersSec: onDersSec ?? (_) {},
          onTopluOnay: onTopluOnay ?? () {},
          onYenile: () async {},
          onYenidenDene: () {},
        );

    testWidgets('antrenörün onayladığı ders varsa toplu onay kartı',
        (tester) async {
      var onaylandi = 0;
      await tester
          .pumpWidget(_uygulama(gorunum(onTopluOnay: () => onaylandi++)));
      expect(find.textContaining('1 ders onay bekliyor'), findsOneWidget);
      await tester.tap(find.text('Hepsini onayla'));
      expect(onaylandi, 1);
    });

    testWidgets('süzgeç çipinde sayı, süzülen liste', (tester) async {
      await tester.pumpWidget(_uygulama(gorunum(suzgec: DersSuzgeci.iptal)));
      expect(find.text('Onay bekleyen · 2'), findsOneWidget);
      expect(find.byType(DersYonetimSatiri), findsOneWidget);
    });

    testWidgets('satıra dokununca ders seçilir', (tester) async {
      YonetimDersi? secilen;
      await tester.pumpWidget(_uygulama(
          gorunum(suzgec: DersSuzgeci.iptal, onDersSec: (d) => secilen = d)));
      await tester.tap(find.byType(DersYonetimSatiri));
      expect(secilen?.id, 4);
    });
  });

  group('Ders işlem sayfası', () {
    testWidgets('geçmiş derste onay düğmeleri ve paket düşümü', (tester) async {
      var yapildi = 0;
      YonetimKatilimci? paket;
      await tester.pumpWidget(_uygulama(_govde(
        ornekGun().dersler.first,
        onYapildi: () => yapildi++,
        onPaketDusum: (k) => paket = k,
      )));
      expect(find.text('Antrenör: yapıldı dedi'), findsOneWidget);
      expect(find.text('Hakediş'), findsOneWidget);
      await tester.tap(find.text('Yapıldı'));
      expect(yapildi, 1);
      await tester.tap(find.text('Paketten düş'));
      expect(paket?.uyeId, 10);
      expect(find.text('Düşümü geri al'), findsOneWidget);
      expect(find.textContaining('karar bekleniyor'), findsOneWidget);
    });

    testWidgets('onaylı derste seçili karara yeniden basılamaz, kaldırılabilir',
        (tester) async {
      var yapildi = 0;
      await tester.pumpWidget(
          _uygulama(_govde(ornekGun().dersler[2], onYapildi: () => yapildi++)));
      await tester.tap(find.text('Yapıldı'));
      expect(yapildi, 0);
      expect(find.text('Kararı kaldır'), findsOneWidget);
      // Yardımcı antrenör satırı da var.
      expect(find.textContaining('(yardımcı)'), findsWidgets);
    });

    testWidgets('gelecek derste katılacak / hatırlat yalnız cevapsızlarda',
        (tester) async {
      final katilacak = <int>[];
      final hatirlat = <int>[];
      await tester.pumpWidget(_uygulama(_govde(
        ornekGun().dersler[4],
        onKatilacak: (k) => katilacak.add(k.uyeId),
        onHatirlat: (k) => hatirlat.add(k.uyeId),
      )));
      // Onay bölümü gelecek derste yok.
      expect(find.text('Yapılmadı'), findsNothing);
      // bekliyor + bildirim_yok + katılmayacak → 3 "Katılacak"; katılacak olana yok.
      expect(find.text('Katılacak'), findsNWidgets(4)); // 3 düğme + 1 durum
      expect(find.text('Hatırlat'), findsNWidgets(2));
      await tester.tap(find.text('Hatırlat').first);
      expect(hatirlat, [20]);
    });

    testWidgets('iptal derste yalnız künye', (tester) async {
      await tester.pumpWidget(_uygulama(_govde(ornekGun().dersler[3])));
      expect(find.text('Ders iptal edildi'), findsOneWidget);
      expect(find.text('Yapıldı'), findsNothing);
      expect(find.textContaining('Hava koşulları'), findsOneWidget);
    });

    // Sayfa açıkken ders bitince sunucunun `baglam`ı bayatlıyor. Satır
    // etiketi istemci saatini kullandığı için "Onay bekliyor" diyor ve
    // "Hepsini onayla" sayacına giriyordu; sheet ise `baglam`a baktığından
    // Yapıldı/Yapılmadı düğmelerini hiç çizmiyordu.
    testWidgets('bayat "gelecek" bağlamında onay düğmeleri çizilir',
        (tester) async {
      final ders = YonetimDersi.fromJson({
        ...dersJson(saatSonra: -3),
        'baglam': 'gelecek',
      });
      expect(ders.bittiMi, isTrue);
      expect(ders.onayBekliyor, isTrue);

      await tester.pumpWidget(_uygulama(_govde(ders)));
      expect(find.text('Yapıldı'), findsOneWidget);
      expect(find.text('Yapılmadı'), findsOneWidget);
    });
  });

  group('Ders bitti ölçütü', () {
    test('satır ve sheet aynı ölçütten geçer', () {
      final bitmis = YonetimDersi.fromJson(dersJson(saatSonra: -3));
      expect(bitmis.bittiMi, isTrue);
      expect(bitmis.kararVerilebilir, isTrue);
      expect(bitmis.onayBekliyor, isTrue);

      final gelecek = YonetimDersi.fromJson(dersJson(saatSonra: 5));
      expect(gelecek.bittiMi, isFalse);
      expect(gelecek.kararVerilebilir, isFalse);
      expect(gelecek.onayBekliyor, isFalse);
    });

    test('iptal ve kararlı derste karar verilemez / beklemez', () {
      final iptal = YonetimDersi.fromJson(dersJson(saatSonra: -3, iptal: true));
      expect(iptal.kararVerilebilir, isFalse);
      expect(iptal.onayBekliyor, isFalse);

      final kararli =
          YonetimDersi.fromJson(dersJson(saatSonra: -3, yonetici: true));
      expect(kararli.kararVerilebilir, isTrue, reason: 'karar değiştirilebilir');
      expect(kararli.onayBekliyor, isFalse);
    });
  });

  group('Plan dışı karar formu', () {
    Future<List<PlanDisiKararGirdisi>> ac(WidgetTester tester) async {
      final kayit = <PlanDisiKararGirdisi>[];
      final ders = ornekPlanDisi().first;
      await tester.pumpWidget(_uygulama(PlanDisiKararFormu(
        ders: ders,
        kisi: ders.kisiler.first,
        secenekler: ornekSecenekler(),
        kaydediliyor: false,
        onKaydet: kayit.add,
      )));
      return kayit;
    }

    testWidgets('borçta tutar ve açıklama zorunlu', (tester) async {
      final kayit = await ac(tester);
      await tester.tap(find.text('Kararı kaydet'));
      await tester.pump();
      expect(find.text('Geçerli bir tutar girin.'), findsOneWidget);
      expect(find.textContaining('Açıklama zorunlu'), findsOneWidget);
      expect(kayit, isEmpty);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Tutar'), '450,5');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Açıklama'), 'Deneme dersi');
      await tester.tap(find.text('Kararı kaydet'));
      await tester.pump();
      expect(kayit.single.karar, 'BORC');
      expect(kayit.single.tutar, '450.5');
      // Varsayılan ödeyen: misafir havuzu.
      expect(kayit.single.hedefUyeId, 1);
    });

    testWidgets('sunucu hatası formun içinde görünür', (tester) async {
      final ders = ornekPlanDisi().first;
      await tester.pumpWidget(_uygulama(PlanDisiKararFormu(
        ders: ders,
        kisi: ders.kisiler.first,
        secenekler: ornekSecenekler(),
        kaydediliyor: false,
        hata: 'Bu ders için karar verilemez.',
        onKaydet: (_) {},
      )));
      expect(find.text('Bu ders için karar verilemez.'), findsOneWidget);
    });

    testWidgets('ücretsizde tutar ve ödeyen istenmez', (tester) async {
      final kayit = await ac(tester);
      await tester.tap(find.text('Ücretsiz'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Tutar'), findsNothing);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Açıklama'), 'Kulüp misafiri');
      await tester.tap(find.text('Kararı kaydet'));
      await tester.pump();
      expect(kayit.single.karar, 'UCRETSIZ');
      expect(kayit.single.tutar, isNull);
      expect(kayit.single.uyeUrunId, isNull);
    });

    testWidgets('paketi olmayan ödeyende uyarı', (tester) async {
      await ac(tester);
      await tester.tap(find.text('Paketten'));
      await tester.pump();
      expect(find.textContaining('aktif paketi yok'), findsOneWidget);
    });
  });

  group('Ana Sayfa', () {
    testWidgets('bekleyen işler sayılarla, dokununca ilgili ekran',
        (tester) async {
      final acilan = <String>[];
      await tester.pumpWidget(_uygulama(OfisAnaSayfaGorunumu(
        ofisAdi: 'Mehmet Yılmaz',
        profilDegistir: false,
        veri: ornekBekleyenIsler(),
        yukleniyor: false,
        hata: null,
        onYenile: () async {},
        onYenidenDene: () {},
        onOnay: () => acilan.add('onay'),
        onPlanDisi: () => acilan.add('plan'),
        onTeyit: () => acilan.add('teyit'),
        onBugununDersleri: () => acilan.add('bugun'),
        zil: const SizedBox(),
      )));
      expect(find.text('137'), findsOneWidget);
      expect(find.text('42 ders'), findsOneWidget);
      await tester.tap(find.text('Ders onayı'));
      await tester.tap(find.text('Plan dışı / misafir kararı'));
      expect(find.text('Bugün 5 · Yarın 7 kişi'), findsOneWidget);
      await tester.tap(find.text('Katılım cevabı bekleyenler'));
      expect(acilan, ['onay', 'plan', 'teyit']);
    });

    testWidgets('bekleyen iş yoksa boş durum', (tester) async {
      await tester.pumpWidget(_uygulama(OfisAnaSayfaGorunumu(
        ofisAdi: '',
        profilDegistir: false,
        veri: ornekBekleyenIsler(bos: true),
        yukleniyor: false,
        hata: null,
        onYenile: () async {},
        onYenidenDene: () {},
        onOnay: () {},
        onPlanDisi: () {},
        onTeyit: () {},
        onBugununDersleri: () {},
        zil: const SizedBox(),
      )));
      expect(find.text('Bekleyen iş yok'), findsOneWidget);
      expect(find.byType(ListeSatiri), findsNothing);
    });
  });
}
