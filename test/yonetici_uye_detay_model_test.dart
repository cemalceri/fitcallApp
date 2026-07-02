// Yönetici üye-detay ve doluluk-haritası modelleri için birim testleri.
// Backend JSON şekliyle parse doğruluğunu doğrular (Firebase gerektirmez).

import 'package:flutter_test/flutter_test.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';

void main() {
  group('UyeDetayData.fromJson', () {
    final json = {
      'profil': {
        'id': 12,
        'uye_no': 105,
        'adi': 'Ayşe',
        'soyadi': 'YILMAZ',
        'ad_soyad': 'Ayşe YILMAZ',
        'telefon': '5321234567',
        'email': 'ayse@example.com',
        'yas': 24,
        'seviye_rengi': 'Mavi',
        'seviye_rengi_hex': '#2196F3',
        'uye_tipi': 1,
        'uye_turu': 'Standart',
        'aktif_mi': true,
        'sorumlu_hoca_adi': 'Mehmet HOCA',
      },
      'bakiye': -1500.0,
      'para_hareketleri': [
        {
          'id': 1,
          'tarih': '2026-06-01',
          'hareket_turu': 'ALACAK',
          'hareket_turu_label': 'Alacak',
          'tutar': 1500.0,
          'borc_mu': true,
          'aciklama': 'Haziran aidatı',
          'urun_adi': 'Aylık Abonelik',
        }
      ],
      'aylik_ozet': [
        {
          'yil': 2026,
          'ay': 6,
          'borc': 1500.0,
          'odeme': 0.0,
          'acilis_bakiyesi': 0.0,
          'kapanis_bakiyesi': -1500.0,
        }
      ],
      'paketler': [
        {
          'id': 3,
          'urun_adi': '10 Ders Paketi',
          'urun_tipi': 'PAKET',
          'toplam_hak': 10,
          'kalan_hak': 7.0,
          'baslangic': '2026-05-01',
          'bitis': null,
          'aktif_mi': true,
        }
      ],
      'yaklasan_dersler': [
        {
          'id': 55,
          'tarih': '05.07.2026',
          'saat': '18:00',
          'antrenor_adi': 'Mehmet HOCA',
          'kort_adi': 'Kort 1',
          'urun_adi': 'Aylık Abonelik',
          'iptal_mi': false,
        }
      ],
      'gecmis_dersler': [],
    };

    test('temel alanları doğru parse eder', () {
      final data = UyeDetayData.fromJson(json);

      expect(data.profil.id, 12);
      expect(data.profil.adSoyad, 'Ayşe YILMAZ');
      expect(data.profil.telefon, '5321234567');
      expect(data.bakiye, -1500.0);
      expect(data.paraHareketleri.length, 1);
      expect(data.paraHareketleri.first.borcMu, true);
      expect(data.paraHareketleri.first.tutar, 1500.0);
      expect(data.aylikOzet.first.kapanisBakiyesi, -1500.0);
      expect(data.paketler.first.kalanHak, 7.0);
      expect(data.paketler.first.toplamHak, 10);
      expect(data.yaklasanDersler.first.saat, '18:00');
      expect(data.gecmisDersler, isEmpty);
    });

    test('seviye rengi hex koddan Color üretir', () {
      final data = UyeDetayData.fromJson(json);
      expect(data.profil.seviyeRenkColor.toARGB32(), 0xFF2196F3);
    });

    test('eksik/boş alanlarda güvenli varsayılanlar', () {
      final data = UyeDetayData.fromJson({});
      expect(data.profil.id, 0);
      expect(data.bakiye, 0);
      expect(data.paraHareketleri, isEmpty);
      expect(data.paketler, isEmpty);
    });
  });

  group('DolulukHaritasi.fromJson', () {
    test('ısı haritası matrisini doğru parse eder', () {
      final json = {
        'donem': 'bu_hafta',
        'gunler': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
        'saatler': [8, 9, 10],
        'hucreler': [
          {
            'saat': 8,
            'degerler': [0, 1, 2, 0, 3, 0, 0]
          },
          {
            'saat': 9,
            'degerler': [1, 1, 0, 4, 0, 2, 0]
          },
          {
            'saat': 10,
            'degerler': [0, 0, 0, 0, 0, 0, 0]
          },
        ],
        'max_sayi': 4,
        'toplam_ders': 20,
      };

      final harita = DolulukHaritasi.fromJson(json);

      expect(harita.gunler.length, 7);
      expect(harita.saatler, [8, 9, 10]);
      expect(harita.hucreler.length, 3);
      expect(harita.hucreler[1].saat, 9);
      expect(harita.hucreler[1].degerler[3], 4);
      expect(harita.maxSayi, 4);
      expect(harita.toplamDers, 20);
    });

    test('boş yanıtta güvenli varsayılanlar', () {
      final harita = DolulukHaritasi.fromJson({});
      expect(harita.hucreler, isEmpty);
      expect(harita.maxSayi, 0);
      expect(harita.saatler, isEmpty);
    });
  });
}
