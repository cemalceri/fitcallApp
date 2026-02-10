class TelafiDersModel {
  final int id;
  final IptalEdilenDers? iptalEdilenDers;
  final YapilanDers? yapilanDers;
  final String durum; // "aktif" | "yapildi" | "suresi_doldu"
  final int kalanGun;
  final String sonGecerlilikTarihi;
  final String? aciklama;
  final String? yapilmaAciklama;
  final int? uyeId;
  final int? urunId;

  TelafiDersModel({
    required this.id,
    this.iptalEdilenDers,
    this.yapilanDers,
    required this.durum,
    required this.kalanGun,
    required this.sonGecerlilikTarihi,
    this.aciklama,
    this.yapilmaAciklama,
    this.uyeId,
    this.urunId,
  });

  factory TelafiDersModel.fromJson(Map<String, dynamic> json) {
    return TelafiDersModel(
      id: json['id'] as int,
      iptalEdilenDers: json['iptal_edilen_ders'] != null
          ? IptalEdilenDers.fromJson(
              json['iptal_edilen_ders'] as Map<String, dynamic>)
          : null,
      yapilanDers: json['yapilan_ders'] != null
          ? YapilanDers.fromJson(json['yapilan_ders'] as Map<String, dynamic>)
          : null,
      durum: json['durum'] as String? ?? 'aktif',
      kalanGun: json['kalan_gun'] as int? ?? 0,
      sonGecerlilikTarihi: json['son_gecerlilik_tarihi'] as String? ?? '',
      aciklama: json['aciklama'] as String?,
      yapilmaAciklama: json['yapilma_aciklama'] as String?,
      uyeId: json['uye'] as int?,
      urunId: json['urun'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'iptal_edilen_ders': iptalEdilenDers?.toJson(),
      'yapilan_ders': yapilanDers?.toJson(),
      'durum': durum,
      'kalan_gun': kalanGun,
      'son_gecerlilik_tarihi': sonGecerlilikTarihi,
      'aciklama': aciklama,
      'yapilma_aciklama': yapilmaAciklama,
      'uye': uyeId,
      'urun': urunId,
    };
  }
}

class IptalEdilenDers {
  final String kortAdi;
  final String? antrenorAdi;
  final String tarih;
  final String saat;

  IptalEdilenDers({
    required this.kortAdi,
    this.antrenorAdi,
    required this.tarih,
    required this.saat,
  });

  factory IptalEdilenDers.fromJson(Map<String, dynamic> json) {
    return IptalEdilenDers(
      kortAdi: json['kort_adi'] as String? ?? 'Belirtilmemiş',
      antrenorAdi: json['antrenor_adi'] as String?,
      tarih: json['tarih'] as String? ?? '',
      saat: json['saat'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kort_adi': kortAdi,
      'antrenor_adi': antrenorAdi,
      'tarih': tarih,
      'saat': saat,
    };
  }
}

class YapilanDers {
  final String kortAdi;
  final String? antrenorAdi;
  final String tarih;
  final String saat;

  YapilanDers({
    required this.kortAdi,
    this.antrenorAdi,
    required this.tarih,
    required this.saat,
  });

  factory YapilanDers.fromJson(Map<String, dynamic> json) {
    return YapilanDers(
      kortAdi: json['kort_adi'] as String? ?? 'Belirtilmemiş',
      antrenorAdi: json['antrenor_adi'] as String?,
      tarih: json['tarih'] as String? ?? '',
      saat: json['saat'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kort_adi': kortAdi,
      'antrenor_adi': antrenorAdi,
      'tarih': tarih,
      'saat': saat,
    };
  }
}
