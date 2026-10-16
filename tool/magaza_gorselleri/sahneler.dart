// Mağaza görsellerinin sahneleri: hangi sayfa, hangi oturum, hangi veri.

import 'dart:convert';

import 'package:fitcall/screens/2_uye/uye_kabuk.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_veri.dart';

typedef ApiYaniti = Object? Function(Uri url, Object? govde);

class Sahne {
  final String ad;
  final Map<String, String> Function() depo;
  final WidgetBuilder kur;
  final Map<String, ApiYaniti> api;

  /// Sayfa açıldıktan sonra yapılacaklar (sekme seçmek, detay açmak).
  final Future<void> Function(WidgetTester, GlobalKey<NavigatorState>)?
      hazirla;

  /// Durum çubuğunun rengi; verilmezse başlık bandının yazı rengi.
  final Color Function(ThemeData)? cubukRengi;

  const Sahne({
    required this.ad,
    required this.depo,
    required this.kur,
    this.api = const {},
    this.hazirla,
    this.cubukRengi,
  });
}

/// Her sahnede ortak uçlar (okunmamış bildirim sayısı, açılış popup'ları).
final Map<String, ApiYaniti> ortakApi = {
  'getUnreadNotificationCount': (_, __) => {'unread': 2},
  'getirEventAktif': (_, __) => null,
  'getPopupDuyuru': (_, __) => null,
};

/// Üyenin bu haftaki dersleri: bugün (akşamsa yarın) 18:00 ve iki gün sonra.
List<Map<String, Object?>> uyeHaftalikDersler() => [
      ders(
        baslangic: gunSaat(DateTime.now().hour < 17 ? 0 : 1, 18),
        kort: 2,
        katilimcilar: [uye, uyeler[0], uyeler[1], uyeler[2]],
      ),
      ders(
        baslangic: gunSaat(3, 10),
        dakika: 90,
        kort: 1,
        hoca: antrenorler[1],
        katilimcilar: [uye, uyeler[3]],
        urun: 'Yetişkin Özel',
      ),
    ];

final Map<String, ApiYaniti> uyeAnaSayfaApi = {
  'getHaftalikDersBilgilerim': (_, __) => uyeHaftalikDersler(),
  'getUyeHomeOzet': (_, __) => {
        'ozet': {'bakiye': 0, 'kalan_paket_hak': 2, 'aktif_telafi': 1},
        // Metinler backend'in ürettiği kartlarla aynı (api/uye/uye_home_ozet.py).
        'kartlar': [
          {
            'id': 1,
            'type': 'paket_bitiyor',
            'title': 'Paketiniz Bitmek Üzere',
            'subtitle': 'Yetişkin Grup paketinizde 2 ders hakkınız kaldı',
            'value': 2,
            'action_text': 'Paketlerim',
            'action_route': '/uyelikPaket',
          },
          {
            'id': 2,
            'type': 'degerlendirme_bekleyen',
            'title': 'Dersinizi Değerlendirin',
            'subtitle': 'Katıldığınız dersler için görüşünüzü paylaşın',
            'value': 1,
            'action_text': 'Değerlendir',
            'action_route': '/uyeGecmisDersler',
          },
        ],
      },
  'getUyeOdulDurumu': (_, __) => {
        'aktif': true,
        'odul_adi': 'Kahve',
        'ikon': 'kahve',
        'esik': 10,
        'gecerlilik_gun': 30,
        'sayac': 7,
        'kalan': 3,
        'hak_edildi': false,
      },
  'getAktifDuyurular': (_, __) => [
        {
          'id': 1,
          'baslik': 'Kış dönemi kayıtları başladı',
          'alt_baslik': 'Kapalı kortta yeni grup saatleri',
          'icerik': "Kış dönemi grup dersleri 1 Kasım'da başlıyor.",
          'onemli_mi': true,
          'yayin_baslangic': apiTarih(bugun),
          'olusturulma_zamani': apiTarih(bugun),
        },
        {
          'id': 2,
          'baslik': 'Hafta sonu kulüp turnuvası',
          'alt_baslik': 'Tüm seviyeler, kayıtlar resepsiyonda',
          'icerik': "Cumartesi 10:00'da başlıyor.",
          'yayin_baslangic': apiTarih(bugun),
          'olusturulma_zamani': apiTarih(bugun),
        },
      ],
};

