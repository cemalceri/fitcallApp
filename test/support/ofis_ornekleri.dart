// Ofis Ana Sayfa / Dersler / plan dışı testlerinin örnek verileri. JSON
// anahtarları backend'in (api/ofis/ders_yonetimi.py + ders_yonetimi_service)
// döndürdüğüyle aynı; model ayrıştırması da böylece sınanmış olur.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';

String _iso(DateTime kulupSaati) => '${formatApiTarih(kulupSaati)}+03:00';

Map<String, dynamic> katilimciJson(
  int id,
  String ad, {
  String? teyit,
  String? katilim,
  bool planDisi = false,
  String? paket,
}) =>
    {
      'uye_id': id,
      'ad_soyad': ad,
      'teyit_durum': teyit,
      'teyit_aciklama':
          teyit == 'katilmayacak' ? 'Hastayım, gelemeyeceğim' : null,
      'katilim_durum': katilim,
      'plan_disi_mi': planDisi,
      'paket_dusum_btn': paket,
    };

/// [saatSonra] negatifse geçmiş ders.
Map<String, dynamic> dersJson({
  int id = 1,
  int saatSonra = -3,
  bool iptal = false,
  bool? yonetici,
  bool? antrenor,
  bool yardimci = false,
  int planDisiBekleyen = 0,
  List<Map<String, dynamic>>? katilimcilar,
}) {
  final bas = simdiKulup().add(Duration(hours: saatSonra));
  return {
    'id': id,
    'baglam': iptal ? 'iptal' : (saatSonra > 0 ? 'gelecek' : 'gecmis'),
    'kort_adi': 'Kapalı Kort Uzun Adlı Tenis Alanı $id',
    'baslangic': _iso(bas),
    'bitis': _iso(bas.add(const Duration(hours: 1))),
    'urun_adi': 'Özel Ders Paketi (10 ders) Hafta Sonu',
    'antrenor': 'Ayşe Yılmaz Öğretmenoğulları',
    'yardimci_antrenor': yardimci ? 'Mert Kandemiroğlu' : null,
    'iptal_mi': iptal,
    'iptal_sebebi': iptal ? 'Hava koşulları' : null,
    'iptal_aciklamasi': iptal ? 'Yoğun yağış nedeniyle kortlar kapalı' : null,
    'iptal_eden': iptal ? 'Ofis Çalışanı' : null,
    'yonetici_tamamlandi': yonetici,
    'yonetici_neden': yonetici == false ? 'Hava şartları' : null,
    'antrenor_tamamlandi': antrenor,
    'antrenor_neden': antrenor == false ? 'Öğrenci gelmedi' : null,
    'hakedis': null,
    'yardimci_hakedis': yardimci ? true : null,
    'plan_disi_bekleyen': planDisiBekleyen,
    'katilimcilar': katilimcilar ??
        [
          katilimciJson(10, 'Deniz Ayşegül Arslanoğulları',
              katilim: 'katildi', paket: 'dus'),
          katilimciJson(11, 'Ece Yılmaz',
              katilim: 'katilmadi', paket: 'geri_al'),
          katilimciJson(12, 'Misafir Olmayan Plan Dışı Üye',
              katilim: 'katildi', planDisi: true),
        ],
  };
}

DersYonetimiGun ornekGun() => DersYonetimiGun.fromJson({
      'tarih': formatApiGun(bugunKulup()),
      'dersler': [
        dersJson(id: 1, antrenor: true, planDisiBekleyen: 2),
        dersJson(id: 2, antrenor: false),
        dersJson(id: 3, yonetici: true, antrenor: true, yardimci: true),
        dersJson(id: 4, iptal: true),
        dersJson(id: 5, saatSonra: 20, katilimcilar: [
          katilimciJson(20, 'Cevap Vermeyen Üye', teyit: 'bekliyor'),
          katilimciJson(21, 'Bildirim Gitmeyen Üye', teyit: 'bildirim_yok'),
          katilimciJson(22, 'Katılacak Üye', teyit: 'katilacak'),
          katilimciJson(23, 'Gelemeyecek Üye', teyit: 'katilmayacak'),
        ]),
      ],
      'yapilmadi_nedenleri': [
        {'kod': 'YMD_OGRENCI', 'etiket': 'Öğrenci gelmedi'},
        {'kod': 'YMD_HAVA', 'etiket': 'Hava şartları'},
      ],
    });

