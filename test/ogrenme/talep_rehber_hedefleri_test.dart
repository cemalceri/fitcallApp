// Ders / kort talebi rehberlerinin hedefleri adımın gerektirdiği durumdaki
// satıra konur (öneri bekleyen, geri çekilebilir; ofiste öneri ya da kayıt
// yapılabilen talep), haritada ilk uygun kareye; ofis Talepler başlığında "?"
// durur.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/taleplerim_gorunumu.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/uygunluk_haritasi.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/ofis_talepler_gorunumu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

UyeTalep _uyeTalep(int id, String durum, {bool oneri = false}) =>
    UyeTalep.fromJson({
      'id': id,
      'tur': 'PAKET',
      'tur_adi': 'Paketim',
      'durum': 'UYEDE',
      'uye_durum': durum,
      'durum_metni': durum,
      'uye_id': 1,
      'antrenor_id': 1,
      'antrenor_adi': 'Hoca',
      'kort_adi': 'Kort',
      'baslangic_tarih_saat': '2026-11-05T17:00:00+03:00',
      'bitis_tarih_saat': '2026-11-05T18:00:00+03:00',
      'sure_dk': 60,
      'ders_tanimi': 'Talep$id',
      'oneri': oneri
          ? {
              'baslangic_tarih_saat': '2026-11-05T18:00:00+03:00',
              'bitis_tarih_saat': '2026-11-05T19:00:00+03:00',
              'sure_dk': 60,
              'ders_tanimi': 'Öneri$id',
            }
          : null,
      'geri_cekilebilir': durum != 'KAPANDI',
    });

OfisUyeTalep _ofisTalep(int id, {bool oneri = false, bool kaydet = false}) =>
    OfisUyeTalep.fromJson({
      'id': id,
      'tur': 'KORT',
      'tur_adi': 'Kort kiralama',
      'durum': 'BEKLIYOR',
      'sekme': 'bende',
      'uye_adi': 'Üye$id',
      'antrenor_adi': 'Antrenörsüz',
      'kort_adi': 'Kort',
      'baslangic_tarih_saat': '2026-11-05T17:00:00+03:00',
      'bitis_tarih_saat': '2026-11-05T18:00:00+03:00',
      'sure_dk': 60,
      'ders_tanimi': '5 Kasım 17:00-18:00',
      'hak_durumu': 'Uygun',
      'hak_uygun': true,
      'eylemler': {'kaydet': kaydet, 'oneri': oneri, 'reddet': true},
    });

Finder _hedef(String id) =>
    find.byWidgetPredicate((w) => w is OgrenmeHedefi && w.id == id);

Future<void> _kur(WidgetTester tester, Widget govde) async {
  await tester.pumpWidget(MaterialApp(
    theme: FitcallTema.temasi(TakimTemasi.binay, Brightness.light),
    home: Scaffold(body: govde),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  testWidgets('Taleplerim: öneri bekleyen ve geri çekilebilir ilk talep',
      (tester) async {
    await _kur(
      tester,
      TaleplerimGorunumu(
        talepler: [
          _uyeTalep(1, 'KAPANDI'),
          _uyeTalep(2, 'OFISTE'),
          _uyeTalep(3, 'CEVAP_BEKLIYOR', oneri: true),
        ],
        onYenile: () async {},
        onYenidenDene: () {},
        onAc: (_) {},
        onYeni: () {},
      ),
    );

    Finder satirda(String yazi, String id) =>
        find.ancestor(of: find.textContaining(yazi), matching: _hedef(id));
    expect(satirda('Talep2', Hedef.uyeTalepGeriCekilir), findsOneWidget);
    expect(satirda('Öneri3', Hedef.uyeTalepOnerili), findsOneWidget);
    expect(OgrenmeHedefi.kayitlilar(Hedef.uyeTalepGeriCekilir), hasLength(1));
    expect(OgrenmeHedefi.kayitlilar(Hedef.uyeTalepOnerili), hasLength(1));
  });

  testWidgets('talep detayında öneri kutusu hedeftir', (tester) async {
    await _kur(
      tester,
      TalepDetayGorunumu(
        talep: _uyeTalep(3, 'CEVAP_BEKLIYOR', oneri: true),
        isleniyor: false,
        onKabul: () {},
        onReddet: () {},
        onGeriCek: () {},
        onDuzenle: () {},
        onBenzeri: () {},
      ),
    );
    expect(
        find.ancestor(
            of: find.text('Ofisin önerisi'),
            matching: _hedef(Hedef.uyeTalepOneri)),
        findsOneWidget);
  });

  testWidgets('ofis Talepler: "?" ve eylemi olan ilk üye talebi',
      (tester) async {
    await _kur(
      tester,
      OfisTaleplerGorunumu(
        sekme: 'bende',
        liste: OfisTalepListesi(talepler: [
          _ofisTalep(1),
          _ofisTalep(2, oneri: true),
          _ofisTalep(3, oneri: true, kaydet: true),
        ]),
        onSekme: (_) {},
        onYenile: () async {},
        onYenidenDene: () {},
        onUyeTalepAc: (_) {},
        onAra: (_) {},
        onKayitOlustur: (_) {},
        onReddet: (_) {},
        onProgramdaGoster: (_) {},
      ),
    );

    expect(find.byType(OgrenmeButonu), findsOneWidget);
    Finder satirda(String yazi, String id) =>
        find.ancestor(of: find.textContaining(yazi), matching: _hedef(id));
    expect(satirda('Üye2', Hedef.ofisTalepOnerilebilir), findsOneWidget);
    expect(satirda('Üye3', Hedef.ofisTalepKaydedilir), findsOneWidget);
    expect(OgrenmeHedefi.kayitlilar(Hedef.ofisTalepOnerilebilir), hasLength(1));
  });

  testWidgets('haritada ilk uygun kare hedeftir, dokununca o saat seçilir',
      (tester) async {
    DateTime? secilen;
    final harita = TalepHarita.fromJson({
      'hafta_baslangic': '2026-11-02',
      'onceki_hafta': false,
      'sonraki_hafta': false,
      'sure_dk': 60,
      'gunler': [
        {
          'tarih': '2026-11-02',
          'gun_adi': 'Pzt',
          'saatler': [
            {'saat': '08:00', 'durum': 'dolu'},
            {'saat': '08:30', 'durum': 'uygun'},
          ],
        },
        {
          'tarih': '2026-11-03',
          'gun_adi': 'Sal',
          'saatler': [
            {'saat': '08:00', 'durum': 'uygun'},
            {'saat': '08:30', 'durum': 'uygun'},
          ],
        },
      ],
    });
    await _kur(
      tester,
      UygunlukHaritasi(harita: harita, onSec: (an) => secilen = an),
    );

    final hedef = _hedef(Hedef.uyeTalepKare);
    expect(hedef, findsOneWidget);
    await tester.tap(hedef);
    expect(secilen, DateTime(2026, 11, 3, 8));
  });
}
