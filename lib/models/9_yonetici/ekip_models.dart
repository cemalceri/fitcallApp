// lib/models/9_yonetici/ekip_models.dart
//
// Yönetici "Ekip" takibi: ofis çalışanı kim, ne yaptı, kaçta geldi; altında
// antrenörlerin ders ve yoklama sayıları.
// Turnike yalnız girişi okutur; çıkış saati ve süre yoktur.

import 'package:fitcall/common/tarih_util.dart';

/// Bir işlem türünün sayısı ("Ders kaydı · 5").
class EkipIslem {
  final String kod;

  /// ders | para | uye | diger
  final String grup;
  final String etiket;

  /// Silme ve para işlemleri: ekranda vurgulu.
  final bool kritik;
  final int sayi;

  const EkipIslem({
    required this.kod,
    required this.grup,
    required this.etiket,
    required this.kritik,
    required this.sayi,
  });

  factory EkipIslem.fromJson(Map<String, dynamic> json) => EkipIslem(
        kod: json['kod']?.toString() ?? '',
        grup: json['grup']?.toString() ?? 'diger',
        etiket: json['etiket']?.toString() ?? '',
        kritik: json['kritik'] == true,
        sayi: json['sayi'] ?? 0,
      );
}

class EkipGrubu {
  final String kod;
  final String etiket;

  const EkipGrubu({required this.kod, required this.etiket});

  factory EkipGrubu.fromJson(Map<String, dynamic> json) => EkipGrubu(
        kod: json['kod']?.toString() ?? '',
        etiket: json['etiket']?.toString() ?? '',
      );

  static List<EkipGrubu> liste(dynamic json) =>
      (json as List? ?? []).map((e) => EkipGrubu.fromJson(e)).toList();
}

List<EkipIslem> _islemler(dynamic json) =>
    (json as List? ?? []).map((e) => EkipIslem.fromJson(e)).toList();

/// Ekip listesindeki bir çalışan.
class EkipKisi {
  final int id;
  final String adSoyad;

  /// Bugünün ilk turnike girişi; okutmadıysa null.
  final DateTime? bugunGiris;
  final int toplamIslem;
  final int kritikIslem;
  final List<EkipIslem> islemler;

  const EkipKisi({
    required this.id,
    required this.adSoyad,
    required this.toplamIslem,
    required this.kritikIslem,
    required this.islemler,
    this.bugunGiris,
  });

  factory EkipKisi.fromJson(Map<String, dynamic> json) => EkipKisi(
        id: json['id'] ?? 0,
        adSoyad: json['ad_soyad']?.toString() ?? '',
        bugunGiris: parseApiTarih(json['bugun_giris']),
        toplamIslem: json['toplam_islem'] ?? 0,
        kritikIslem: json['kritik_islem'] ?? 0,
        islemler: _islemler(json['islemler']),
      );

  /// Bir grubun toplam işlem sayısı.
  int grupToplami(String grup) => islemler
      .where((i) => i.grup == grup)
      .fold(0, (toplam, i) => toplam + i.sayi);
}

/// Ekip sayfasında ofisin altındaki antrenör satırı (seçili dönem).
class EkipAntrenor {
  final int id;
  final String adSoyad;

  /// Bugünün ilk turnike girişi; okutmadıysa null.
  final DateTime? bugunGiris;

  /// Saati bitmiş, iptal edilmemiş ve "yapılmadı" denmemiş ders.
  final int dersSayisi;

  /// Antrenörün "ders yapılmadı" dediği ders.
  final int yapilmadi;
  final int yoklamaGirilen;
  final int yoklamaBekleyen;

  const EkipAntrenor({
    required this.id,
    required this.adSoyad,
    required this.dersSayisi,
    required this.yapilmadi,
    required this.yoklamaGirilen,
    required this.yoklamaBekleyen,
    this.bugunGiris,
  });

  factory EkipAntrenor.fromJson(Map<String, dynamic> json) => EkipAntrenor(
        id: json['id'] ?? 0,
        adSoyad: json['ad_soyad']?.toString() ?? '',
        bugunGiris: parseApiTarih(json['bugun_giris']),
        dersSayisi: json['ders_sayisi'] ?? 0,
        yapilmadi: json['yapilmadi'] ?? 0,
        yoklamaGirilen: json['yoklama_girilen'] ?? 0,
        yoklamaBekleyen: json['yoklama_bekleyen'] ?? 0,
      );
}

class EkipData {
  final DateTime? baslangic;
  final DateTime? bitis;
  final List<EkipGrubu> gruplar;
  final int kisiSayisi;
  final int gelenSayisi;
  final int toplamIslem;
  final int kritikIslem;
  final List<EkipKisi> kisiler;

  /// Eski sunucu göndermez: boş liste, bölüm çizilmez.
  final List<EkipAntrenor> antrenorler;

  const EkipData({
    required this.gruplar,
    required this.kisiSayisi,
    required this.gelenSayisi,
    required this.toplamIslem,
    required this.kritikIslem,
    required this.kisiler,
    this.antrenorler = const [],
    this.baslangic,
    this.bitis,
  });