String _iso(DateTime d) => d.toIso8601String().split('.').first;

Map<String, String> uyeOturumu() {
  final simdi = DateTime.now();
  final uye = {
    'id': 101,
    'adi': 'Deniz',
    'soyadi': 'Yılmaz',
    'cinsiyet': 'E',
    'is_active': true,
    'aktif_mi': true,
    'onaylandi_mi': true,
    'uye_no': 1042,
    'isletme': 1,
  };
  final user = {
    'id': 501,
    'password': '',
    'is_superuser': false,
    'username': 'deniz.yilmaz',
    'email': 'deniz.yilmaz@ornek.com',
    'first_name': 'Deniz',
    'last_name': 'Yılmaz',
    'is_active': true,
    'groups': <int>[],
    'user_permissions': <Object>[],
  };
  final profil = {
    'id': 9001,
    'user': user,
    'rol': 'uye',
    'uye': uye,
    'antrenor': null,
    'ana_hesap_mi': true,
    'isletme_id': 1,
    'isletme_adi': 'Binay Akademi',
  };
  return {
    'token': 'magaza-demo',
    'token_exp': _iso(simdi.add(const Duration(days: 30))),
    'uye': jsonEncode(uye),
    'user': jsonEncode(user),
    'user_id': '501',
    'ana_hesap_mi': 'true',
    'uye_profil': jsonEncode(profil),
    'kullanici_profiller': jsonEncode([profil]),
    'tema_modu': 'light',
    'tema_takim': 'binay',
  };
}

/// Bu haftanın tüm dersleri (takvim): geçmiş günler dahil.
List<Map<String, Object?>> uyeTakvimDersleri() {
  final pzt = haftaBasi.difference(bugun).inDays;
  return [
    ders(baslangic: gunSaat(pzt, 18), kort: 2,
        katilimcilar: [uye, uyeler[0], uyeler[1], uyeler[2]]),
    ders(baslangic: gunSaat(pzt + 2, 19), kort: 3, hoca: antrenorler[2],
        katilimcilar: [uye, uyeler[4], uyeler[5]], urun: 'Kondisyon'),
    ...uyeHaftalikDersler(),
  ];
}

/// Son 30 günün dersleri: katıldı / telafi / puanlanmış.
Map<String, Object?> gecmisDersler() {
  Map<String, Object?> g(int gunOnce, int saat, int kort, DemoKisi hoca,
      {bool katildi = true, int? puan, String urun = 'Yetişkin Grup'}) {
    final b = gunSaat(-gunOnce, saat);
    return {
      'id': 4000 + gunOnce,
      'baslangic_tarih_saat': apiTarih(b),
      'bitis_tarih_saat': apiTarih(b.add(const Duration(hours: 1))),
      'kort_adi': kortlar[kort],
      'antrenor_adi': hoca.adSoyad,
      'urun_adi': urun,
      'seviye': 'Orta',
      'iptal_mi': false,
      'katilim': {'katildi': katildi, 'plan_disi_mi': false},
      'ders_yapildi': true,
      'puanim': puan == null ? null : {'puan': puan},
    };
  }

  return {
    'baslangic': apiTarih(bugun.subtract(const Duration(days: 30))),
    'bitis': apiTarih(bugun),
    'dersler': [
      g(1, 19, 3, antrenorler[2], urun: 'Kondisyon'),
      g(3, 18, 2, antrenor, puan: 5),
      g(6, 10, 1, antrenorler[1], puan: 5, urun: 'Yetişkin Özel'),
      g(8, 18, 2, antrenor, puan: 4),
      g(10, 18, 2, antrenor, katildi: false),
      g(13, 10, 1, antrenorler[1], puan: 5, urun: 'Yetişkin Özel'),
      g(15, 18, 2, antrenor, puan: 5),
    ],
  };
}

