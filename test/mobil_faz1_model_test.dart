// test/mobil_faz1_model_test.dart
// Mobil Faz 1 modellerinin JSON parse testleri:
// UyeHomeOzet, GecmisDers, GunlukOzet, OgrenciDetay, CalismaGunleri, HomeCard.

import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:fitcall/models/2_uye/uye_home_ozet_model.dart';
import 'package:fitcall/models/3_antrenor/calisma_saatleri_model.dart';
import 'package:fitcall/models/3_antrenor/gunluk_ozet_model.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/models/3_antrenor/ogrenci_detay_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UyeHomeOzetModel', () {
    test('tam veri parse edilir', () {
      final json = {
        'ozet': {
          'bakiye': -1250.5,
          'kalan_paket_hak': 3.0,
          'aktif_telafi': 2,
        },
        'kartlar': [
          {
            'id': 0,
            'type': 'borc',
            'title': 'Ödenmemiş Borcunuz Var',
            'subtitle': 'Güncel borcunuz 1.250 TL',
            'value': 1250,
            'action_text': 'Hesabım',
            'action_route': '/muhasebe',
            'action_params': null,
            'priority': 90,
            'dismissible': false,
            'olusturulma_zamani': null,
            'expires_at': null,
          },
        ],
      };

      final model = UyeHomeOzetModel.fromJson(json);
      expect(model.ozet.bakiye, -1250.5);
      expect(model.ozet.kalanPaketHak, 3.0);
      expect(model.ozet.aktifTelafi, 2);
      expect(model.kartlar.length, 1);
      expect(model.kartlar.first.type, HomeCardType.borc);
      expect(model.kartlar.first.actionRoute, '/muhasebe');
      expect(model.kartlar.first.dismissible, false);
    });

    test('eksik/boş veri varsayılanlara düşer', () {
      final model = UyeHomeOzetModel.fromJson(const {});
      expect(model.ozet.bakiye, 0.0);
      expect(model.ozet.kalanPaketHak, isNull);
      expect(model.ozet.aktifTelafi, 0);
      expect(model.kartlar, isEmpty);
    });
  });

  group('HomeCardModel yeni üye tipleri', () {
    HomeCardModel kart(String tip) =>
        HomeCardModel.fromJson({'id': 1, 'type': tip, 'title': '', 'subtitle': ''});

    test('üye tipleri doğru enum değerine çözülür', () {
      expect(kart('teyit_bekleyen').type, HomeCardType.teyitBekleyen);
      expect(kart('borc').type, HomeCardType.borc);
      expect(kart('paket_bitiyor').type, HomeCardType.paketBitiyor);
      expect(kart('telafi_sure_yaklasan').type, HomeCardType.telafiSureYaklasan);
      expect(
          kart('degerlendirme_bekleyen').type, HomeCardType.degerlendirmeBekleyen);
    });

    test('bilinmeyen tip info olarak parse edilir (geriye uyumluluk)', () {
      expect(kart('bilinmeyen_yeni_tip').type, HomeCardType.info);
    });

    test('her tipin renk ve ikonu tanımlı', () {
      for (final tip in HomeCardType.values) {
        final model = HomeCardModel(
            id: 1, type: tip, title: 't', subtitle: 's');
        expect(model.color, isNotNull);
        expect(model.icon, isNotNull);
      }
    });
  });

  group('GecmisDersModel', () {
    test('katılım, sonuç ve puan parse edilir', () {
      final json = {
        'baslangic': '2026-06-01T00:00:00+03:00',
        'bitis': '2026-07-01T00:00:00+03:00',
        'dersler': [
          {
            'id': 75255,
            'baslangic_tarih_saat': '2026-07-01T16:30:00+03:00',
            'bitis_tarih_saat': '2026-07-01T17:30:00+03:00',
            'kort_adi': 'Tekli Kapalı',
            'antrenor_adi': 'BURAK AKTAŞ',
            'urun_adi': 'Kırmızı-aidat-tekli',
            'seviye': 'Kirmizi',
            'iptal_mi': false,
            'katilim': {
              'katildi': true,
              'plan_disi_mi': true,
              'not_metni': 'Telafi dersi',
            },
            'ders_yapildi': true,
            'puanim': {'puan': 4, 'yorum': 'iyi'},
          },
          {
            'id': 2,
            'baslangic_tarih_saat': '2026-06-25T17:30:00+03:00',
            'bitis_tarih_saat': '2026-06-25T18:30:00+03:00',
            'kort_adi': '',
            'antrenor_adi': '',
            'urun_adi': '',
            'seviye': '',
            'iptal_mi': true,
            'iptal_eden_adi': ' Ayşe Yılmaz ',
            'katilim': null,
            'ders_yapildi': null,
            'puanim': null,
          },
        ],
      };

      final res = GecmisDerslerResponse.fromJson(json);
      expect(res.dersler.length, 2);

      final ilk = res.dersler.first;
      expect(ilk.id, 75255);
      expect(ilk.katilim?.katildi, true);
      expect(ilk.katilim?.planDisiMi, true);
      expect(ilk.katilim?.notMetni, 'Telafi dersi');
      expect(ilk.dersYapildi, true);
      expect(ilk.puanim?.puan, 4);

      // iptal_eden_adi göndermeyen (eski) cevapta alan boş kalmalı
      expect(ilk.iptalEdenAdi, '');

      final ikinci = res.dersler[1];
      expect(ikinci.iptalMi, true);
      expect(ikinci.iptalEdenAdi, 'Ayşe Yılmaz');
      expect(ikinci.katilim, isNull);
      expect(ikinci.dersYapildi, isNull);
      expect(ikinci.puanim, isNull);
    });
  });

  group('GunlukOzetModel', () {
    test('kokpit alanları parse edilir', () {
      final json = {
        'tarih': '2026-07-02',
        'ders_sayisi': 8,
        'iptal': 2,
        'tamamlanan': 5,
        'kalan': 3,
        'ogrenci_sayisi': 9,
        'ilk_ders': '07:30',
        'son_ders': '20:30',
        'eksik_yoklama': 2,
        'eksik_yoklama_dersler': [
          {'id': 75553, 'saat': '07:30', 'kort_adi': 'Üye Kortu'},
          {'id': 74846, 'saat': '08:30', 'kort_adi': 'Üye Kortu'},
        ],
        'eksik_yoklama_gecmis': 5,
      };

      final model = GunlukOzetModel.fromJson(json);
      expect(model.dersSayisi, 8);
      expect(model.iptal, 2);
      expect(model.kalan, 3);
      expect(model.ogrenciSayisi, 9);
      expect(model.ilkDers, '07:30');
      expect(model.eksikYoklama, 2);
      expect(model.eksikYoklamaDersler.length, 2);
      expect(model.eksikYoklamaDersler.first.id, 75553);
      expect(model.eksikYoklamaGecmis, 5);
    });

    test('boş gün: null ilk/son ders', () {
      final model = GunlukOzetModel.fromJson(const {
        'tarih': '2026-07-02',
        'ders_sayisi': 0,
        'iptal': 0,
        'tamamlanan': 0,
        'kalan': 0,
        'ogrenci_sayisi': 0,
        'ilk_ders': null,
        'son_ders': null,
        'eksik_yoklama': 0,
        'eksik_yoklama_dersler': [],
        'eksik_yoklama_gecmis': 0,
      });
      expect(model.ilkDers, isNull);
      expect(model.eksikYoklamaDersler, isEmpty);
    });
  });

  group('OgrenciDetayModel', () {
    test('tam detay parse edilir', () {
      final json = {
        'profil': {
          'id': 935,
          'adi': 'Nergis',
          'soyadi': 'TAĞI',
          'uye_no': 361,
          'telefon': '5457608257',
          'email': 'a@b.com',
          'dogum_tarihi': '2003-09-25',
          'cinsiyet': 'Kadın',
          'seviye_rengi': 'Yetiskin',
          'program_tercihi': 'Özel Ders',
          'aktif_mi': true,
          'sorumlu_hocasi_miyim': false,
        },
        'veli': {
          'acil_durum_kisi': 'Ali',
          'acil_durum_telefon': '5551112233',
          'anne_adi_soyadi': null,
          'anne_telefon': null,
          'baba_adi_soyadi': null,
          'baba_telefon': null,
        },
        'istatistik': {
          'pencere_gun': 90,
          'planlanan_ders': 4,
          'yoklama_girilen': 0,
          'katildigi_ders': 0,
          'katilim_yuzdesi': null,
          'son_katilim_tarihi': null,
        },
        'paketler': [
          {
            'id': 1,
            'urun_adi': 'Paket 8',
            'toplam_hak': 8,
            'kalan_hak': 2.0,
            'baslangic': '2026-05-01',
            'bitis': null,
          },
        ],
        'aktif_telafi': 1,
        'son_katilimlar': [
          {
            'etkinlik_id': 10,
            'tarih': '2026-06-25T17:30:00+03:00',
            'kort_adi': 'Kort 1',
            'katildi': true,
            'plan_disi_mi': false,
            'not_metni': null,
          },
        ],
        'gorusme_notlari': [
          {
            'gorusen_kisi': 'Ofis',
            'gorusme_tarihi': '2026-06-01',
            'notu': 'Seviye ilerlemesi iyi',
          },
        ],
      };

      final model = OgrenciDetayModel.fromJson(json);
      expect(model.profil.adSoyad, 'Nergis TAĞI');
      expect(model.profil.sorumluHocasiMiyim, false);
      expect(model.veli.bosMu, false);
      expect(model.istatistik.katilimYuzdesi, isNull,
          reason: 'Yoklama yoksa yüzde hesaplanmamalı (yanlış oran gösterme)');
      expect(model.paketler.first.kalanHak, 2.0);
      expect(model.aktifTelafi, 1);
      expect(model.sonKatilimlar.first.katildi, true);
      expect(model.gorusmeNotlari.first.gorusenKisi, 'Ofis');
    });

    test('boş veri çökmez', () {
      final model = OgrenciDetayModel.fromJson(const {});
      expect(model.profil.id, 0);
      expect(model.veli.bosMu, true);
      expect(model.paketler, isEmpty);
    });
  });

  group('CalismaGunleriResponse', () {
    test('günler ve kayıtlar parse edilir', () {
      final json = {
        'gunler': [
          {'gun_id': 1, 'gun_adi': 'Pazartesi', 'haftanin_gunu': 0},
          {'gun_id': 2, 'gun_adi': 'Salı', 'haftanin_gunu': 1},
        ],
        'calisma_saatleri': [
          {
            'id': 5,
            'gun_id': 1,
            'gun_adi': 'Pazartesi',
            'haftanin_gunu': 0,
            'baslangic_saat': '09:00',
            'bitis_saat': '18:00',
          },
        ],
      };

      final model = CalismaGunleriResponse.fromJson(json);
      expect(model.gunler.length, 2);
      expect(model.calismaSaatleri.length, 1);
      expect(model.calismaSaatleri.first.baslangicSaat, '09:00');

      final setJson = model.calismaSaatleri.first.toSetJson();
      expect(setJson,
          {'gun_id': 1, 'baslangic_saat': '09:00', 'bitis_saat': '18:00'});
    });
  });
}
