// test/support/duyuru_ornekleri.dart
//
// Yönetici/ofis duyuru ekranı testlerinin ortak örnek verisi.

/// Sunucunun döndürdüğü biçimde örnek okuma durumu.
Map<String, dynamic> okumaDurumuJson({
  String durum = 'yayinda',
  bool olculuyor = true,
}) =>
    {
      'duyuru': {
        'id': 7,
        'baslik': 'Kort bakımı',
        'alt_baslik': 'Dış kortlar kapalı',
        'icerik': 'Ayrıntı',
        'hedef_kitle': 'herkes',
        'popup_goster': true,
        'yayin_baslangic': '2026-10-03T09:00:00+03:00',
        'yayin_bitis': '2026-10-17T23:59:00+03:00',
        'durum': durum,
        'aktif_mi': true,
      },
      'ozet': {
        'olculuyor': olculuyor,
        'hedef_sayisi': olculuyor ? 142 : null,
        'goren_sayisi': olculuyor ? 54 : null,
        'toplam_goren': 3,
        'ana_sayfa': 2,
        'popup': 1,
        'detay_acan': 2,
        'kullanmayan_sayisi': 1,
      },
      'gordu': [
        {
          'hesap_id': 1,
          'profiller': [
            {'ad': 'Can YILMAZ', 'rol': 'uye', 'uye_id': 11},
            {'ad': 'Ece YILMAZ', 'rol': 'uye', 'uye_id': 12},
          ],
          'kaynak': 'popup',
          'detay_acildi': true,
          'zaman': '2026-10-12T14:32:00+03:00',
        },
        {
          'hesap_id': 2,
          'profiller': [
            {'ad': 'Murat Hoca', 'rol': 'antrenor', 'uye_id': null},
          ],
          'kaynak': 'carousel',
          'detay_acildi': true,
          'zaman': '2026-10-11T09:05:00+03:00',
        },
      ],
      'gormedi': [
        {
          'hesap_id': 3,
          'profiller': [
            {'ad': 'Ada DEMİR', 'rol': 'uye', 'uye_id': 13},
          ],
          'uygulama_kullaniyor': true,
        },
        {
          'hesap_id': 4,
          'profiller': [
            {'ad': 'İpek IŞIK', 'rol': 'uye', 'uye_id': 14},
          ],
          'uygulama_kullaniyor': false,
        },
      ],
      'web_duzenle_yolu': '/duyuru/7/duzenle/?isletme=1',
    };
