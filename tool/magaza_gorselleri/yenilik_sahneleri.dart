// "Neler yeni" dokümanının sahneleri: son sürümden bu yana gelen ekranlar.
// Mağaza setinden ayrı tutulur; çalıştırmak için:
//   flutter test tool/magaza_gorselleri/magaza_gorselleri_test.dart \
//     --dart-define=SAHNELER=yenilik --dart-define=CIHAZ=iphone_6.5

import 'dart:convert';

import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/2_uye/uye_kabuk.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_veri.dart';
import 'sahneler.dart';

Future<void> _bekle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _rota(
    WidgetTester tester, GlobalKey<NavigatorState> nav, String rota) async {
  nav.currentState!.pushNamed(rota);
  await _bekle(tester);
}

Object? _hepsi(Uri url, Object? govde) => null;

int? _ay(Uri url, Object? govde) {
  final g = govde is Map ? govde : const {};
  return int.tryParse('${url.queryParameters['ay'] ?? g['ay'] ?? ''}');
}

final _simdi = DateTime.now();
final _gecenAy = DateTime(_simdi.year, _simdi.month - 1, 1);

Map<String, Object?> _hareket(int id, String tur, num tutar, DateTime tarih,
        String aciklama, {String? odemeSekli}) =>
    {
      'id': id,
      'is_active': true,
      'is_deleted': false,
      'olusturulma_zamani': apiTarih(tarih),
      'guncellenme_zamani': apiTarih(tarih),
      'isletme': 1,
      'uye': uye.id,
      'hareket_turu': tur,
      'tutar': tutar,
      'odeme_sekli': odemeSekli,
      'tarih': apiTarih(tarih),
      'aciklama': aciklama,
    };

Map<String, Object?> _dekont(int id, String durum, String etiket, DateTime t,
        num tutar,
        {bool pdf = false, String? red}) =>
    {
      'id': id,
      'durum': durum,
      'durum_etiketi': etiket,
      'olusturulma_zamani': apiTarih(t),
      'beyan_tutar': '$tutar',
      if (durum == 'ISLENDI') 'islenen_tutar': tutar,
      if (durum == 'ISLENDI')
        'islenen_uyeler': [
          {'uye_id': uye.id, 'ad': uye.adSoyad},
        ],
      'pdf_mi': pdf,
      'dosya_adi': pdf ? 'dekont.pdf' : 'dekont.jpg',
      'red_nedeni': red,
    };

Map<String, Object?> dekontlarim() => {
      'dekontlar': [
        _dekont(3, 'BEKLIYOR', 'Kontrol bekliyor',
            _simdi.subtract(const Duration(hours: 2)), 4500, pdf: true),
        _dekont(2, 'REDDEDILDI', 'Reddedildi',
            _simdi.subtract(const Duration(days: 9)), 4500,
            red: 'Dekontta alıcı adı okunmuyor, lütfen PDF olarak yükleyin.'),
        _dekont(1, 'ISLENDI', 'İşlendi', _gecenAy.add(const Duration(days: 3)),
            4500),
      ],
      'bekleyen_sayisi': 1,
    };

final Map<String, ApiYaniti> _muhasebeApi = {
  ...uyeAnaSayfaApi,
  'getMuhasebeOzet': (_, __) => [
        {
          'yil': _simdi.year,
          'ay': _simdi.month,
          'borc': 4500,
          'odeme': 0,
          'acilis_bakiyesi': 0,
          'kapanis_bakiyesi': -4500,
        },
        {
          'yil': _gecenAy.year,
          'ay': _gecenAy.month,
          'borc': 4500,
          'odeme': 4500,
          'acilis_bakiyesi': 0,
          'kapanis_bakiyesi': 0,
        },
      ],
  'getParaHareketi': (url, govde) => _ay(url, govde) == _simdi.month
      ? [
          _hareket(12, 'ALACAK', 4500, DateTime(_simdi.year, _simdi.month, 1),
              'Yetişkin Grup — aylık aidat'),
        ]
      : [
          _hareket(11, 'ODEME', 4500, _gecenAy.add(const Duration(days: 4)),
              'Havale / EFT', odemeSekli: 'HAVALE'),
          _hareket(10, 'ALACAK', 4500, _gecenAy, 'Yetişkin Grup — aylık aidat'),
        ],
  'uyeDekontlarim': (_, __) => dekontlarim(),
  'uyeBankaHesaplari': (_, __) => {
        'hesaplar': [
          {
            'id': 1,
            'etiket': 'Şirket hesabı',
            'banka_adi': 'Örnek Bank',
            'alici_adi': 'Binay Spor Kulübü',
            'iban': 'TR330006100519786457841326',
            'iban_gruplu': 'TR33 0006 1005 1978 6457 8413 26',
            'karekod_url': '',
          },
          {
            'id': 2,
            'etiket': 'Aidat hesabı',
            'banka_adi': 'Diğer Bank',
            'alici_adi': 'Binay Spor Kulübü',
            'iban': 'TR320010009999901234567890',
            'iban_gruplu': 'TR32 0010 0099 9990 1234 5678 90',
            'karekod_url': '',
          },
        ],
      },
};

