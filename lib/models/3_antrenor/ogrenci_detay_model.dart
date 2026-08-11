import 'package:fitcall/common/tarih_util.dart';

// lib/models/3_antrenor/ogrenci_detay_model.dart

/// Öğrenci detayı — profil bölümü
class OgrenciProfil {
  final int id;
  final String adi;
  final String soyadi;
  final int uyeNo;
  final String? telefon;
  final String? email;
  final DateTime? dogumTarihi;
  final String? cinsiyet;
  final String seviyeRengi;
  final String? programTercihi;
  final bool aktifMi;
  final bool sorumluHocasiMiyim;

  OgrenciProfil({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.uyeNo,
    this.telefon,
    this.email,
    this.dogumTarihi,
    this.cinsiyet,
    required this.seviyeRengi,
    this.programTercihi,
    required this.aktifMi,
    required this.sorumluHocasiMiyim,
  });

  String get adSoyad => '$adi $soyadi'.trim();

  factory OgrenciProfil.fromJson(Map<String, dynamic> json) {
    return OgrenciProfil(
      id: (json['id'] as num?)?.toInt() ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      uyeNo: (json['uye_no'] as num?)?.toInt() ?? 0,
      telefon: json['telefon'],
      email: json['email'],
      dogumTarihi: parseApiTarih(json['dogum_tarihi'] ?? ''),
      cinsiyet: json['cinsiyet'],
      seviyeRengi: json['seviye_rengi'] ?? '',
      programTercihi: json['program_tercihi'],
      aktifMi: json['aktif_mi'] == true,
      sorumluHocasiMiyim: json['sorumlu_hocasi_miyim'] == true,
    );
  }
}

/// Öğrenci detayı — veli/acil durum iletişimi
class OgrenciVeli {
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
  final String? anneAdiSoyadi;
  final String? anneTelefon;
  final String? babaAdiSoyadi;
  final String? babaTelefon;

  OgrenciVeli({
    this.acilDurumKisi,
    this.acilDurumTelefon,
    this.anneAdiSoyadi,
    this.anneTelefon,
    this.babaAdiSoyadi,
    this.babaTelefon,
  });

  bool get bosMu =>
      (acilDurumTelefon ?? '').isEmpty &&
      (anneTelefon ?? '').isEmpty &&
      (babaTelefon ?? '').isEmpty;

  factory OgrenciVeli.fromJson(Map<String, dynamic> json) {
    return OgrenciVeli(
      acilDurumKisi: json['acil_durum_kisi'],
      acilDurumTelefon: json['acil_durum_telefon'],
      anneAdiSoyadi: json['anne_adi_soyadi'],
      anneTelefon: json['anne_telefon'],
      babaAdiSoyadi: json['baba_adi_soyadi'],
      babaTelefon: json['baba_telefon'],
    );
  }
}

/// Öğrenci detayı — katılım istatistiği (son 90 gün)
class OgrenciIstatistik {
  final int pencereGun;
  final int plananlanDers;
  final int yoklamaGirilen;
  final int katildigiDers;

  /// Yoklaması girilmiş dersler üzerinden yüzde; yoklama yoksa null.
  final int? katilimYuzdesi;
  final DateTime? sonKatilimTarihi;

  OgrenciIstatistik({
    required this.pencereGun,
    required this.plananlanDers,
    required this.yoklamaGirilen,
    required this.katildigiDers,
    this.katilimYuzdesi,
    this.sonKatilimTarihi,
  });

  factory OgrenciIstatistik.fromJson(Map<String, dynamic> json) {
    return OgrenciIstatistik(
      pencereGun: (json['pencere_gun'] as num?)?.toInt() ?? 90,
      plananlanDers: (json['planlanan_ders'] as num?)?.toInt() ?? 0,
      yoklamaGirilen: (json['yoklama_girilen'] as num?)?.toInt() ?? 0,
      katildigiDers: (json['katildigi_ders'] as num?)?.toInt() ?? 0,
      katilimYuzdesi: (json['katilim_yuzdesi'] as num?)?.toInt(),
      sonKatilimTarihi: parseApiTarih(json['son_katilim_tarihi'] ?? ''),
    );
  }
}

