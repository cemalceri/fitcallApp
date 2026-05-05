class DevirRolu {
  static const ana = 'ANA';
  static const yardimci = 'YARDIMCI';
}

class DevirDurumu {
  static const bekliyor = 'BEKLIYOR';
  static const kabulEdildi = 'KABUL_EDILDI';
  static const reddedildi = 'REDDEDILDI';
  static const geriCekildi = 'GERI_CEKILDI';
  static const suresiGecti = 'SURESI_GECTI';
}

/// Etkinlik içinde gelen aktif (BEKLIYOR) devir talebi özeti.
class AktifDevirTalebiModel {
  final int id;
  final String rol; // 'ANA' | 'YARDIMCI'
  final String durum;
  final int talepEdenAntrenorId;
  final String talepEdenAntrenorAdi;
  final int hedefAntrenorId;
  final String hedefAntrenorAdi;
  final String? talepNotu;
  final DateTime? olusturulmaZamani;
  final bool benTalepEdenim;
  final bool benHedefim;

  AktifDevirTalebiModel({
    required this.id,
    required this.rol,
    required this.durum,
    required this.talepEdenAntrenorId,
    required this.talepEdenAntrenorAdi,
    required this.hedefAntrenorId,
    required this.hedefAntrenorAdi,
    this.talepNotu,
    this.olusturulmaZamani,
    required this.benTalepEdenim,
    required this.benHedefim,
  });

  factory AktifDevirTalebiModel.fromMap(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return AktifDevirTalebiModel(
      id: asInt(j['id']),
      rol: j['rol']?.toString() ?? '',
      durum: j['durum']?.toString() ?? '',
      talepEdenAntrenorId: asInt(j['talep_eden_antrenor_id']),
      talepEdenAntrenorAdi: j['talep_eden_antrenor_adi']?.toString() ?? '',
      hedefAntrenorId: asInt(j['hedef_antrenor_id']),
      hedefAntrenorAdi: j['hedef_antrenor_adi']?.toString() ?? '',
      talepNotu: j['talep_notu']?.toString(),
      olusturulmaZamani: parseDate(j['olusturulma_zamani']),
      benTalepEdenim: (j['ben_talep_edenim'] ?? false) == true,
      benHedefim: (j['ben_hedefim'] ?? false) == true,
    );
  }

  bool get rolAna => rol == DevirRolu.ana;
  bool get rolYardimci => rol == DevirRolu.yardimci;
  String get rolLabel => rolAna ? 'ana antrenör' : 'yardımcı antrenör';
}

/// Devir için aday antrenör (liste elemanı).
class DevirAdayAntrenorModel {
  final int id;
  final String adi;
  final String soyadi;
  final String adSoyad;
  final String? renk;
  final bool devralabilirMi;
  final String? engelNedeni;

  DevirAdayAntrenorModel({
    required this.id,
    required this.adi,
    required this.soyadi,
    required this.adSoyad,
    this.renk,
    required this.devralabilirMi,
    this.engelNedeni,
  });

  factory DevirAdayAntrenorModel.fromMap(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DevirAdayAntrenorModel(
      id: asInt(j['id']),
      adi: j['adi']?.toString() ?? '',
      soyadi: j['soyadi']?.toString() ?? '',
      adSoyad: j['ad_soyad']?.toString() ?? '',
      renk: j['renk']?.toString(),
      devralabilirMi: (j['devralabilir_mi'] ?? false) == true,
      engelNedeni: j['engel_nedeni']?.toString(),
    );
  }
}

/// `getDersIcinAntrenorListesi` endpoint cevabı.
class DevirAdayAntrenorListesiDto {
  final String rol; // talep edenin bu derste rolü
  final List<DevirAdayAntrenorModel> antrenorler;

  DevirAdayAntrenorListesiDto({
    required this.rol,
    required this.antrenorler,
  });