OfisBekleyenIsler ornekBekleyenIsler({bool bos = false}) =>
    OfisBekleyenIsler.fromJson({
      'bugun': {'ders': 42, 'iptal': bos ? 0 : 3, 'onay_bekleyen': bos ? 0 : 7},
      'onay_bekleyen': {
        'toplam': bos ? 0 : 137,
        'antrenor_onayli': bos ? 0 : 96,
        'pencere_gun': 60,
        'gunler': bos
            ? []
            : [
                {
                  'tarih': formatApiGun(bugunKulup()),
                  'bekleyen': 7,
                  'antrenor_onayli': 5
                },
                {
                  'tarih': formatApiGun(
                      bugunKulup().subtract(const Duration(days: 1))),
                  'bekleyen': 30,
                  'antrenor_onayli': 0
                },
              ],
      },
      'plan_disi_bekleyen': {'kisi': bos ? 0 : 5, 'ders': bos ? 0 : 3},
      'ders_kayit_talebi_bekleyen': bos ? 0 : 2,
      'teyit_bekleyen': {
        'kisi': bos ? 0 : 12,
        'ders': bos ? 0 : 6,
        'gunler': bos
            ? []
            : [
                {'tarih': formatApiGun(bugunKulup()), 'kisi': 5},
                {
                  'tarih':
                      formatApiGun(bugunKulup().add(const Duration(days: 1))),
                  'kisi': 7
                },
              ],
      },
    });

List<PlanDisiDers> ornekPlanDisi() => [
      PlanDisiDers.fromJson({
        'etkinlik_id': 1,
        'baslangic': _iso(simdiKulup().subtract(const Duration(hours: 5))),
        'kort': 'Kapalı Kort Uzun Adlı Tenis Alanı',
        'antrenor': 'Ayşe Yılmaz Öğretmenoğulları',
        'urun': 'Özel Ders Paketi (10 ders) Hafta Sonu',
        'kisiler': [
          {
            'tur': 'misafir',
            'id': 3,
            'ad_soyad': 'Mehmet Kaya Uzunsoyadlıoğlu',
            'not_metni': "Ayşe'nin arkadaşı, deneme dersi"
          },
          {'tur': 'uye', 'id': 12, 'ad_soyad': 'Deniz Yılmaz', 'uye_id': 7},
        ],
      }),
    ];

PlanDisiSecenekler ornekSecenekler() => PlanDisiSecenekler.fromJson({
      'kisi': 'Mehmet Kaya Uzunsoyadlıoğlu',
      'mevcut_karar': 'BEKLIYOR',
      'adaylar': [
        {
          'uye_id': 1,
          'ad_soyad': 'Misafir havuzu',
          'varsayilan': true,
          'paketler': []
        },
        {
          'uye_id': 7,
          'ad_soyad': 'Deniz Ayşegül Arslanoğulları',
          'varsayilan': false,
          'paketler': [
            {
              'id': 70,
              'ad': '10 ders paketi',
              'etiket': '10 ders paketi — 4 hak kaldı'
            },
          ],
        },
      ],
    });

/// Ders kayıt talebi örneği (backend talep_sozlugu biçimi). Uzun not ve uzun
/// ad taşma testleri için bilerek seçildi.
Map<String, dynamic> ornekTalepJson({
  int id = 1,
  String tarih = '2026-07-23',
  String saat = '17:30',
  String bitisSaat = '18:30',
  int kortId = 2,
  String aciklama =
      "Kort 3 sulandı, Ali Kaya ve Ece Turan ile Kort 5'e geçtik; "
          'kendi 17:00 grubum bugün yapılmadı.',
}) =>
    {
      'id': id,
      'kaynak': 'ANTRENOR',
      'durum': 'BEKLIYOR',
      'talep_eden_adi': 'Mehmet Hocaoğlu Uzunsoyadlı',
      'antrenor_id': 1,
      'antrenor_adi': 'Mehmet Hocaoğlu Uzunsoyadlı',
      'antrenor_renk': '#4F7FE0',
      'kort_id': kortId,
      'kort_adi': 'Kapalı Kort $kortId',
      'tarih': tarih,
      'baslangic_tarih_saat': '${tarih}T$saat:00+03:00',
      'bitis_tarih_saat': '${tarih}T$bitisSaat:00+03:00',
      'saat': saat,
      'bitis_saat': bitisSaat,
      'aciklama': aciklama,
      'red_nedeni': null,
      'olusturulma_zamani': '${tarih}T16:05:00+03:00',
      'olusan_etkinlik_id': null,
    };

DersKayitTalebi ornekTalep({int id = 1, String saat = '17:30'}) =>
    DersKayitTalebi.fromJson(ornekTalepJson(id: id, saat: saat));
