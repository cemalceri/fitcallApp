/// Üye (sporcu) bilgilerini içeren model
class UyeModel {
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
  final String? telefon;
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
  final String? tenisGecmisiVarMi;
  final String? programTercihi;
  final String? profilFotografi;
  final double indirimOrani;
  final String uyeTuru;
  final bool mobilKayitMi;
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
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
  final int? sorumluHoca;
  final String? okul;
  final List<String> gunler;
  final List<String> saatler;

  UyeModel({
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
    this.telefon,
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
    this.tenisGecmisiVarMi,
    this.programTercihi,
    this.profilFotografi,
    required this.indirimOrani,
    required this.uyeTuru,
    required this.mobilKayitMi,
    this.acilDurumKisi,
    this.acilDurumTelefon,
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
    this.sorumluHoca,
    this.okul,
    required this.gunler,
    required this.saatler,
  });

  factory UyeModel.fromJson(Map<String, dynamic> json) {
    return UyeModel(
      id: json['id'] ?? 0,
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
      telefon: json['telefon'],
      email: json['email'],
      dogumTarihi: json['dogum_tarihi'] != null
          ? DateTime.tryParse(json['dogum_tarihi'])
          : null,
      dogumYeri: json['dogum_yeri'],
      adres: json['adres'] ?? '',
      uyeNo: json['uye_no'] ?? 0,
      seviyeRengi: json['seviye_rengi'] ?? '',
      onaylandiMi: json['onaylandi_mi'] ?? false,
      aktifMi: json['aktif_mi'] ?? false,
      uyeTipi: json['uye_tipi'] ?? 0,
      referansi: json['referansi'] ?? '',
      tenisGecmisiVarMi: json['tenis_gecmisi_var_mi']?.toString(),
      programTercihi: json['program_tercihi']?.toString(),
      profilFotografi: json['profil_fotografi']?.toString(),
      indirimOrani: json['indirim_orani'] != null
          ? (json['indirim_orani'] is int
              ? (json['indirim_orani'] as int).toDouble()
              : json['indirim_orani'].toDouble())
          : 0.0,
      uyeTuru: json['uye_turu'] ?? '',
      mobilKayitMi: json['mobil_kayit_mi'] ?? false,
      acilDurumKisi: json['acil_durum_kisi']?.toString(),
      acilDurumTelefon: json['acil_durum_telefon']?.toString(),
      meslek: json['meslek']?.toString(),
      anneAdiSoyadi: json['anne_adi_soyadi']?.toString(),
      anneTelefon: json['anne_telefon']?.toString(),
      anneMail: json['anne_mail']?.toString(),
      anneMeslek: json['anne_meslek']?.toString(),
      babaAdiSoyadi: json['baba_adi_soyadi']?.toString(),
      babaTelefon: json['baba_telefon']?.toString(),
      babaMail: json['baba_mail']?.toString(),
      babaMeslek: json['baba_meslek']?.toString(),
      user: json['user'] ?? 0,
      kullaniciHesabi: json['kullanici_hesabi'] ?? 0,
      sorumluHoca: json['sorumlu_hoca'],
      okul: json['okul']?.toString(),
      gunler: json['gunler'] != null ? List<String>.from(json['gunler']) : [],
      saatler:
          json['saatler'] != null ? List<String>.from(json['saatler']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'isletme': isletme,
      'adi': adi,
      'soyadi': soyadi,
      'kimlik_no': kimlikNo,
      'cinsiyet': cinsiyet,
      'telefon': telefon,
      'email': email,
      'dogum_tarihi': dogumTarihi?.toIso8601String(),
      'dogum_yeri': dogumYeri,
      'adres': adres,
      'uye_no': uyeNo,
      'seviye_rengi': seviyeRengi,
      'onaylandi_mi': onaylandiMi,
      'aktif_mi': aktifMi,
      'uye_tipi': uyeTipi,
      'referansi': referansi,
      'tenis_gecmisi_var_mi': tenisGecmisiVarMi,
      'program_tercihi': programTercihi,
      'profil_fotografi': profilFotografi,
      'indirim_orani': indirimOrani,
      'uye_turu': uyeTuru,
      'mobil_kayit_mi': mobilKayitMi,
      'acil_durum_kisi': acilDurumKisi,
      'acil_durum_telefon': acilDurumTelefon,
      'meslek': meslek,
      'anne_adi_soyadi': anneAdiSoyadi,
      'anne_telefon': anneTelefon,
      'anne_mail': anneMail,
      'anne_meslek': anneMeslek,
      'baba_adi_soyadi': babaAdiSoyadi,
      'baba_telefon': babaTelefon,
      'baba_mail': babaMail,
      'baba_meslek': babaMeslek,
      'user': user,
      'kullanici_hesabi': kullaniciHesabi,
      'sorumlu_hoca': sorumluHoca,
      'okul': okul,
      'gunler': gunler,
      'saatler': saatler,
    };
  }
}
