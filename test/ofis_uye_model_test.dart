// Ofis üye modelleri: parse + "gizli alan sızmıyor" güvencesi.
//
// Backend zaten bakiye/para hareketi/mahrem profil alanlarını göndermiyor
// (tests/api/test_ofis_uclari.py). Buradaki testler mobil tarafın ikinci
// kilidini doğrular: yanıt bir şekilde o alanları taşısa bile modelde karşılığı
// olmadığı için ekrana çıkamaz.

import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend'in ASLA göndermemesi gereken alanlar; sızma testi bunları ekliyor.
const _sizdirilmisYanit = {
  'bakiye': -1850.0,
  'para_hareketleri': [
    {'id': 1, 'tutar': 500, 'hareket_turu': 'ALACAK'},
  ],
  'aylik_ozet': [
    {'yil': 2026, 'ay': 7, 'borc': 500, 'odeme': 0},
  ],
};

Map<String, dynamic> _listeSatiri({bool sizintiEkle = false}) => {
      'id': 7,
      'uye_no': 10407,
      'adi': 'Deniz',
      'soyadi': 'ARSLAN',
      'ad_soyad': 'Deniz ARSLAN',
      'telefon': '5551112233',
      'email': 'deniz@binay.fit',
      'seviye_rengi': 'Kirmizi',
      'seviye_rengi_hex': '#C2500B',
      'aktif_mi': true,
      'uye_tipi': 1,
      'uye_turu': 'Standart',
      'yas': 14,
      'son_ders_tarihi': '2026-07-23T10:00:00+03:00',
      if (sizintiEkle) 'bakiye': -1850.0,
    };

Map<String, dynamic> _detay({bool sizintiEkle = false}) => {
      'profil': {
        'id': 7,
        'uye_no': 10407,
        'adi': 'Deniz',
        'soyadi': 'ARSLAN',
        'ad_soyad': 'Deniz ARSLAN',
        'telefon': '5551112233',
        'yas': 14,
        'seviye_rengi': 'Kirmizi',
        'seviye_rengi_hex': '#C2500B',
        'uye_tipi': 1,
        'uye_turu': 'Standart',
        'aktif_mi': true,
        'sorumlu_hoca_adi': 'Ayşe YILMAZ',
        'kayit_tarihi': '2024-01-15',
        if (sizintiEkle) ...{
          'adres': 'Bir sokak No 5',
          'meslek': 'Öğrenci',
          'anne_telefon': '5559998877',
        },
      },
      'paketler': [
        {
          'id': 1,
          'urun_adi': '8 Ders Paketi',
          'urun_tipi': 'PAKET',
          'toplam_hak': 8,
          'kalan_hak': 3.0,
          'aktif_mi': true,
        },
      ],
      'yaklasan_dersler': [
        {
          'id': 11,
          'tarih': '25.07.2026',
          'saat': '10:00',
          'antrenor_adi': 'Ayşe YILMAZ',
          'kort_adi': 'Kort 1',
          'urun_adi': '8 Ders Paketi',
          'iptal_mi': false,
        },
      ],
      'gecmis_dersler': const [],
      if (sizintiEkle) ..._sizdirilmisYanit,
    };

void main() {
  group('OfisUyeListeItem', () {
    test('beklenen alanları parse eder', () {
      final uye = OfisUyeListeItem.fromJson(_listeSatiri());

      expect(uye.id, 7);
      expect(uye.uyeNo, 10407);
      expect(uye.adSoyad, 'Deniz ARSLAN');
      expect(uye.telefon, '5551112233');
      expect(uye.aktifMi, isTrue);
      // Sağ değer bakiye değil son ders tarihi.
      expect(uye.sonDersTarihi, isNotNull);
      expect(uye.sonDersTarihi!.hour, 10, reason: 'yerel saat korunmalı');
    });

    test('son ders yoksa null kalır', () {
      final ham = _listeSatiri()..remove('son_ders_tarihi');
      expect(OfisUyeListeItem.fromJson(ham).sonDersTarihi, isNull);
    });

    test('yanıtta bakiye gelse bile modele girmez', () {
      // Model bakiye alanı tanımlamıyor; derleme düzeyinde de erişilemez.
      // Test, sızıntılı yanıtın parse'ı bozmadığını doğrular.
      final uye = OfisUyeListeItem.fromJson(_listeSatiri(sizintiEkle: true));
      expect(uye.adSoyad, 'Deniz ARSLAN');
    });
  });

  group('OfisUyelerData', () {
    test('liste parse edilir', () {
      final data = OfisUyelerData.fromJson({
        'uyeler': [_listeSatiri(), _listeSatiri()],
        // Backend istatistik de gönderiyor; ofis ekranı kullanmıyor.
        'istatistikler': {'toplam_uye': 2},
      });
      expect(data.uyeler, hasLength(2));
    });

    test('boş yanıtta çökmez', () {
      expect(OfisUyelerData.fromJson(const {}).uyeler, isEmpty);
    });
  });

  group('OfisUyeDetayData', () {
    test('profil, paket ve dersler parse edilir', () {
      final detay = OfisUyeDetayData.fromJson(_detay());

      expect(detay.profil.adSoyad, 'Deniz ARSLAN');
      expect(detay.profil.sorumluHocaAdi, 'Ayşe YILMAZ');
      expect(detay.paketler, hasLength(1));
      expect(detay.paketler.first.kalanHak, 3.0);
      expect(detay.yaklasanDersler, hasLength(1));
      expect(detay.gecmisDersler, isEmpty);
    });

    test('sızıntılı yanıtta parasal bölümler modele girmez', () {
      final detay = OfisUyeDetayData.fromJson(_detay(sizintiEkle: true));

      // Sınıfın alanları: profil + paketler + iki ders listesi. Parasal
      // bölümlerin karşılığı yok, dolayısıyla veri kaybolur.
      expect(detay.profil.adSoyad, 'Deniz ARSLAN');
      expect(detay.paketler, hasLength(1));
    });

    test('boş yanıtta çökmez', () {
      final detay = OfisUyeDetayData.fromJson(const {});
      expect(detay.profil.adSoyad, '');
      expect(detay.paketler, isEmpty);
      expect(detay.yaklasanDersler, isEmpty);
    });
  });
}
