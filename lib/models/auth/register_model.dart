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
}
