// lib/models/1_common/hakedis_models.dart
//
// Antrenör hakediş saatleri ekranının modelleri.
// Backend: api/yonetici/hakedis_metots.py + hakedis_servis.py
//
// Durum ve rol kodları backend'le birebir aynı string'ler; kural tek yerde
// (backend hakedis_servis.py) uygulanır, burada yalnızca sunulur.

import 'package:fitcall/common/tarih_util.dart';

/* -------------------------------------------------------------------------- */
/*                                  SABİTLER                                  */
/* -------------------------------------------------------------------------- */

/// Hakediş durumu kodları — backend `DURUMLAR` ile aynı.
class HakedisDurumu {
  static const String hakedis = 'hakedis';
  static const String bekliyor = 'bekliyor';
  static const String disi = 'disi';

  /// Ekranda gösterim sırası: alacağı, bekleyen, dışı.
  static const List<String> sirali = [hakedis, bekliyor, disi];

  static String etiket(String durum) {
    switch (durum) {
      case hakedis:
        return 'Hakediş alacak';
      case bekliyor:
        return 'Bekliyor';
      case disi:
        return 'Hakediş dışı';
      default:
        return durum;
    }
  }
}

/// Antrenörün derse hangi rolle girdiği — backend `ROLLER` ile aynı.
class HakedisRolu {
  static const String ana = 'ana';
  static const String yardimci = 'yardimci';

  static String etiket(String rol) =>
      rol == yardimci ? 'Yardımcı antrenör' : 'Ana antrenör';
}

/// Dakikayı "23,5 sa" biçimine çevirir; 0 ise "0 sa".
String saatMetni(int dakika) {
  if (dakika <= 0) return '0 sa';
  final saat = dakika / 60.0;
  final metin = saat.toStringAsFixed(1).replaceAll('.', ',');
  return '${metin.endsWith(',0') ? metin.substring(0, metin.length - 2) : metin} sa';
}

int _int(dynamic v) => v == null ? 0 : (v as num).toInt();

/// Ay ızgarasının tek hücresi.
///
/// Hem antrenör listesi (`HakedisListeAyi`) hem ay panosu (`HakedisAy`) aynı
/// ızgarayı besliyor; ortak görünüm modeli olmasa ızgara iki kez yazılırdı.
class HakedisAyHucresi {
  /// "Tem" — kısa ay adı
  final String kisaAd;

  /// "26" — yılın son iki hanesi
  final String yilKisa;

  final int dakika;
  final bool bekleyenVar;
  final bool bos;

  const HakedisAyHucresi({
    required this.kisaAd,
    required this.yilKisa,
    required this.dakika,
    required this.bekleyenVar,
    required this.bos,
  });
}

/// "Tem 2026" → "Tem"
String _kisaAd(String kisaEtiket) =>
    kisaEtiket.isEmpty ? '' : kisaEtiket.split(' ').first;

/// 2026 → "26"
String _yilKisa(int yil) {
  final metin = yil.toString();
  return metin.length > 2 ? metin.substring(metin.length - 2) : metin;
}

/* -------------------------------------------------------------------------- */
/*                          1. EKRAN: ANTRENÖR LİSTESİ                        */
/* -------------------------------------------------------------------------- */

/// Bir dönemin (ay ya da 12 ay toplamı) durum kırılımı.
///
/// Hem ay ızgarasındaki hücreler hem antrenör satırları bu biçimi kullanıyor.
class HakedisDonem {
  final int dersSayisi;
  final int dakika;
  final int hakedisDersSayisi;
  final int hakedisDakika;
  final int bekleyenDersSayisi;
  final int bekleyenDakika;
  final int disiDersSayisi;
  final int disiDakika;

  const HakedisDonem({
    this.dersSayisi = 0,
    this.dakika = 0,
    this.hakedisDersSayisi = 0,
    this.hakedisDakika = 0,
    this.bekleyenDersSayisi = 0,
    this.bekleyenDakika = 0,
    this.disiDersSayisi = 0,
    this.disiDakika = 0,
  });

  bool get bos => dersSayisi == 0;
  bool get bekleyenVar => bekleyenDersSayisi > 0;

  factory HakedisDonem.fromJson(Map<String, dynamic> j) => HakedisDonem(
        dersSayisi: _int(j['ders_sayisi']),
        dakika: _int(j['dakika']),
        hakedisDersSayisi: _int(j['hakedis_ders_sayisi']),
        hakedisDakika: _int(j['hakedis_dakika']),
        bekleyenDersSayisi: _int(j['bekleyen_ders_sayisi']),
        bekleyenDakika: _int(j['bekleyen_dakika']),
        disiDersSayisi: _int(j['disi_ders_sayisi']),
        disiDakika: _int(j['disi_dakika']),
      );
}

