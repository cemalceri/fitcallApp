class DersZamanDilimi {
  final String gun;
  final String baslangic;
  final String bitis;

  DersZamanDilimi(
      {required this.gun, required this.baslangic, required this.bitis});

  factory DersZamanDilimi.fromJson(Map<String, dynamic> json) =>
      DersZamanDilimi(
          gun: json['gun'] as String,
          baslangic: json['baslangic'] as String,
          bitis: json['bitis'] as String);

  Map<String, dynamic> toJson() =>
      {'gun': gun, 'baslangic': baslangic, 'bitis': bitis};
}

class DersTalebi {
  final String? uye;
  final String? misafir;
  final String? seviye;
  final int? onemDerecesi;
  final String? referans;
  final int? antrenor;
  final bool aktifMi;
  final String? aciklama;
  final int? user;
  final List<DersZamanDilimi> zamanDilimleri;

  DersTalebi({
    this.uye,
    this.misafir,
    this.seviye,
    this.onemDerecesi,
    this.referans,
    this.antrenor,
    required this.aktifMi,
    this.aciklama,
    this.user,
    required this.zamanDilimleri,
  });

  factory DersTalebi.fromJson(Map<String, dynamic> json) {
    var zamanList = json['zaman_dilimleri'] as List<dynamic>;
    List<DersZamanDilimi> zamanDilimleri = zamanList
        .map((e) => DersZamanDilimi.fromJson(e as Map<String, dynamic>))
        .toList();
    return DersTalebi(
      uye: json['uye'] as String?,
      misafir: json['misafir'] as String?,
      seviye: json['seviye'] as String,
      onemDerecesi: json['onem_derecesi'] as int?,
      referans: json['referans'] as String?,
      antrenor: json['antrenor'] as int?,
      aktifMi: json['aktif_mi'] as bool,
      aciklama: json['aciklama'] as String?,
      user: json['user'] as int?,
      zamanDilimleri: zamanDilimleri,
    );
  }

  Map<String, dynamic> toJson() => {
        'uye': uye,
        'misafir': misafir,
        'seviye': seviye,
        'onem_derecesi': onemDerecesi,
        'referans': referans,
        'antrenor': antrenor,
        'aktif_mi': aktifMi,
        'aciklama': aciklama,
        'user': user,
        'zaman_dilimleri': zamanDilimleri.map((e) => e.toJson()).toList(),
      };
}
