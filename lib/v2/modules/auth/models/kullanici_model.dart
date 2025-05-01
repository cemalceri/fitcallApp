// lib/models/kullanici_model.dart

class KullaniciModel {
  final int id;
  final String sifre;
  final DateTime? sonGirisZamani;
  final bool superuserMi;
  final String kullaniciAdi;
  final String ad;
  final String soyad;
  final String eposta;
  final bool personelMi;
  final bool aktifMi;
  final DateTime kayitTarihi;
  final List<int> gruplar;
  final List<int> kullaniciIzinleri;

  KullaniciModel({
    required this.id,
    required this.sifre,
    this.sonGirisZamani,
    required this.superuserMi,
    required this.kullaniciAdi,
    required this.ad,
    required this.soyad,
    required this.eposta,
    required this.personelMi,
    required this.aktifMi,
    required this.kayitTarihi,
    required this.gruplar,
    required this.kullaniciIzinleri,
  });

  factory KullaniciModel.fromJson(Map<String, dynamic> json) => KullaniciModel(
        id: json['id'] as int,
        sifre: json['password'] as String,
        sonGirisZamani: json['last_login'] != null
            ? DateTime.parse(json['last_login'] as String)
            : null,
        superuserMi: json['is_superuser'] as bool,
        kullaniciAdi: json['username'] as String,
        ad: json['first_name'] as String,
        soyad: json['last_name'] as String,
        eposta: json['email'] as String,
        personelMi: json['is_staff'] as bool,
        aktifMi: json['is_active'] as bool,
        kayitTarihi: DateTime.parse(json['date_joined'] as String),
        gruplar: List<int>.from(json['groups'] as List<dynamic>),
        kullaniciIzinleri:
            List<int>.from(json['user_permissions'] as List<dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'password': sifre,
        'last_login': sonGirisZamani?.toIso8601String(),
        'is_superuser': superuserMi,
        'username': kullaniciAdi,
        'first_name': ad,
        'last_name': soyad,
        'email': eposta,
        'is_staff': personelMi,
        'is_active': aktifMi,
        'date_joined': kayitTarihi.toIso8601String(),
        'groups': gruplar,
        'user_permissions': kullaniciIzinleri,
      };
}