/// Ay ızgarasındaki bir hücre — tüm görünür antrenörlerin o aydaki toplamı.
class HakedisListeAyi {
  final int yil;
  final int ay;
  final String etiket;
  final String kisaEtiket;
  final HakedisDonem donem;

  const HakedisListeAyi({
    required this.yil,
    required this.ay,
    required this.etiket,
    required this.kisaEtiket,
    required this.donem,
  });

  HakedisAyHucresi get hucre => HakedisAyHucresi(
        kisaAd: _kisaAd(kisaEtiket),
        yilKisa: _yilKisa(yil),
        dakika: donem.dakika,
        bekleyenVar: donem.bekleyenVar,
        bos: donem.bos,
      );

  factory HakedisListeAyi.fromJson(Map<String, dynamic> j) => HakedisListeAyi(
        yil: _int(j['yil']),
        ay: _int(j['ay']),
        etiket: j['etiket']?.toString() ?? '',
        kisaEtiket: j['kisa_etiket']?.toString() ?? '',
        donem: HakedisDonem.fromJson(j),
      );
}

class HakedisAntrenorOzeti {
  final int antrenorId;
  final String adSoyad;
  final bool aktifMi;

  /// Son 12 ayın toplamı.
  final HakedisDonem toplam;

  /// Ay ay kırılım — üst düzeydeki `aylar` listesiyle AYNI SIRADA.
  final List<HakedisDonem> aylar;

  const HakedisAntrenorOzeti({
    required this.antrenorId,
    required this.adSoyad,
    required this.aktifMi,
    required this.toplam,
    required this.aylar,
  });

  /// [index]'inci ayın kırılımı; sıra dışıysa boş dönem.
  HakedisDonem ay(int index) => (index >= 0 && index < aylar.length)
      ? aylar[index]
      : const HakedisDonem();

