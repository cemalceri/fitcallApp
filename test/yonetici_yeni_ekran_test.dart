// test/yonetici_yeni_ekran_test.dart
//
// Yönetici yeniden tasarımının (2026-11) saf mantığı: model okuma, eski
// sunucuyla uyum, "en sakin saatler" hesabı ve dikkat maddesinin hedefleri.

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_ozetleri.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('Pano modelleri', () {
    test('eski sunucu: yeni alanlar yokken null/boş kalır', () {
      final data = DashboardData.fromJson(const {
        'gunun_ozeti': {'yeni_kayit': 2, 'doluluk_yuzdesi': 40},
        'tahsilat': {'toplam_tahsilat': '100'},
      });
      expect(data.dikkat, isNull);
      expect(data.gununOzeti.bugunTahsilat, isNull);
      expect(data.gununOzeti.bugunToplamDers, isNull);
      expect(data.tahsilat.sonGiris, isNull);
      expect(data.ders.oncekiDolulukYuzdesi, isNull);

      final rapor = RaporlarData.fromJson(const {});
      expect(rapor.ciroOzet, isNull);
      expect(rapor.urunKirilimi, isEmpty);
      expect(rapor.dolulukOzet, isNull);
    });

    test('yeni sunucu: dikkat, bugünkü kasa ve rapor özetleri okunur', () {
      final data = DashboardData.fromJson(const {
        'gunun_ozeti': {
          'bugun_toplam_ders': 18,
          'bugun_biten_ders': 11,
          'bugun_iptal_ders': 2,
          'bugun_tahsilat': '12400.00',
          'bugun_tahsilat_islem': 8,
          'bugun_son_giris': '2026-11-12T14:20:00+03:00',
        },
        'dikkat': [
          {
            'kod': 'gelmeyen_uye',
            'sayi': 9,
            'baslik': '9 üye 14 gündür derse gelmiyor',
            'ton': 'olumsuz',
            'filtre': {'durum': 'aktif', 'ders_once': '2026-10-29'},
          },
          {'kod': 'ekip', 'sayi': 3, 'baslik': 'x', 'kullanici_id': 7},
        ],
      });
      final ozet = data.gununOzeti;
      expect(ozet.bugunTahsilat, 12400);
      expect((ozet.bugunBitenDers, ozet.bugunToplamDers), (11, 18));
      expect(ozet.bugunSonGiris!.hour, 14);
      expect(data.dikkat!.first.filtre!['ders_once'], '2026-10-29');
      expect(data.dikkat!.last.kullaniciId, 7);

      final rapor = RaporlarData.fromJson(const {
        'ciro_ozet': {
          'toplam': '86500',
          'ders_sayisi': 120,
          'onceki_toplam': '77200',
          'degisim_yuzdesi': 12.0,
        },
        'tahsilat_ozet': {'toplam': '71300', 'islem_sayisi': 62},
        'urun_kirilimi': [
          {'ad': 'Özel ders', 'tutar': '52300', 'ders_sayisi': 60},
        ],
        'doluluk_ozet': {'yuzde': 64.2, 'onceki_yuzde': 61.0},
      });
      expect(rapor.ciroOzet!.degisimYuzdesi, 12.0);
      expect(rapor.tahsilatOzet!.sonGiris, isNull);
      expect(rapor.urunKirilimi.single.tutar, 52300);
      expect(rapor.dolulukOzet!.yuzde, 64.2);
    });
  });

  group('Yazım', () {
    test('tutar kuruşsuz ve binlik ayraçlı', () {
      expect(tutarYaz(12400.49), '12.400');
      expect(tlYaz(1234567), '1.234.567 TL');
      expect(tlYaz(0), '0 TL');
    });

    test('son giriş bugünse yalnız saat, değilse gün ve saat', () {
      final bugun = DateTime(2026, 11, 12, 18);
      expect(sonGirisYaz(DateTime(2026, 11, 12, 14, 20), bugun: bugun), '14:20');
      expect(
          sonGirisYaz(DateTime(2026, 11, 10, 9, 5), bugun: bugun), '10 Kas 09:05');
    });
  });

  group('En sakin saatler', () {
    DolulukHaritasi harita(Map<int, List<int>> satirlar) => DolulukHaritasi(
          donem: 'bu_hafta',
          gunler: const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
          saatler: satirlar.keys.toList(),
          hucreler: [
            for (final e in satirlar.entries)
              DolulukHaritasiSatir(saat: e.key, degerler: e.value),
          ],
          maxSayi: 9,
          toplamDers: 100,
        );

    test('saat toplamı en düşük olanlar; 09–21 dışı sayılmaz', () {
      final h = harita({
        7: [0, 0, 0, 0, 0, 0, 0], // aralık dışı
        10: [3, 3, 3, 3, 3, 3, 3],
        14: [0, 1, 0, 0, 1, 0, 0],
        15: [1, 0, 1, 1, 0, 1, 1],
        18: [5, 5, 5, 5, 5, 5, 5],
        22: [0, 0, 0, 0, 0, 0, 0], // aralık dışı
      });
      expect(SakinSaatlerNotu.sakinSaatler(h), [14, 15, 10]);
    });

    test('en sakin gün sütun toplamından', () {
      final h = harita({
        10: [3, 0, 3, 3, 3, 3, 3],
        18: [5, 1, 5, 5, 5, 5, 5],
      });
      expect(SakinSaatlerNotu.sakinGun(h), 1); // Salı
      expect(SakinSaatlerNotu.sakinGun(harita({})), isNull);
    });
  });

  group('Ekip modelleri', () {
    test('grup toplamı ve boş yanıt', () {
      final kisi = EkipKisi.fromJson(const {
        'id': 4,
        'ad_soyad': 'Ayşe Ofis',
        'islemler': [
          {'kod': 'ders_kaydi', 'grup': 'ders', 'etiket': 'Ders kaydı', 'sayi': 5},
          {
            'kod': 'ders_silme',
            'grup': 'ders',
            'etiket': 'Ders silme',
            'kritik': true,
            'sayi': 3,
          },
          {'kod': 'tahsilat', 'grup': 'para', 'etiket': 'Tahsilat', 'sayi': 2},
        ],
      });
      expect(kisi.grupToplami('ders'), 8);
      expect(kisi.grupToplami('uye'), 0);
      expect(kisi.bugunGiris, isNull);

      final bos = EkipData.fromJson(const {});
      expect(bos.kisiler, isEmpty);
      expect(bos.kisiSayisi, 0);
    });
  });

  group('Üyeler ön ayar isteği', () {
    test('özel süzgeç ön ayarın yerine geçer, sıralama varsayılan', () {
      final bugun = DateTime(2026, 11, 12);
      final filtre = UyeFiltreleri(
          durum: UyeDurumFiltresi.aktif, dersOnce: DateTime(2026, 10, 29));
      final istek = UyeOnAyarIstegi.filtre(filtre);
      expect(istek.filtreler(bugun), filtre);
      expect(istek.siralama, UyeSiralama.varsayilan);

      final borclu = UyeOnAyarIstegi(UyeOnAyari.borclu);
      expect(borclu.filtreler(bugun), UyeOnAyari.borclu.filtreler(bugun));
      expect(borclu.siralama, UyeOnAyari.borclu.siralama);
    });
  });
}
