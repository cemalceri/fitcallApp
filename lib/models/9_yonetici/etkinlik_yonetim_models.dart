// lib/models/9_yonetici/etkinlik_yonetim_models.dart
//
// Yönetici ders (etkinlik) yönetimi modelleri.
// Backend karşılığı: api/yonetici/etkinlik_metots.py
//
// Tarih alanları parseApiTarih ile okunur (bkz. lib/common/tarih_util.dart);
// gönderimde formatApiTarih kullanılır.

import 'package:fitcall/common/tarih_util.dart';
import 'package:flutter/material.dart';

Color _renk(String? hex, Color varsayilan) {
  if (hex == null || hex.isEmpty) return varsayilan;
  final temiz = hex.replaceAll('#', '').trim();
  if (temiz.length != 6) return varsayilan;
  final deger = int.tryParse('FF$temiz', radix: 16);
  return deger == null ? varsayilan : Color(deger);
}

int _int(dynamic v, [int varsayilan = 0]) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? varsayilan;
}

/* ============================ ORTAK KÜÇÜK MODELLER ============================ */

class SecenekKort {
  final int id;
  final String adi;
  final int sira;
  final int maxEtkinlikSayisi;

  SecenekKort({
    required this.id,
    required this.adi,
    required this.sira,
    this.maxEtkinlikSayisi = 0,
  });

  factory SecenekKort.fromJson(Map<String, dynamic> j) => SecenekKort(
        id: _int(j['id']),
        adi: j['adi']?.toString() ?? '',
        sira: _int(j['sira']),
        maxEtkinlikSayisi: _int(j['max_etkinlik_sayisi']),
      );
}

class SecenekAntrenor {
  final int id;
  final String adSoyad;
  final Color renk;
  final bool pasif;

  SecenekAntrenor({
    required this.id,
    required this.adSoyad,
    required this.renk,
    this.pasif = false,
  });

  factory SecenekAntrenor.fromJson(Map<String, dynamic> j) => SecenekAntrenor(
        id: _int(j['id']),
        adSoyad: j['ad_soyad']?.toString() ?? '',
        renk: _renk(j['renk']?.toString(), const Color(0xFF8C8C8C)),
        pasif: j['pasif'] == true,
      );
}

class SecenekUrun {
  final int id;
  final String adi;
  final String urunTipi;
  final bool telafiMi;

  SecenekUrun({
    required this.id,
    required this.adi,
    required this.urunTipi,
    this.telafiMi = false,
  });

  factory SecenekUrun.fromJson(Map<String, dynamic> j) => SecenekUrun(
        id: _int(j['id']),
        adi: j['adi']?.toString() ?? '',
        urunTipi: j['urun_tipi']?.toString() ?? '',
        telafiMi: j['telafi_mi'] == true,
      );
}

class SecenekSeviye {
  final String kod;
  final String ad;
  final Color renk;

  SecenekSeviye({required this.kod, required this.ad, required this.renk});

  factory SecenekSeviye.fromJson(Map<String, dynamic> j) => SecenekSeviye(
        kod: j['kod']?.toString() ?? '',
        ad: j['ad']?.toString() ?? '',
        renk: _renk(j['renk']?.toString(), const Color(0xFFCFCFCF)),
      );
}

class SecenekUye {
  final int id;
  final String adSoyad;
  final String? uyeNo;
  final String telefon;
  final bool pasif;

  SecenekUye({
    required this.id,
    required this.adSoyad,
    this.uyeNo,
    this.telefon = '',
    this.pasif = false,
  });

  factory SecenekUye.fromJson(Map<String, dynamic> j) => SecenekUye(
        id: _int(j['id']),
        adSoyad: j['ad_soyad']?.toString() ?? '',
        uyeNo: j['uye_no']?.toString(),
        telefon: j['telefon']?.toString() ?? '',
        pasif: j['pasif'] == true,
      );

  /// Arama kutusu için: ad, üye no ve telefon üzerinden eşleşme.
  bool eslesiyorMu(String sorgu) {
    final q = sorgu.trim().toLowerCase();
    if (q.isEmpty) return true;
    return adSoyad.toLowerCase().contains(q) ||
        (uyeNo ?? '').toLowerCase().contains(q) ||
        telefon.toLowerCase().contains(q);
  }
}

class SecenekKodAd {
  final String kod;
  final String ad;
  final String aciklama;

  SecenekKodAd({required this.kod, required this.ad, this.aciklama = ''});

  factory SecenekKodAd.fromJson(Map<String, dynamic> j) => SecenekKodAd(
        kod: j['kod']?.toString() ?? '',
        ad: j['ad']?.toString() ?? '',
        aciklama: j['aciklama']?.toString() ?? '',
      );
}