List<Map<String, Object?>> bildirimListesi() {
  final simdi = DateTime.now();
  Map<String, Object?> b(int id, String tip, String baslik, String govde,
          Duration once, {bool okundu = true}) =>
      {
        'id': id,
        'notification_type': tip,
        'title': baslik,
        'body': govde,
        'action_type': 'NO_ACTION',
        'is_read': okundu,
        'timestamp': apiTarih(simdi.subtract(once)),
      };
  return [
    b(1, 'DERS_HATIRLATMA', '${simdi.hour < 17 ? 'Bugün' : 'Yarın'} dersin var',
        '18:00 · Kort 2 · Emre Kaya. Görüşmek üzere!',
        const Duration(minutes: 25), okundu: false),
    b(2, 'GENEL', 'Kış dönemi kayıtları başladı',
        'Kapalı kortta yeni grup saatleri açıldı.',
        const Duration(hours: 3), okundu: false),
    b(3, 'ODEME_ALINDI', 'Ödemeniz alındı',
        'Yetişkin Grup paketi için ödemeniz hesabınıza işlendi.',
        const Duration(days: 1, hours: 2)),
    b(4, 'PAKET_BITIYOR', 'Paketiniz bitmek üzere',
        'Yetişkin Grup paketinizde 2 ders hakkınız kaldı.',
        const Duration(days: 2, hours: 5)),
    b(5, 'TELAFI_KULLANILDI', 'Telafi dersiniz planlandı',
        'Cumartesi 10:00 Merkez Kort, Selin Aydın.',
        const Duration(days: 4)),
    b(6, 'ANTRENOR_DEGISIKLIGI', 'Antrenör değişikliği',
        'Çarşamba 19:00 dersinize Burak Demir girecek.',
        const Duration(days: 6)),
  ];
}

Future<void> _sekmeSec(WidgetTester tester, String etiket) async {
  await tester.tap(find.text(etiket).last);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _rotaAc(
    WidgetTester tester, GlobalKey<NavigatorState> nav, String rota) async {
  nav.currentState!.pushNamed(rota);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

final sahneler = <Sahne>[
  Sahne(
    ad: 'giris',
    depo: () => {'tema_modu': 'light', 'tema_takim': 'binay'},
    kur: (_) => const LoginPage(),
    cubukRengi: (t) => t.colorScheme.onSurface,
  ),
  Sahne(
    ad: 'uye_ana_sayfa',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: uyeAnaSayfaApi,
  ),
  Sahne(
    ad: 'uye_takvim',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: {
      ...uyeAnaSayfaApi,
      'getUyeDersProgrami': (_, __) => uyeTakvimDersleri(),
    },
    hazirla: (t, _) => _sekmeSec(t, 'Takvim'),
  ),
  Sahne(
    ad: 'qr_giris',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: {
      ...uyeAnaSayfaApi,
      'getirTesisSelfPass': (_, __) => {
            'kapsam': 'TESIS',
            'gecis_tipi': 'UYE',
            'code': 'BNY-7Q4K-2M9X-D101',
            'expires_at': apiTarih(DateTime.now().add(const Duration(hours: 23))),
            'iptal_mi': false,
            'label': uye.adSoyad,
          },
      'listeleTesisMisafirPass': (_, __) => <Object>[],
    },
    hazirla: (t, nav) => _rotaAc(t, nav, '/qrKodKayit'),
    cubukRengi: (t) => t.colorScheme.onSurface,
  ),
  Sahne(
    ad: 'gecmis_dersler',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: {...uyeAnaSayfaApi, 'getUyeGecmisDersler': (_, __) => gecmisDersler()},
    hazirla: (t, nav) => _rotaAc(t, nav, '/uyeGecmisDersler'),
  ),
  Sahne(
    ad: 'bildirimler',
    depo: uyeOturumu,
    kur: (_) => const UyeKabuk(),
    api: {
      ...uyeAnaSayfaApi,
      'getNotifications': (_, __) => bildirimListesi(),
      'setNotificationsRead': (_, __) => true,
    },
    hazirla: (t, nav) => _rotaAc(t, nav, '/bildirimler'),
  ),
];