  factory DevirAdayAntrenorListesiDto.fromMap(Map<String, dynamic> j) {
    final list = (j['antrenorler'] as List?) ?? const [];
    return DevirAdayAntrenorListesiDto(
      rol: j['rol']?.toString() ?? '',
      antrenorler: list
          .map((e) => DevirAdayAntrenorModel.fromMap(
              (e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Devir talebi detay ekranı için tam talep bilgisi.
class DevirTalebiDetayDto {
  final DevirTalebiTam talep;
  final DevirTalebiEtkinlikInfo etkinlik;
  final List<DevirTalebiKatilimciInfo> katilimcilar;
  final DevirTalebiDigerRolAntrenor? digerRolAntrenor;

  DevirTalebiDetayDto({
    required this.talep,
    required this.etkinlik,
    required this.katilimcilar,
    this.digerRolAntrenor,
  });

  factory DevirTalebiDetayDto.fromMap(Map<String, dynamic> j) {
    final katList = (j['katilimcilar'] as List?) ?? const [];
    final dynamic dr = j['diger_rol_antrenor'];
    return DevirTalebiDetayDto(
      talep:
          DevirTalebiTam.fromMap((j['talep'] as Map).cast<String, dynamic>()),
      etkinlik: DevirTalebiEtkinlikInfo.fromMap(
          (j['etkinlik'] as Map).cast<String, dynamic>()),
      katilimcilar: katList
          .map((e) => DevirTalebiKatilimciInfo.fromMap(
              (e as Map).cast<String, dynamic>()))
          .toList(),
      digerRolAntrenor: (dr is Map<String, dynamic>)
          ? DevirTalebiDigerRolAntrenor.fromMap(dr)
          : null,
    );
  }
}

class DevirTalebiTam {
  final int id;
  final String rol;
  final String rolLabel;
  final String durum;
  final int talepEdenAntrenorId;
  final String talepEdenAntrenorAdi;
  final int hedefAntrenorId;
  final String hedefAntrenorAdi;
  final String? talepNotu;
  final String? cevapNotu;
  final DateTime? olusturulmaZamani;
  final DateTime? cevapTarihi;
  final bool benTalepEdenim;
  final bool benHedefim;
  final bool devralabilirMi;
  final String? engelNedeni;
  final bool suresiGecti;

  DevirTalebiTam({
    required this.id,
    required this.rol,
    required this.rolLabel,
    required this.durum,
    required this.talepEdenAntrenorId,
    required this.talepEdenAntrenorAdi,
    required this.hedefAntrenorId,
    required this.hedefAntrenorAdi,
    this.talepNotu,
    this.cevapNotu,
    this.olusturulmaZamani,
    this.cevapTarihi,
    required this.benTalepEdenim,
    required this.benHedefim,
    required this.devralabilirMi,
    this.engelNedeni,
    required this.suresiGecti,
  });

  factory DevirTalebiTam.fromMap(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : DateTime.tryParse(s);
    }

    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return DevirTalebiTam(
      id: asInt(j['id']),
      rol: j['rol']?.toString() ?? '',
      rolLabel: j['rol_label']?.toString() ?? '',
      durum: j['durum']?.toString() ?? '',
      talepEdenAntrenorId: asInt(j['talep_eden_antrenor_id']),
      talepEdenAntrenorAdi: j['talep_eden_antrenor_adi']?.toString() ?? '',
      hedefAntrenorId: asInt(j['hedef_antrenor_id']),
      hedefAntrenorAdi: j['hedef_antrenor_adi']?.toString() ?? '',
      talepNotu: j['talep_notu']?.toString(),
      cevapNotu: j['cevap_notu']?.toString(),
      olusturulmaZamani: parseDate(j['olusturulma_zamani']),
      cevapTarihi: parseDate(j['cevap_tarihi']),
      benTalepEdenim: (j['ben_talep_edenim'] ?? false) == true,
      benHedefim: (j['ben_hedefim'] ?? false) == true,
      devralabilirMi: (j['devralabilir_mi'] ?? false) == true,
      engelNedeni: j['engel_nedeni']?.toString(),
      suresiGecti: (j['suresi_gecti'] ?? false) == true,
    );
  }
}

class DevirTalebiEtkinlikInfo {
  final int id;
  final DateTime baslangicTarihSaat;
  final DateTime bitisTarihSaat;
  final String tarih;
  final String saat;
  final String kortAdi;
  final String urunAdi;
  final String seviye;
  final bool iptalMi;

  DevirTalebiEtkinlikInfo({
    required this.id,
    required this.baslangicTarihSaat,
    required this.bitisTarihSaat,
    required this.tarih,
    required this.saat,
    required this.kortAdi,
    required this.urunAdi,
    required this.seviye,
    required this.iptalMi,
  });

  factory DevirTalebiEtkinlikInfo.fromMap(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DevirTalebiEtkinlikInfo(
      id: asInt(j['id']),
      baslangicTarihSaat: DateTime.parse(j['baslangic_tarih_saat']),
      bitisTarihSaat: DateTime.parse(j['bitis_tarih_saat']),
      tarih: j['tarih']?.toString() ?? '',
      saat: j['saat']?.toString() ?? '',
      kortAdi: j['kort_adi']?.toString() ?? '',
      urunAdi: j['urun_adi']?.toString() ?? '',
      seviye: j['seviye']?.toString() ?? '',
      iptalMi: (j['iptal_mi'] ?? false) == true,
    );
  }
}

class DevirTalebiKatilimciInfo {
  final int id;
  final String ad;
  final String soyad;
  final String adSoyad;
  final String? telefon;

  DevirTalebiKatilimciInfo({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.adSoyad,
    this.telefon,
  });

  factory DevirTalebiKatilimciInfo.fromMap(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DevirTalebiKatilimciInfo(
      id: asInt(j['id']),
      ad: j['ad']?.toString() ?? '',
      soyad: j['soyad']?.toString() ?? '',
      adSoyad: j['ad_soyad']?.toString() ?? '',
      telefon: j['telefon']?.toString(),
    );
  }
}

class DevirTalebiDigerRolAntrenor {
  final int id;
  final String adSoyad;
  final String rol;
  final String rolLabel;

  DevirTalebiDigerRolAntrenor({
    required this.id,
    required this.adSoyad,
    required this.rol,
    required this.rolLabel,
  });

  factory DevirTalebiDigerRolAntrenor.fromMap(Map<String, dynamic> j) {
    int asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DevirTalebiDigerRolAntrenor(
      id: asInt(j['id']),
      adSoyad: j['ad_soyad']?.toString() ?? '',
      rol: j['rol']?.toString() ?? '',
      rolLabel: j['rol_label']?.toString() ?? '',
    );
  }
}
