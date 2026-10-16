// Değerlendirme ekranı testleri için örnek veri — backend'in
// (api/etkinlik/degerlendirmeler.py) döndürdüğü biçimde.

import 'package:fitcall/models/1_common/degerlendirme_models.dart';

Map<String, dynamic> ornekDegerlendirmeJson({
  int id = 1,
  int puan = 5,
  String? yorum = 'Çok verimli geçti, servis çalışması harikaydı.',
  bool iptal = false,
  bool yardimci = false,
  int digerSayisi = 3,
}) =>
    {
      'id': id,
      'puan': puan,
      'yorum': yorum,
      'tarih': '2026-10-15T21:30:00+03:00',
      'degerlendiren': {
        'uye_id': 11,
        'ad_soyad': 'Deniz Ayşegül ARSLANOĞULLARI',
        'profil_fotografi': null,
      },
      'ders': {
        'id': 99,
        'baslangic_tarih_saat': '2026-10-15T10:00:00+03:00',
        'bitis_tarih_saat': '2026-10-15T11:00:00+03:00',
        'kort_adi': 'Kapalı Kort 1 (Uzun Adlı Tenis Alanı)',
        'antrenor_adi': 'Can Burak ALTINERoğulları',
        'yardimci_antrenor_adi': yardimci ? 'Ayşe Öğretmenoğlu TAN' : null,
        'urun_adi': 'Yetişkin Grup Dersi Paketi (10 ders, hafta sonu)',
        'seviye': 'Kirmizi',
        'iptal_mi': iptal,
        'katilimcilar': [
          {
            'uye_id': 11,
            'ad_soyad': 'Deniz Ayşegül ARSLANOĞULLARI',
            'profil_fotografi': null,
            'puan': puan,
            'katildi': true,
            'misafir': false,
            'degerlendiren_mi': true,
          },
          for (var i = 0; i < digerSayisi; i++)
            {
              'uye_id': i == digerSayisi - 1 ? null : 20 + i,
              'ad_soyad': 'Katılımcı $i Çok Uzun Soyadlıoğulları',
              'profil_fotografi': null,
              'puan': i == 0 ? 3 : null,
              'katildi': i == 1 ? false : true,
              'misafir': i == digerSayisi - 1,
              'degerlendiren_mi': false,
            },
        ],
      },
    };

DersDegerlendirmesi ornekDegerlendirme({
  int id = 1,
  int puan = 5,
  String? yorum = 'Çok verimli geçti, servis çalışması harikaydı.',
  bool iptal = false,
  bool yardimci = false,
  int digerSayisi = 3,
}) =>
    DersDegerlendirmesi.fromJson(ornekDegerlendirmeJson(
      id: id,
      puan: puan,
      yorum: yorum,
      iptal: iptal,
      yardimci: yardimci,
      digerSayisi: digerSayisi,
    ));