/// Öğrenci detayı — aktif paket
class OgrenciPaket {
  final int id;
  final String urunAdi;
  final int? toplamHak;
  final double? kalanHak;
  final DateTime? baslangic;
  final DateTime? bitis;

  OgrenciPaket({
    required this.id,
    required this.urunAdi,
    this.toplamHak,
    this.kalanHak,
    this.baslangic,
    this.bitis,
  });

  factory OgrenciPaket.fromJson(Map<String, dynamic> json) {
    return OgrenciPaket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      urunAdi: json['urun_adi'] ?? '',
      toplamHak: (json['toplam_hak'] as num?)?.toInt(),
      kalanHak: (json['kalan_hak'] as num?)?.toDouble(),
      baslangic: parseApiTarih(json['baslangic'] ?? ''),
      bitis: parseApiTarih(json['bitis'] ?? ''),
    );
  }
}

/// Öğrenci detayı — son katılım kaydı
class OgrenciKatilim {
  final int etkinlikId;
  final DateTime? tarih;
  final String kortAdi;
  final bool katildi;
  final bool planDisiMi;
  final String? notMetni;

  OgrenciKatilim({
    required this.etkinlikId,
    this.tarih,
    required this.kortAdi,
    required this.katildi,
    required this.planDisiMi,
    this.notMetni,
  });

  factory OgrenciKatilim.fromJson(Map<String, dynamic> json) {
    return OgrenciKatilim(
      etkinlikId: (json['etkinlik_id'] as num?)?.toInt() ?? 0,
      tarih: parseApiTarih(json['tarih'] ?? ''),
      kortAdi: json['kort_adi'] ?? '',
      katildi: json['katildi'] == true,
      planDisiMi: json['plan_disi_mi'] == true,
      notMetni: json['not_metni'],
    );
  }
}

/// Öğrenci detayı — görüşme notu
class OgrenciGorusmeNotu {
  final String gorusenKisi;
  final DateTime? gorusmeTarihi;
  final String notu;

  OgrenciGorusmeNotu({
    required this.gorusenKisi,
    this.gorusmeTarihi,
    required this.notu,
  });

  factory OgrenciGorusmeNotu.fromJson(Map<String, dynamic> json) {
    return OgrenciGorusmeNotu(
      gorusenKisi: json['gorusen_kisi'] ?? '',
      gorusmeTarihi: parseApiTarih(json['gorusme_tarihi'] ?? ''),
      notu: json['notu'] ?? '',
    );
  }
}

/// getAntrenorOgrenciDetay cevabı
class OgrenciDetayModel {
  final OgrenciProfil profil;
  final OgrenciVeli veli;
  final OgrenciIstatistik istatistik;
  final List<OgrenciPaket> paketler;
  final int aktifTelafi;
  final List<OgrenciKatilim> sonKatilimlar;
  final List<OgrenciGorusmeNotu> gorusmeNotlari;

  OgrenciDetayModel({
    required this.profil,
    required this.veli,
    required this.istatistik,
    required this.paketler,
    required this.aktifTelafi,
    required this.sonKatilimlar,
    required this.gorusmeNotlari,
  });

  factory OgrenciDetayModel.fromJson(Map<String, dynamic> json) {
    return OgrenciDetayModel(
      profil: OgrenciProfil.fromJson(
          (json['profil'] as Map?)?.cast<String, dynamic>() ?? const {}),
      veli: OgrenciVeli.fromJson(
          (json['veli'] as Map?)?.cast<String, dynamic>() ?? const {}),
      istatistik: OgrenciIstatistik.fromJson(
          (json['istatistik'] as Map?)?.cast<String, dynamic>() ?? const {}),
      paketler: ((json['paketler'] as List?) ?? const [])
          .map((e) => OgrenciPaket.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      aktifTelafi: (json['aktif_telafi'] as num?)?.toInt() ?? 0,
      sonKatilimlar: ((json['son_katilimlar'] as List?) ?? const [])
          .map((e) =>
              OgrenciKatilim.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      gorusmeNotlari: ((json['gorusme_notlari'] as List?) ?? const [])
          .map((e) =>
              OgrenciGorusmeNotu.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