Map<String, String> antrenorOturumu() {
  final d = uyeOturumu();
  final hoca = {
    'id': antrenor.id,
    'adi': antrenor.adi,
    'soyadi': antrenor.soyadi,
    'is_active': true,
    'isletme': 1,
  };
  final profil = (jsonDecode(d['uye_profil']!) as Map<String, dynamic>)
    ..['rol'] = 'antrenor'
    ..['uye'] = null
    ..['antrenor'] = hoca;
  return {
    ...d..remove('uye'),
    'antrenor': jsonEncode(hoca),
    'uye_profil': jsonEncode(profil),
    'kullanici_profiller': jsonEncode([profil]),
  };
}

Map<String, Object?> _programDers(int id, int kort, DemoKisi hoca, String renk,
    int saat, int dakika, int sure, int kisi) {
  final b = gunSaat(0, saat, dakika);
  final s = b.add(Duration(minutes: sure));
  String hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  return {
    'id': id,
    'tarih': apiGun(b),
    'kort_id': kort,
    'kort_adi': kortlar[kort] ?? 'Kort $kort',
    'antrenor_id': hoca.id,
    'antrenor_adi': hoca.adSoyad,
    'antrenor_renk': renk,
    'baslangic_tarih_saat': apiTarih(b),
    'bitis_tarih_saat': apiTarih(s),
    'saat': hm(b),
    'bitis_saat': hm(s),
    'iptal_mi': false,
    'katilimci_sayisi': kisi,
    'katilimcilar': [],
  };
}

Map<String, Object?> antrenorProgrami() {
  const ben = '#FE5000', selin = '#00A9E0', burak = '#43B02A';
  final talepBas = gunSaat(0, 12);
  return {
    'hafta_baslangic': apiGun(haftaBasi),
    'hafta_bitis': apiGun(haftaBasi.add(const Duration(days: 6))),
    'bugun': apiGun(bugun),
    'gunler': const [],
    'kortlar': [
      for (final k in kortlar.entries)
        {'id': k.key, 'adi': k.value, 'sira': k.key, 'max_etkinlik_sayisi': 4},
    ],
    'dersler': [
      _programDers(1, 1, antrenor, ben, 9, 0, 60, 4),
      _programDers(2, 2, antrenorler[1], selin, 9, 0, 90, 2),
      _programDers(3, 3, antrenorler[2], burak, 10, 30, 60, 6),
      _programDers(4, 1, antrenor, ben, 11, 0, 60, 3),
      _programDers(5, 2, antrenorler[1], selin, 14, 0, 60, 4),
      _programDers(6, 1, antrenorler[2], burak, 16, 0, 90, 5),
      _programDers(7, 3, antrenor, ben, 17, 0, 60, 2),
      _programDers(8, 2, antrenor, ben, 18, 0, 60, 4),
      _programDers(9, 1, antrenorler[1], selin, 18, 0, 60, 3),
    ],
    'talepler': [
      {
        'id': 1,
        'kaynak': 'ANTRENOR',
        'durum': 'BEKLIYOR',
        'talep_eden_adi': antrenor.adSoyad,
        'antrenor_id': antrenor.id,
        'antrenor_adi': antrenor.adSoyad,
        'antrenor_renk': ben,
        'kort_id': 3,
        'kort_adi': kortlar[3],
        'tarih': apiGun(talepBas),
        'baslangic_tarih_saat': apiTarih(talepBas),
        'bitis_tarih_saat': apiTarih(talepBas.add(const Duration(hours: 1))),
        'saat': '12:00',
        'bitis_saat': '13:00',
        'aciklama': 'Ece Şahin ile ek özel ders.',
        'red_nedeni': null,
      },
    ],
    'benim_antrenor_id': antrenor.id,
  };
}

Map<String, String> yoneticiOturumu() {
  final d = uyeOturumu();
  final profil = (jsonDecode(d['uye_profil']!) as Map<String, dynamic>)
    ..['rol'] = 'yonetici'
    ..['uye'] = null
    ..['antrenor'] = null;
  return {
    ...d..remove('uye'),
    'uye_profil': jsonEncode(profil),
    'kullanici_profiller': jsonEncode([profil]),
  };
}

