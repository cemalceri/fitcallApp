class DersZamanDilimiModel {
  final int gun;
  final List<String> saatler;

  DersZamanDilimiModel({required this.gun, required this.saatler});

  factory DersZamanDilimiModel.fromJson(Map<String, dynamic> json) {
    final int gun = json['gun'] as int;
    List<String> saatler;
    if (json.containsKey('saatler') && json['saatler'] != null) {
      saatler = List<String>.from(json['saatler']);
    } else if (json.containsKey('baslangic') && json['baslangic'] != null) {
      saatler = [json['baslangic'].toString()];
    } else {
      saatler = [];
    }
    return DersZamanDilimiModel(gun: gun, saatler: saatler);
  }

  Map<String, dynamic> toJson() => {
        'gun': gun,
        'saatler': saatler,
      };
}

class DersTalebiModel {
  final int? id;
  final String? uye;
  final String? misafir;
  final String? seviye;
  final String? referans;
  final int? antrenor;
  final bool aktifMi;
  final String? aciklama;
  final int? user;
  final List<DersZamanDilimiModel> zamanDilimleri;

  DersTalebiModel({
    this.id,
    this.uye,
    this.misafir,
    this.seviye,
    this.referans,
    this.antrenor,
    required this.aktifMi,
    this.aciklama,
    this.user,
    required this.zamanDilimleri,
  });

  factory DersTalebiModel.fromJson(Map<String, dynamic> json) {
    var zamanList = json['zaman_dilimleri'] as List<dynamic>? ?? [];
    List<DersZamanDilimiModel> zamanDilimleri = zamanList
        .map((e) => DersZamanDilimiModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return DersTalebiModel(
      id: json['id'] as int?,
      uye: json['uye']?.toString(),
      misafir: json['misafir'] as String?,
      seviye: json['seviye'] as String,
      referans: json['referans'] as String?,
      antrenor: json['antrenor'] as int?,
      aktifMi: json['aktif_mi'] as bool,
      aciklama: json['aciklama'] as String?,
      user: json['user'] as int?,
      zamanDilimleri: zamanDilimleri,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uye': uye,
        'misafir': misafir,
        'seviye': seviye,
        'referans': referans,
        'antrenor': antrenor,
        'aktif_mi': aktifMi,
        'aciklama': aciklama,
        'user': user,
        'zaman_dilimleri': zamanDilimleri.map((e) => e.toJson()).toList(),
      };
}