/* ============================ HAFTALIK PROGRAM ============================ */

class ProgramKatilimci {
  final int id;
  final String adSoyad;

  ProgramKatilimci({required this.id, required this.adSoyad});

  factory ProgramKatilimci.fromJson(Map<String, dynamic> j) => ProgramKatilimci(
        id: _int(j['id']),
        adSoyad: j['ad_soyad']?.toString() ?? '',
      );
}

class ProgramDersi {
  final int id;
  final DateTime baslangic;
  final DateTime bitis;
  final String tarih; // "2026-07-23"
  final String saat; // "10:00"
  final String bitisSaat;
  final int? kortId;
  final String kortAdi;
  final int? antrenorId;
  final String antrenorAdi;
  final Color antrenorRenk;
  final int? urunId;
  final String urunAdi;
  final String seviye;
  final Color seviyeRenk;
  final bool iptalMi;
  final bool sabitPlanMi;
  final String
      durum; // planli | devam_ediyor | tamamlandi | iptal | onay_bekliyor
  final int katilimciSayisi;
  final List<ProgramKatilimci> katilimcilar;
  final String? aciklama;

  ProgramDersi({
    required this.id,
    required this.baslangic,
    required this.bitis,
    required this.tarih,
    required this.saat,
    required this.bitisSaat,
    this.kortId,
    this.kortAdi = '',
    this.antrenorId,
    this.antrenorAdi = '',
    required this.antrenorRenk,
    this.urunId,
    this.urunAdi = '',
    this.seviye = '',
    required this.seviyeRenk,
    this.iptalMi = false,
    this.sabitPlanMi = false,
    this.durum = 'planli',
    this.katilimciSayisi = 0,
    this.katilimcilar = const [],
    this.aciklama,
  });

  factory ProgramDersi.fromJson(Map<String, dynamic> j) {
    final bas = parseApiTarihOrNow(j['baslangic_tarih_saat']);
    return ProgramDersi(
      id: _int(j['id']),
      baslangic: bas,
      bitis: parseApiTarih(j['bitis_tarih_saat']) ??
          bas.add(const Duration(hours: 1)),
      tarih: j['tarih']?.toString() ?? '',
      saat: j['saat']?.toString() ?? '',
      bitisSaat: j['bitis_saat']?.toString() ?? '',
      kortId: j['kort_id'] == null ? null : _int(j['kort_id']),
      kortAdi: j['kort_adi']?.toString() ?? '',
      antrenorId: j['antrenor_id'] == null ? null : _int(j['antrenor_id']),
      antrenorAdi: j['antrenor_adi']?.toString() ?? '',
      antrenorRenk:
          _renk(j['antrenor_renk']?.toString(), const Color(0xFF8C8C8C)),
      urunId: j['urun_id'] == null ? null : _int(j['urun_id']),
      urunAdi: j['urun_adi']?.toString() ?? '',
      seviye: j['seviye']?.toString() ?? '',
      seviyeRenk: _renk(j['seviye_renk']?.toString(), const Color(0xFFCFCFCF)),
      iptalMi: j['iptal_mi'] == true,
      sabitPlanMi: j['sabit_plan_mi'] == true,
      durum: j['durum']?.toString() ?? 'planli',
      katilimciSayisi: _int(j['katilimci_sayisi']),
      katilimcilar: (j['katilimcilar'] as List? ?? const [])
          .map((e) =>
              ProgramKatilimci.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      aciklama: j['aciklama']?.toString(),
    );
  }

  int get sureDakika => bitis.difference(baslangic).inMinutes;
}

class ProgramGunu {
  final DateTime tarih;
  final String tarihMetin;
  final String gunAdi;
  final String gunKisa;
  final int dersSayisi;

  ProgramGunu({
    required this.tarih,
    required this.tarihMetin,
    required this.gunAdi,
    required this.gunKisa,
    required this.dersSayisi,
  });

  factory ProgramGunu.fromJson(Map<String, dynamic> j) => ProgramGunu(
        tarih: parseApiGun(j['tarih']) ?? simdiKulup(),
        tarihMetin: j['tarih']?.toString() ?? '',
        gunAdi: j['gun_adi']?.toString() ?? '',
        gunKisa: j['gun_kisa']?.toString() ?? '',
        dersSayisi: _int(j['ders_sayisi']),
      );
}

class HaftalikProgram {
  final DateTime haftaBaslangic;
  final DateTime haftaBitis;
  final DateTime bugun;
  final List<ProgramGunu> gunler;
  final List<SecenekKort> kortlar;
  final List<ProgramDersi> dersler;

  HaftalikProgram({
    required this.haftaBaslangic,
    required this.haftaBitis,
    required this.bugun,
    required this.gunler,
    required this.kortlar,
    required this.dersler,
  });