  factory EkipData.fromJson(Map<String, dynamic> json) {
    final ozet = json['ozet'] as Map? ?? const {};
    return EkipData(
      baslangic: parseApiTarih(json['baslangic']),
      bitis: parseApiTarih(json['bitis']),
      gruplar: EkipGrubu.liste(json['gruplar']),
      kisiSayisi: ozet['kisi_sayisi'] ?? 0,
      gelenSayisi: ozet['gelen_sayisi'] ?? 0,
      toplamIslem: ozet['toplam_islem'] ?? 0,
      kritikIslem: ozet['kritik_islem'] ?? 0,
      kisiler: (json['kisiler'] as List? ?? [])
          .map((e) => EkipKisi.fromJson(e))
          .toList(),
      antrenorler: (json['antrenorler'] as List? ?? [])
          .map((e) => EkipAntrenor.fromJson(e))
          .toList(),
    );
  }
}

/// Kişi detayındaki zaman sıralı akışın bir satırı.
class EkipAkisSatiri {
  final DateTime? zaman;
  final String saat;
  final String kod;
  final String grup;
  final String etiket;
  final bool kritik;

  /// "Tahsilat girdi", "5 ders onayladı".
  final String metin;

  /// "Deniz YILMAZ · 1.250 TL", "Kort 1 · Sal 12 Kas 16:30".
  final String? ayrinti;

  const EkipAkisSatiri({
    required this.saat,
    required this.kod,
    required this.grup,
    required this.etiket,
    required this.kritik,
    required this.metin,
    this.zaman,
    this.ayrinti,
  });

  factory EkipAkisSatiri.fromJson(Map<String, dynamic> json) => EkipAkisSatiri(
        zaman: parseApiTarih(json['zaman']),
        saat: json['saat']?.toString() ?? '',
        kod: json['kod']?.toString() ?? '',
        grup: json['grup']?.toString() ?? 'diger',
        etiket: json['etiket']?.toString() ?? '',
        kritik: json['kritik'] == true,
        metin: json['metin']?.toString() ?? '',
        ayrinti: json['ayrinti']?.toString(),
      );
}

/// Bir günün ilk turnike girişi (okutma yoksa [ilkGiris] null).
class EkipGirisGunu {
  final DateTime gun;
  final DateTime? ilkGiris;

  const EkipGirisGunu({required this.gun, this.ilkGiris});

  factory EkipGirisGunu.fromJson(Map<String, dynamic> json) => EkipGirisGunu(
        gun: parseApiTarih(json['gun']) ?? simdiKulup(),
        ilkGiris: parseApiTarih(json['ilk_giris']),
      );
}

class EkipDetayData {
  final int id;
  final String adSoyad;
  final DateTime gun;

  /// Seçili günün ilk girişi.
  final DateTime? giris;

  /// Seçili günle biten son 7 gün (eskiden yeniye).
  final List<EkipGirisGunu> girisler;
  final List<EkipGrubu> gruplar;
  final int toplamIslem;
  final int kritikIslem;
  final List<EkipIslem> islemler;
  final List<EkipAkisSatiri> akis;

  const EkipDetayData({
    required this.id,
    required this.adSoyad,
    required this.gun,
    required this.girisler,
    required this.gruplar,
    required this.toplamIslem,
    required this.kritikIslem,
    required this.islemler,
    required this.akis,
    this.giris,
  });

  factory EkipDetayData.fromJson(Map<String, dynamic> json) {
    final kisi = json['kisi'] as Map? ?? const {};
    return EkipDetayData(
      id: kisi['id'] ?? 0,
      adSoyad: kisi['ad_soyad']?.toString() ?? '',
      gun: parseApiTarih(json['gun']) ?? simdiKulup(),
      giris: parseApiTarih(json['giris']),
      girisler: (json['girisler'] as List? ?? [])
          .map((e) => EkipGirisGunu.fromJson(e))
          .toList(),
      gruplar: EkipGrubu.liste(json['gruplar']),
      toplamIslem: json['toplam_islem'] ?? 0,
      kritikIslem: json['kritik_islem'] ?? 0,
      islemler: _islemler(json['islemler']),
      akis: (json['akis'] as List? ?? [])
          .map((e) => EkipAkisSatiri.fromJson(e))
          .toList(),
    );
  }
}

/// Bir kaydın (dersin) işlem geçmişi satırı: kim, ne zaman, ne yaptı.
class IslemGecmisiSatiri {
  final DateTime? zaman;
  final String kim;
  final String metin;

  /// ekleme | onay | yoklama | iptal | guncelleme | silme
  final String ton;

  /// Yoklamada katılım özeti ("4 üyeden 3 geldi · Gelmedi: …"), onayda not.
  final String? ayrinti;

  const IslemGecmisiSatiri({
    required this.kim,
    required this.metin,
    required this.ton,
    this.zaman,
    this.ayrinti,
  });

  factory IslemGecmisiSatiri.fromJson(Map<String, dynamic> json) =>
      IslemGecmisiSatiri(
        zaman: parseApiTarih(json['zaman']),
        kim: json['kim']?.toString() ?? '',
        metin: json['metin']?.toString() ?? '',
        ton: json['ton']?.toString() ?? 'guncelleme',
        ayrinti: json['ayrinti']?.toString(),
      );

  static List<IslemGecmisiSatiri> liste(dynamic json) =>
      (json as List? ?? []).map((e) => IslemGecmisiSatiri.fromJson(e)).toList();
}