Map<String, Object?> _listeUyesi(DemoKisi k, int no, num bakiye,
    {bool kesin = false, int? kontrolGunOnce, int? odemeGunOnce, int dersGunOnce = 2}) {
  String? gun(int? g) => g == null ? null : apiGun(bugun.subtract(Duration(days: g)));
  return {
    'id': k.id,
    'uye_no': no,
    'adi': k.adi,
    'soyadi': k.soyadi,
    'ad_soyad': k.adSoyad,
    'telefon': '0532 000 00 ${no % 100}',
    'seviye_rengi': 'Turuncu',
    'seviye_rengi_hex': '#FE5000',
    'aktif_mi': true,
    'uye_tipi': 1,
    'uye_turu': 'Standart',
    'bakiye': bakiye,
    'son_ders_tarihi': apiTarih(gunSaat(-dersGunOnce, 18)),
    'borc_kesinlesti': kesin,
    'son_kontrol_tarihi': gun(kontrolGunOnce),
    'son_odeme_tarihi': gun(odemeGunOnce),
  };
}

Map<String, Object?> yoneticiUyeListesi() => {
      'istatistikler': {
        'toplam_uye': 214,
        'aktif_uye': 186,
        'pasif_uye': 28,
        'bu_ay_yeni_kayit': 9,
        'borclu_uye': 37,
      },
      'uyeler': [
        _listeUyesi(uyeler[4], 1051, -13500, kesin: true, kontrolGunOnce: 3, odemeGunOnce: 75),
        _listeUyesi(uyeler[1], 1023, -9000, kesin: true, kontrolGunOnce: 3, odemeGunOnce: 40),
        _listeUyesi(uyeler[6], 1078, -6750, odemeGunOnce: 36),
        _listeUyesi(uye, 1042, -4500, kesin: true, kontrolGunOnce: 1, odemeGunOnce: 33),
        _listeUyesi(uyeler[2], 1033, -4500, odemeGunOnce: 31),
        _listeUyesi(uyeler[8], 1090, -3200, odemeGunOnce: 12),
        _listeUyesi(uyeler[3], 1037, -2250, kontrolGunOnce: 10, odemeGunOnce: 8),
        _listeUyesi(uyeler[9], 1101, -1500, odemeGunOnce: 5),
      ],
      'toplam_sayfa': 5,
      'mevcut_sayfa': 1,
      'toplam_uye': 37,
      'filtre_ozeti': {'uye_sayisi': 37, 'toplam_borc': 48200},
    };

final Map<String, ApiYaniti> _yoneticiUyeApi = {
  'yoneticiUyeler': (_, govde) => (govde is Map && govde['sadece_sayi'] == true)
      ? {'toplam_uye': 37}
      : yoneticiUyeListesi(),
};

Widget _yoneticiUyeler(BuildContext _) => Scaffold(
      body: UyelerPage(
        onAyarIstegi: ValueNotifier(UyeOnAyarIstegi(UyeOnAyari.borclu)),
      ),
    );

final yoneticiSahneleri = <Sahne>[
  Sahne(
    ad: 'yonetici_uyeler',
    depo: yoneticiOturumu,
    kur: _yoneticiUyeler,
    api: _yoneticiUyeApi,
  ),
  Sahne(
    ad: 'yonetici_uye_filtre',
    depo: yoneticiOturumu,
    kur: _yoneticiUyeler,
    api: _yoneticiUyeApi,
    hazirla: (t, _) async {
      await t.tap(find.textContaining('Filtrele').first);
      await _bekle(t);
    },
  ),
  Sahne(
    ad: 'yonetici_uye_siralama',
    depo: yoneticiOturumu,
    kur: _yoneticiUyeler,
    api: _yoneticiUyeApi,
    hazirla: (t, _) async {
      await t.tap(find.textContaining('Sırala').first);
      await _bekle(t);
    },
  ),
];

final yenilikSahneleri = <Sahne>[
  Sahne(
    ad: 'hesap_ozeti',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: _muhasebeApi,
    hazirla: (t, nav) => _rota(t, nav, '/muhasebe'),
  ),
  Sahne(
    ad: 'havale_eft_hesaplar',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: _muhasebeApi,
    hazirla: (t, nav) => _rota(t, nav, '/havaleEft'),
  ),
  Sahne(
    ad: 'dekontlarim',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: _muhasebeApi,
    hazirla: (t, nav) async {
      await _rota(t, nav, '/havaleEft');
      await t.tap(find.textContaining('Dekontlarım').last);
      await _bekle(t);
    },
  ),
  Sahne(
    ad: 'renk_temasi',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: {...uyeAnaSayfaApi, 'getUyeProfil': _hepsi},
    hazirla: (t, nav) async {
      await _rota(t, nav, '/ayarlar');
      final hedef = find.text('Renk teması');
      if (hedef.evaluate().isNotEmpty) {
        await t.ensureVisible(hedef.first);
        await _bekle(t);
      }
    },
  ),
  Sahne(
    ad: 'antrenor_tum_program',
    depo: antrenorOturumu,
    kur: (_) => const SizedBox.shrink(),
    api: {'antrenorHaftalikProgram': (_, __) => antrenorProgrami()},
    hazirla: (t, nav) => _rota(t, nav, '/antrenorTumProgram'),
  ),
  ...yoneticiSahneleri,
];