  factory HaftalikProgram.fromJson(Map<String, dynamic> j) => HaftalikProgram(
        haftaBaslangic: parseApiGun(j['hafta_baslangic']) ?? simdiKulup(),
        haftaBitis: parseApiGun(j['hafta_bitis']) ?? simdiKulup(),
        bugun: parseApiGun(j['bugun']) ?? simdiKulup(),
        gunler: (j['gunler'] as List? ?? const [])
            .map(
                (e) => ProgramGunu.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        kortlar: (j['kortlar'] as List? ?? const [])
            .map(
                (e) => SecenekKort.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        dersler: (j['dersler'] as List? ?? const [])
            .map((e) =>
                ProgramDersi.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// Verilen günün dersleri (iptaller dahil).
  List<ProgramDersi> gununDersleri(DateTime gun) {
    final anahtar = formatApiGun(gun);
    return dersler.where((d) => d.tarih == anahtar).toList()
      ..sort((a, b) => a.baslangic.compareTo(b.baslangic));
  }
}

/* ============================ FORM VERİLERİ ============================ */

class EtkinlikMevcutDeger {
  final int id;
  final int? urunId;
  final int? kortId;
  final int? antrenorId;
  final int? yardimciAntrenorId;
  final String seviye;
  final String antrenorKatsayisi;
  final String ucret;
  final String aciklama;
  final DateTime? baslangic;
  final DateTime? bitis;
  final bool iptalMi;
  final bool sabitPlanMi;
  final bool urunKilitliMi;

  EtkinlikMevcutDeger({
    required this.id,
    this.urunId,
    this.kortId,
    this.antrenorId,
    this.yardimciAntrenorId,
    this.seviye = '',
    this.antrenorKatsayisi = '1.0',
    this.ucret = '0',
    this.aciklama = '',
    this.baslangic,
    this.bitis,
    this.iptalMi = false,
    this.sabitPlanMi = false,
    this.urunKilitliMi = false,
  });

  factory EtkinlikMevcutDeger.fromJson(Map<String, dynamic> j) =>
      EtkinlikMevcutDeger(
        id: _int(j['id']),
        urunId: j['urun_id'] == null ? null : _int(j['urun_id']),
        kortId: j['kort_id'] == null ? null : _int(j['kort_id']),
        antrenorId: j['antrenor_id'] == null ? null : _int(j['antrenor_id']),
        yardimciAntrenorId: j['yardimci_antrenor_id'] == null
            ? null
            : _int(j['yardimci_antrenor_id']),
        seviye: j['seviye']?.toString() ?? '',
        antrenorKatsayisi: j['antrenor_katsayisi']?.toString() ?? '1.0',
        ucret: j['ucret']?.toString() ?? '0',
        aciklama: j['aciklama']?.toString() ?? '',
        baslangic: parseApiTarih(j['baslangic_tarih_saat']),
        bitis: parseApiTarih(j['bitis_tarih_saat']),
        iptalMi: j['iptal_mi'] == true,
        sabitPlanMi: j['sabit_plan_mi'] == true,
        urunKilitliMi: j['urun_kilitli_mi'] == true,
      );
}

class EtkinlikFormVerileri {
  final List<SecenekKort> kortlar;
  final List<SecenekAntrenor> antrenorler;
  final List<SecenekUrun> urunler;
  final List<SecenekSeviye> seviyeler;
  final List<SecenekUye> uyeler;
  final List<SecenekKodAd> iptalSebepleri;
  final List<SecenekKodAd> iptalModlari;
  final List<int> seciliUyeIdler;
  final EtkinlikMevcutDeger? etkinlik;

  EtkinlikFormVerileri({
    required this.kortlar,
    required this.antrenorler,
    required this.urunler,
    required this.seviyeler,
    required this.uyeler,
    required this.iptalSebepleri,
    required this.iptalModlari,
    required this.seciliUyeIdler,
    this.etkinlik,
  });

  factory EtkinlikFormVerileri.fromJson(Map<String, dynamic> j) {
    List<T> liste<T>(String anahtar, T Function(Map<String, dynamic>) yap) =>
        (j[anahtar] as List? ?? const [])
            .map((e) => yap((e as Map).cast<String, dynamic>()))
            .toList();

    return EtkinlikFormVerileri(
      kortlar: liste('kortlar', SecenekKort.fromJson),
      antrenorler: liste('antrenorler', SecenekAntrenor.fromJson),
      urunler: liste('urunler', SecenekUrun.fromJson),
      seviyeler: liste('seviyeler', SecenekSeviye.fromJson),
      uyeler: liste('uyeler', SecenekUye.fromJson),
      iptalSebepleri: liste('iptal_sebepleri', SecenekKodAd.fromJson),
      iptalModlari: liste('iptal_modlari', SecenekKodAd.fromJson),
      seciliUyeIdler:
          (j['secili_uye_idler'] as List? ?? const []).map(_int).toList(),
      etkinlik: j['etkinlik'] == null
          ? null
          : EtkinlikMevcutDeger.fromJson(
              (j['etkinlik'] as Map).cast<String, dynamic>()),
    );
  }
}

/* ============================ SİLME ÖNİZLEMESİ ============================ */

class SilmeEtkisi {
  final int katilimciSayisi;
  final int paketKullanimi;
  final int telafiKaybolacak;
  final int telafiSerbestKalacak;
  final int teyitSayisi;
  final int onaySayisi;
  final int degerlendirmeSayisi;
  final String dersTarih;
  final String dersSaat;
  final String dersKortAdi;

  SilmeEtkisi({
    required this.katilimciSayisi,
    required this.paketKullanimi,
    required this.telafiKaybolacak,
    required this.telafiSerbestKalacak,
    required this.teyitSayisi,
    required this.onaySayisi,
    required this.degerlendirmeSayisi,
    required this.dersTarih,
    required this.dersSaat,
    required this.dersKortAdi,
  });

  factory SilmeEtkisi.fromJson(Map<String, dynamic> j) {
    final ders = (j['ders'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SilmeEtkisi(
      katilimciSayisi: _int(j['katilimci_sayisi']),
      paketKullanimi: _int(j['paket_kullanimi']),
      telafiKaybolacak: _int(j['telafi_kaybolacak']),
      telafiSerbestKalacak: _int(j['telafi_serbest_kalacak']),
      teyitSayisi: _int(j['teyit_sayisi']),
      onaySayisi: _int(j['onay_sayisi']),
      degerlendirmeSayisi: _int(j['degerlendirme_sayisi']),
      dersTarih: ders['tarih']?.toString() ?? '',
      dersSaat: ders['saat']?.toString() ?? '',
      dersKortAdi: ders['kort_adi']?.toString() ?? '',
    );
  }

  /// Uyarı penceresinde satır satır gösterilecek etkiler (yalnızca dolu olanlar).
  List<String> get uyariSatirlari {
    final satirlar = <String>[];
    if (telafiKaybolacak > 0) {
      satirlar.add(
          '$telafiKaybolacak telafi hakkı silinecek (üyeler bu haklarını kaybeder)');
    }
    if (paketKullanimi > 0) {
      satirlar.add('$paketKullanimi paket kullanım kaydı silinecek');
    }
    if (telafiSerbestKalacak > 0) {
      satirlar.add('$telafiSerbestKalacak telafi kaydı kullanılmamışa dönecek');
    }
    if (katilimciSayisi > 0) {
      satirlar.add('$katilimciSayisi katılımcı kaydı silinecek');
    }
    if (teyitSayisi > 0) satirlar.add('$teyitSayisi teyit kaydı silinecek');
    if (onaySayisi > 0) satirlar.add('$onaySayisi onay kaydı silinecek');
    if (degerlendirmeSayisi > 0) {
      satirlar.add('$degerlendirmeSayisi değerlendirme silinecek');
    }
    return satirlar;
  }
}

/* ============================ KAYIT İSTEĞİ ============================ */

class EtkinlikKaydetIstegi {
  final int? pk;
  final int urunId;
  final int kortId;
  final int antrenorId;
  final int? yardimciAntrenorId;
  final DateTime baslangic;
  final DateTime bitis;
  final String seviye;
  final String antrenorKatsayisi;
  final String ucret;
  final String aciklama;
  final List<int> uyeIdler;

  EtkinlikKaydetIstegi({
    this.pk,
    required this.urunId,
    required this.kortId,
    required this.antrenorId,
    this.yardimciAntrenorId,
    required this.baslangic,
    required this.bitis,
    required this.seviye,
    this.antrenorKatsayisi = '1.0',
    this.ucret = '0',
    this.aciklama = '',
    required this.uyeIdler,
  });

  Map<String, dynamic> toJson() => {
        if (pk != null && pk! > 0) 'pk': pk,
        'urun': urunId,
        'kort': kortId,
        'antrenor': antrenorId,
        if (yardimciAntrenorId != null) 'yardimci_antrenor': yardimciAntrenorId,
        // Sözleşme: offset'siz yerel ISO
        'baslangic_tarih_saat': formatApiTarih(baslangic),
        'bitis_tarih_saat': formatApiTarih(bitis),
        'seviye': seviye,
        'antrenor_katsayisi': antrenorKatsayisi,
        'ucret': ucret,
        'aciklama': aciklama,
        'uye_id_list': uyeIdler,
      };
}
