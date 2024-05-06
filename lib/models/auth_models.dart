class LoginModel {
  String username;
  String password;

  LoginModel({required this.username, required this.password});
}

class UserModel {
  final int id;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int isletme;
  final String adi;
  final String soyadi;
  final String? kimlikNo;
  final String cinsiyet;
  final String telefon;
  final String? email;
  final DateTime? dogumTarihi;
  final String? dogumYeri;
  final String adres;
  final int uyeNo;
  final String seviyeRengi;
  final bool onaylandiMi;
  final bool aktifMi;
  final int uyeTipi;
  final String referansi;
  final String tenisGecmisiVarMi;
  final String? programTercihi;
  final String? profilFotografi;
  final double indirimOrani;
  final String uyeTuru;
  final String? meslek;
  final String? anneAdiSoyadi;
  final String? anneTelefon;
  final String? anneMail;
  final String? anneMeslek;
  final String? babaAdiSoyadi;
  final String? babaTelefon;
  final String? babaMail;
  final String? babaMeslek;
  final int user;
  final int kullaniciHesabi;
  final List<String> gunler;
  final List<String> saatler;

  UserModel({
    required this.id,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.isletme,
    required this.adi,
    required this.soyadi,
    this.kimlikNo,
    required this.cinsiyet,
    required this.telefon,
    this.email,
    this.dogumTarihi,
    this.dogumYeri,
    required this.adres,
    required this.uyeNo,
    required this.seviyeRengi,
    required this.onaylandiMi,
    required this.aktifMi,
    required this.uyeTipi,
    required this.referansi,
    required this.tenisGecmisiVarMi,
    this.programTercihi,
    this.profilFotografi,
    required this.indirimOrani,
    required this.uyeTuru,
    this.meslek,
    this.anneAdiSoyadi,
    this.anneTelefon,
    this.anneMail,
    this.anneMeslek,
    this.babaAdiSoyadi,
    this.babaTelefon,
    this.babaMail,
    this.babaMeslek,
    required this.user,
    required this.kullaniciHesabi,
    required this.gunler,
    required this.saatler,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      isActive: json['is_active'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isletme: json['isletme'] ?? 0,
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      kimlikNo: json['kimlik_no'],
      cinsiyet: json['cinsiyet'] ?? '',
      telefon: json['telefon'] ?? '',
      email: json['email'],
      dogumTarihi: json['dogum_tarihi'] != null
          ? DateTime.parse(json['dogum_tarihi'])
          : null,
      dogumYeri: json['dogum_yeri'] ?? '',
      adres: json['adres'] ?? '',
      uyeNo: json['uye_no'] ?? 0,
      seviyeRengi: json['seviye_rengi'] ?? '',
      onaylandiMi: json['onaylandi_mi'] ?? false,
      aktifMi: json['aktif_mi'] ?? false,
      uyeTipi: json['uye_tipi'] ?? 0,
      referansi: json['referansi'] ?? '',
      tenisGecmisiVarMi: json['tenis_gecmisi_var_mi'] ?? '',
      programTercihi: json['program_tercihi'] ?? '',
      profilFotografi: json['profil_fotografi'],
      indirimOrani: json['indirim_orani'] != null
          ? json['indirim_orani'].toDouble()
          : 0.0,
      uyeTuru: json['uye_turu'] ?? '',
      meslek: json['meslek'],
      anneAdiSoyadi: json['anne_adi_soyadi'],
      anneTelefon: json['anne_telefon'],
      anneMail: json['anne_mail'],
      anneMeslek: json['anne_meslek'],
      babaAdiSoyadi: json['baba_adi_soyadi'],
      babaTelefon: json['baba_telefon'],
      babaMail: json['baba_mail'],
      babaMeslek: json['baba_meslek'],
      user: json['user'] ?? 0,
      kullaniciHesabi: json['kullanici_hesabi'] ?? 0,
      gunler: json['gunler'] != null ? List<String>.from(json['gunler']) : [],
      saatler:
          json['saatler'] != null ? List<String>.from(json['saatler']) : [],
    );
  }

  toJson() {
    return {
      'id': id,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isletme': isletme,
      'adi': adi,
      'soyadi': soyadi,
      'kimlikNo': kimlikNo,
      'cinsiyet': cinsiyet,
      'telefon': telefon,
      'email': email,
      'dogumTarihi': dogumTarihi,
      'dogumYeri': dogumYeri,
      'adres': adres,
      'uyeNo': uyeNo,
      'seviyeRengi': seviyeRengi,
      'onaylandiMi': onaylandiMi,
      'aktifMi': aktifMi,
      'uyeTipi': uyeTipi,
      'referansi': referansi,
      'tenisGecmisiVarMi': tenisGecmisiVarMi,
      'programTercihi': programTercihi,
      'profilFotografi': profilFotografi,
      'indirimOrani': indirimOrani,
      'uyeTuru': uyeTuru,
      'meslek': meslek,
      'anneAdiSoyadi': anneAdiSoyadi,
      'anneTelefon': anneTelefon,
      'anneMail': anneMail,
      'anneMeslek': anneMeslek,
      'babaAdiSoyadi': babaAdiSoyadi,
      'babaTelefon': babaTelefon,
      'babaMail': babaMail,
      'babaMeslek': babaMeslek,
      'user': user,
      'kullaniciHesabi': kullaniciHesabi,
      'gunler': gunler,
      'saatler': saatler,
    };
  }
}