  factory HakedisAntrenorOzeti.fromJson(Map<String, dynamic> j) {
    final aylik = (j['aylar'] as List?) ?? const [];
    return HakedisAntrenorOzeti(
      antrenorId: _int(j['antrenor_id']),
      adSoyad: j['ad_soyad']?.toString() ?? '',
      aktifMi: j['aktif_mi'] == true,
      toplam: HakedisDonem.fromJson(j),
      aylar: aylik
          .map((e) => HakedisDonem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HakedisAntrenorListesi {
  final int aySayisi;

  /// Ay ızgarasının hücreleri, ESKİDEN YENİYE — son eleman içinde bulunulan ay.
  final List<HakedisListeAyi> aylar;

  final List<HakedisAntrenorOzeti> antrenorler;

  const HakedisAntrenorListesi({
    required this.aySayisi,
    required this.aylar,
    required this.antrenorler,
  });

  factory HakedisAntrenorListesi.fromJson(Map<String, dynamic> j) {
    final liste = (j['antrenorler'] as List?) ?? const [];
    final aylik = (j['aylar'] as List?) ?? const [];
    return HakedisAntrenorListesi(
      aySayisi: _int(j['ay_sayisi']),
      aylar: aylik
          .map((e) =>
              HakedisListeAyi.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      antrenorler: liste
          .map((e) =>
              HakedisAntrenorOzeti.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             2. EKRAN: AY PANOSU                            */
/* -------------------------------------------------------------------------- */

class HakedisAntrenor {
  final int id;
  final String adSoyad;
  final bool aktifMi;

  const HakedisAntrenor({
    required this.id,
    required this.adSoyad,
    required this.aktifMi,
  });

  factory HakedisAntrenor.fromJson(Map<String, dynamic> j) => HakedisAntrenor(
        id: _int(j['id']),
        adSoyad: j['ad_soyad']?.toString() ?? '',
        aktifMi: j['aktif_mi'] == true,
      );
}

/// Bir ay + rol içindeki tek durum satırı (ör. "hakediş alacak · 20 · 23,5 sa").
class HakedisGrubu {
  final String durum;
  final int dersSayisi;
  final int dakika;

  const HakedisGrubu({
    required this.durum,
    required this.dersSayisi,
    required this.dakika,
  });

  bool get bos => dersSayisi == 0;

  factory HakedisGrubu.fromJson(Map<String, dynamic> j) => HakedisGrubu(
        durum: j['durum']?.toString() ?? '',
        dersSayisi: _int(j['ders_sayisi']),
        dakika: _int(j['dakika']),
      );
}

/// Bir ay içindeki tek rol kartı (ana ya da yardımcı antrenör).
class HakedisRolOzeti {
  final String rol;
  final int dersSayisi;
  final int dakika;
  final List<HakedisGrubu> gruplar;

  const HakedisRolOzeti({
    required this.rol,
    required this.dersSayisi,
    required this.dakika,
    required this.gruplar,
  });

  bool get bos => dersSayisi == 0;

  /// Gösterim sırasına göre, boş olmayan gruplar.
  List<HakedisGrubu> get doluGruplar {
    final haritali = {for (final g in gruplar) g.durum: g};
    return HakedisDurumu.sirali
        .map((d) => haritali[d])
        .whereType<HakedisGrubu>()
        .where((g) => !g.bos)
        .toList();
  }

  factory HakedisRolOzeti.fromJson(Map<String, dynamic> j) {
    final liste = (j['gruplar'] as List?) ?? const [];
    return HakedisRolOzeti(
      rol: j['rol']?.toString() ?? '',
      dersSayisi: _int(j['ders_sayisi']),
      dakika: _int(j['dakika']),
      gruplar: liste
          .map((e) => HakedisGrubu.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Ay şeridindeki bir ay ve o ayın tüm kırılımı.
class HakedisAy {
  final int yil;
  final int ay;
  final String etiket;
  final String kisaEtiket;
  final int dersSayisi;
  final int dakika;
  final int hakedisDersSayisi;
  final int hakedisDakika;
  final int bekleyenDersSayisi;
  final int bekleyenDakika;
  final int disiDersSayisi;
  final int disiDakika;
  final List<HakedisRolOzeti> roller;

  const HakedisAy({
    required this.yil,
    required this.ay,
    required this.etiket,
    required this.kisaEtiket,
    required this.dersSayisi,
    required this.dakika,
    required this.hakedisDersSayisi,
    required this.hakedisDakika,
    required this.bekleyenDersSayisi,
    required this.bekleyenDakika,
    required this.disiDersSayisi,
    required this.disiDakika,
    required this.roller,
  });

  bool get bos => dersSayisi == 0;

  /// Dersi olan roller (yardımcı olarak hiç girmediyse o kart gösterilmez).
  List<HakedisRolOzeti> get doluRoller => roller.where((r) => !r.bos).toList();

  HakedisAyHucresi get hucre => HakedisAyHucresi(
        kisaAd: _kisaAd(kisaEtiket),
        yilKisa: _yilKisa(yil),
        dakika: dakika,
        bekleyenVar: bekleyenDersSayisi > 0,
        bos: bos,
      );

  factory HakedisAy.fromJson(Map<String, dynamic> j) {
    final liste = (j['roller'] as List?) ?? const [];
    return HakedisAy(
      yil: _int(j['yil']),
      ay: _int(j['ay']),
      etiket: j['etiket']?.toString() ?? '',
      kisaEtiket: j['kisa_etiket']?.toString() ?? '',
      dersSayisi: _int(j['ders_sayisi']),
      dakika: _int(j['dakika']),
      hakedisDersSayisi: _int(j['hakedis_ders_sayisi']),
      hakedisDakika: _int(j['hakedis_dakika']),
      bekleyenDersSayisi: _int(j['bekleyen_ders_sayisi']),
      bekleyenDakika: _int(j['bekleyen_dakika']),
      disiDersSayisi: _int(j['disi_ders_sayisi']),
      disiDakika: _int(j['disi_dakika']),
      roller: liste
          .map((e) =>
              HakedisRolOzeti.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HakedisOzet {
  final HakedisAntrenor antrenor;

  /// Son 12 ay, ESKİDEN YENİYE — son eleman içinde bulunulan ay. Tamamı tek
  /// istekte gelir; ay ızgarasında gezinirken yeniden sorgu atılmasın diye.
  final List<HakedisAy> aylar;

  const HakedisOzet({required this.antrenor, required this.aylar});

  factory HakedisOzet.fromJson(Map<String, dynamic> j) {
    final liste = (j['aylar'] as List?) ?? const [];
    return HakedisOzet(
      antrenor: HakedisAntrenor.fromJson(
          (j['antrenor'] as Map).cast<String, dynamic>()),
      aylar: liste
          .map((e) => HakedisAy.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            3. EKRAN: DERS LİSTESİ                          */
/* -------------------------------------------------------------------------- */

class HakedisKatilimci {
  final int uyeId;
  final String adSoyad;

  /// 'katildi' | 'katilmadi' | null (yoklama alınmamış)
  final String? katilimDurum;
  final bool planDisiMi;
  final String? notMetni;

  const HakedisKatilimci({
    required this.uyeId,
    required this.adSoyad,
    required this.katilimDurum,
    required this.planDisiMi,
    this.notMetni,
  });

  bool get katildi => katilimDurum == 'katildi';
  bool get katilmadi => katilimDurum == 'katilmadi';

  factory HakedisKatilimci.fromJson(Map<String, dynamic> j) => HakedisKatilimci(
        uyeId: _int(j['uye_id']),
        adSoyad: j['ad_soyad']?.toString() ?? '',
        katilimDurum: j['katilim_durum']?.toString(),
        planDisiMi: j['plan_disi_mi'] == true,
        notMetni: j['not_metni']?.toString(),
      );
}

class HakedisDers {
  final int id;
  final DateTime? baslangic;
  final DateTime? bitis;
  final int dakika;
  final String rol;
  final String durum;
  final String? kortAdi;
  final String? urunAdi;
  final String? urunTipi;
  final bool iptalMi;
  final bool? yoneticiTamamlandi;
  final String? onayNedeni;
  final String? onayAciklamasi;

  /// İptal bilgisi — yalnız [iptalMi] true iken dolu. İptaller "hakediş dışı"
  /// grubunda çıktığı için "neden dışı" sorusunun cevabı bu alanlar.
  final String? iptalEden;
  final DateTime? iptalTarihi;
  final String? iptalSebebi;
  final String? iptalAciklamasi;

  final List<HakedisKatilimci> katilimcilar;

  const HakedisDers({
    required this.id,
    required this.baslangic,
    required this.bitis,
    required this.dakika,
    required this.rol,
    required this.durum,
    required this.kortAdi,
    required this.urunAdi,
    required this.urunTipi,
    required this.iptalMi,
    required this.yoneticiTamamlandi,
    required this.onayNedeni,
    required this.onayAciklamasi,
    required this.iptalEden,
    required this.iptalTarihi,
    required this.iptalSebebi,
    required this.iptalAciklamasi,
    required this.katilimcilar,
  });

  /// "Özel ders · Kort 2" — ikisi de yoksa boş.
  String get altBaslik =>
      [urunAdi, kortAdi].where((e) => e != null && e.isNotEmpty).join(' · ');

  /// Ders yapılmadığı halde hakediş verilmişse ekranda not gösterilir.
  /// İptaller ayrı bir panelde anlatıldığı için buraya girmez.
  bool get yapilmadiNotuVar =>
      !iptalMi &&
      yoneticiTamamlandi == false &&
      (onayNedeni?.isNotEmpty == true || onayAciklamasi?.isNotEmpty == true);

  /// İptal paneli gösterilecek mi? (kim/ne zaman/neden alanlarından biri dolu)
  bool get iptalBilgisiVar =>
      iptalMi &&
      (iptalEden?.isNotEmpty == true ||
          iptalTarihi != null ||
          iptalSebebi?.isNotEmpty == true ||
          iptalAciklamasi?.isNotEmpty == true);

  factory HakedisDers.fromJson(Map<String, dynamic> j) {
    final liste = (j['katilimcilar'] as List?) ?? const [];
    return HakedisDers(
      id: _int(j['id']),
      baslangic: parseApiTarih(j['baslangic']?.toString()),
      bitis: parseApiTarih(j['bitis']?.toString()),
      dakika: _int(j['dakika']),
      rol: j['rol']?.toString() ?? '',
      durum: j['durum']?.toString() ?? '',
      kortAdi: j['kort_adi']?.toString(),
      urunAdi: j['urun_adi']?.toString(),
      urunTipi: j['urun_tipi']?.toString(),
      iptalMi: j['iptal_mi'] == true,
      yoneticiTamamlandi: j['yonetici_tamamlandi'] as bool?,
      onayNedeni: j['onay_nedeni']?.toString(),
      onayAciklamasi: j['onay_aciklamasi']?.toString(),
      iptalEden: j['iptal_eden']?.toString(),
      iptalTarihi: parseApiTarih(j['iptal_tarihi']?.toString()),
      iptalSebebi: j['iptal_sebebi']?.toString(),
      iptalAciklamasi: j['iptal_aciklamasi']?.toString(),
      katilimcilar: liste
          .map((e) =>
              HakedisKatilimci.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class HakedisDersListesi {
  final int yil;
  final int ay;
  final String etiket;
  final String rol;
  final String durum;
  final int dersSayisi;
  final int dakika;
  final List<HakedisDers> dersler;

  const HakedisDersListesi({
    required this.yil,
    required this.ay,
    required this.etiket,
    required this.rol,
    required this.durum,
    required this.dersSayisi,
    required this.dakika,
    required this.dersler,
  });

  factory HakedisDersListesi.fromJson(Map<String, dynamic> j) {
    final liste = (j['dersler'] as List?) ?? const [];
    return HakedisDersListesi(
      yil: _int(j['yil']),
      ay: _int(j['ay']),
      etiket: j['etiket']?.toString() ?? '',
      rol: j['rol']?.toString() ?? '',
      durum: j['durum']?.toString() ?? '',
      dersSayisi: _int(j['ders_sayisi']),
      dakika: _int(j['dakika']),
      dersler: liste
          .map((e) => HakedisDers.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
