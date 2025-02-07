// ignore_for_file: non_constant_identifier_names

class TemelBilgilerModel {
  String? adi;
  String? soyadi;
  String? kullanici_adi;
  String? sifre;
  String? sifre_tekrar;
  int? kimlik_no;
  String? cinsiyet;
  String? telefon;
  String? email;
  String? adres;
  String? seviye_rengi;
  int? uye_tipi;

  TemelBilgilerModel({
    this.adi,
    this.soyadi,
    this.kullanici_adi,
    this.sifre,
    this.sifre_tekrar,
    this.kimlik_no,
    this.cinsiyet,
    this.telefon,
    this.email,
    this.adres,
    this.seviye_rengi,
    this.uye_tipi,
  });

  factory TemelBilgilerModel.fromJson(Map<String, dynamic> json) {
    return TemelBilgilerModel(
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      kimlik_no: json['kimlik_no'] ?? '',
      kullanici_adi: json['kullanici_adi'] ?? '',
      cinsiyet: json['cinsiyet'] ?? '',
      telefon: json['telefon'] ?? '',
      email: json['email'] ?? '',
      adres: json['adres'] ?? '',
      seviye_rengi: json['seviye_rengi'] ?? '',
      uye_tipi: json['uye_tipi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adi': adi,
      'soyadi': soyadi,
      'kullanici_adi': kullanici_adi,
      'sifre': sifre,
      'sifre_tekrar': sifre_tekrar,
      'kimlikNo': kimlik_no,
      'cinsiyet': cinsiyet,
      'telefon': telefon,
      'email': email,
      'adres': adres,
      'seviye_rengi': seviye_rengi,
      'uye_tipi': uye_tipi,
    };
  }
}

class ProfilBilgilerModel {
  DateTime? dogum_tarihi;
  String? tenis_gecmisi_var_mi;
  String? dogum_yeri;
  String? meslek;
  String? anne_adi_soyadi;
  String? anne_telefon;
  String? anne_mail;
  String? anneMeslek;
  String? baba_adi_soyadi;
  String? anne_meslek;
  String? baba_mail;
  String? baba_meslek;
  String? profilFotografi;
  String? referansi;

  ProfilBilgilerModel({
    this.dogum_tarihi,
    this.tenis_gecmisi_var_mi,
    this.dogum_yeri,
    this.meslek,
    this.anne_adi_soyadi,
    this.anne_telefon,
    this.anne_mail,
    this.anneMeslek,
    this.baba_adi_soyadi,
    this.anne_meslek,
    this.baba_mail,
    this.baba_meslek,
    this.profilFotografi,
    this.referansi,
  });

  factory ProfilBilgilerModel.fromJson(Map<String, dynamic> json) {
    return ProfilBilgilerModel(
      dogum_tarihi: json['dogumTarihi'] != null
          ? DateTime.parse(json['dogumTarihi'])
          : null,
      tenis_gecmisi_var_mi: json['tenisGecmisiVarMi'] ?? '',
      dogum_yeri: json['dogumYeri'] ?? '',
      meslek: json['meslek'] ?? '',
      anne_adi_soyadi: json['anneAdiSoyadi'] ?? '',
      anne_telefon: json['anneTelefon'] ?? '',
      anne_mail: json['anneMail'] ?? '',
      anneMeslek: json['anneMeslek'] ?? '',
      baba_adi_soyadi: json['babaAdiSoyadi'] ?? '',
      anne_meslek: json['anneMeslek'] ?? '',
      baba_mail: json['babaMail'] ?? '',
      baba_meslek: json['babaMeslek'] ?? '',
      referansi: json['referansi'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dogum_tarihi": dogum_tarihi?.toIso8601String(),
      "tenis_gecmisi_var_mi": tenis_gecmisi_var_mi,
      "dogum_yeri": dogum_yeri,
      "meslek": meslek,
      "anne_adi_soyadi": anne_adi_soyadi,
      "anne_telefon": anne_telefon,
      "anne_mail": anne_mail,
      "anneMeslek": anneMeslek,
      "baba_adi_soyadi": baba_adi_soyadi,
      "anne_meslek": anne_meslek,
      "baba_mail": baba_mail,
      "baba_meslek": baba_meslek,
    };
  }
}
