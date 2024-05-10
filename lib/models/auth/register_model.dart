import 'package:fitcall/common/generic_form_builder.dart';

class TemelBilgilerModel {
  String? adi;
  String? soyadi;
  int? kimlikNo;
  String? cinsiyet;
  String? telefon;
  String? email;
  String? adres;
  String? seviyeRengi;
  int? uyeTipi;

  TemelBilgilerModel({
    this.adi,
    this.soyadi,
    this.kimlikNo,
    this.cinsiyet,
    this.telefon,
    this.email,
    this.adres,
    this.seviyeRengi,
    this.uyeTipi,
  });

  factory TemelBilgilerModel.fromJson(Map<String, dynamic> json) {
    return TemelBilgilerModel(
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      kimlikNo: json['kimlikNo'] ?? '',
      cinsiyet: json['cinsiyet'] ?? '',
      telefon: json['telefon'] ?? '',
      email: json['email'] ?? '',
      adres: json['adres'] ?? '',
      seviyeRengi: json['seviyeRengi'] ?? '',
      uyeTipi: json['uyeTipi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adi': adi,
      'soyadi': soyadi,
      'kimlikNo': kimlikNo,
      'cinsiyet': cinsiyet,
      'telefon': telefon,
      'email': email,
      'adres': adres,
      'seviyeRengi': seviyeRengi,
      'uyeTipi': uyeTipi,
    };
  }

  static final Map<String, FieldMetaData> metaData = {
    'adi': const FieldMetaData(label: 'Adı', type: String),
    'soyadi': const FieldMetaData(label: 'Soyadı', type: String),
    'kimlikNo': const FieldMetaData(label: 'Kimlik Numarası', type: String),
    'cinsiyet': const FieldMetaData(label: 'Cinsiyet', type: String),
    'telefon': const FieldMetaData(label: 'Telefon', type: String),
    'email': const FieldMetaData(label: 'E-mail', type: String),
    'adres': const FieldMetaData(label: 'Adres', type: String),
    'seviyeRengi': const FieldMetaData(label: 'Seviye Rengi', type: String),
    'uyeTipi': const FieldMetaData(label: 'Üye Tipi', type: int),
  };
}

class ProfilBilgilerModel {
  DateTime? dogumTarihi;
  String? tenisGecmisiVarMi;
  String? dogumYeri;
  String? meslek;
  String? anneAdiSoyadi;
  String? anneTelefon;
  String? anneMail;
  String? anneMeslek;
  String? babaAdiSoyadi;
  String? babaTelefon;
  String? babaMail;
  String? babaMeslek;
  String? profilFotografi;
  String? referansi;

  ProfilBilgilerModel({
    this.dogumTarihi,
    this.dogumYeri,
    this.meslek,
    this.anneAdiSoyadi,
    this.anneTelefon,
    this.anneMail,
    this.anneMeslek,
    this.babaAdiSoyadi,
    this.babaTelefon,
    this.babaMail,
    this.babaMeslek,
    this.referansi,
  });

  factory ProfilBilgilerModel.fromJson(Map<String, dynamic> json) {
    return ProfilBilgilerModel(
      dogumTarihi: json['dogumTarihi'] != null
          ? DateTime.parse(json['dogumTarihi'])
          : null,
      dogumYeri: json['dogumYeri'],
      meslek: json['meslek'],
      anneAdiSoyadi: json['anneAdiSoyadi'],
      anneTelefon: json['anneTelefon'],
      anneMail: json['anneMail'],
      anneMeslek: json['anneMeslek'],
      babaAdiSoyadi: json['babaAdiSoyadi'],
      babaTelefon: json['babaTelefon'],
      babaMail: json['babaMail'],
      babaMeslek: json['babaMeslek'],
      referansi: json['referansi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dogumTarihi': dogumTarihi?.toIso8601String(),
      'dogumYeri': dogumYeri,
      'meslek': meslek,
      'anneAdiSoyadi': anneAdiSoyadi,
      'anneTelefon': anneTelefon,
      'anneMail': anneMail,
      'anneMeslek': anneMeslek,
      'babaAdiSoyadi': babaAdiSoyadi,
      'babaTelefon': babaTelefon,
      'babaMail': babaMail,
      'babaMeslek': babaMeslek,
      'referansi': referansi,
    };
  }

  static final Map<String, FieldMetaData> metaData = {
    'dogumTarihi': const FieldMetaData(label: 'Doğum Tarihi', type: DateTime),
    'dogumYeri': const FieldMetaData(label: 'Doğum Yeri', type: String),
    'meslek': const FieldMetaData(label: 'Meslek', type: String),
    'anneAdiSoyadi':
        const FieldMetaData(label: 'Anne Adı Soyadı', type: String),
    'anneTelefon': const FieldMetaData(label: 'Anne Telefon', type: String),
    'anneMail': const FieldMetaData(label: 'Anne E-mail', type: String),
    'anneMeslek': const FieldMetaData(label: 'Anne Meslek', type: String),
    'babaAdiSoyadi':
        const FieldMetaData(label: 'Baba Adı Soyadı', type: String),
    'babaTelefon': const FieldMetaData(label: 'Baba Telefon', type: String),
    'babaMail': const FieldMetaData(label: 'Baba E-mail', type: String),
    'babaMeslek': const FieldMetaData(label: 'Baba Meslek', type: String),
    'referansi': const FieldMetaData(label: 'Referansı', type: String),
  };
}
