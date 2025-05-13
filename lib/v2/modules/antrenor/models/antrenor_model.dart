// lib/models/antrenor_model.dart
import 'package:fitcall/v2/shared/models/base_model.dart';

enum HaftaGunleri {
  pazartesi(1),
  sali(2),
  carsamba(3),
  persembe(4),
  cuma(5),
  cumartesi(6),
  pazar(7);

  final int value;
  const HaftaGunleri(this.value);
  factory HaftaGunleri.fromValue(int v) =>
      HaftaGunleri.values.firstWhere((e) => e.value == v);
}

class AntrenorModel extends BaseModel {
  final String adi;
  final String soyadi;
  final String? eposta;
  final String? telefon;
  final String renk;
  final double ucretKatsayisi;
  final int? userId;
  final int? ekleyenId;
  final int? guncelleyenId;

  AntrenorModel({
    required super.id,
    required super.olusturulmaZamani,
    required super.guncellenmeZamani,
    required super.isletmeId,
    required this.adi,
    required this.soyadi,
    this.eposta,
    this.telefon,
    required this.renk,
    required this.ucretKatsayisi,
    this.userId,
    this.ekleyenId,
    this.guncelleyenId,
  });

  factory AntrenorModel.fromJson(Map<String, dynamic> json) => AntrenorModel(
        id: json['id'] as int,
        olusturulmaZamani: DateTime.parse(json['olusturulma_zamani'] as String),
        guncellenmeZamani: DateTime.parse(json['guncellenme_zamani'] as String),
        isletmeId: json['isletme'] as int,
        adi: json['adi'] as String,
        soyadi: json['soyadi'] as String? ?? '',
        eposta: json['e_posta'] as String?,
        telefon: json['telefon'] as String?,
        renk: json['renk'] as String,
        ucretKatsayisi: (json['ucret_katsayisi'] as num).toDouble(),
        userId: json['user'] as int?,
        ekleyenId: json['ekleyen'] as int?,
        guncelleyenId: json['guncelleyen'] as int?,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'adi': adi,
        'soyadi': soyadi,
        'e_posta': eposta,
        'telefon': telefon,
        'renk': renk,
        'ucret_katsayisi': ucretKatsayisi,
        'user': userId,
        'ekleyen': ekleyenId,
        'guncelleyen': guncelleyenId,
      };
}

class AntrenorCalismaGunuModel {
  final int id;
  final int antrenorId;
  final HaftaGunleri gun;
  final String baslangicSaat;
  final String bitisSaat;

  AntrenorCalismaGunuModel({
    required this.id,
    required this.antrenorId,
    required this.gun,
    required this.baslangicSaat,
    required this.bitisSaat,
  });

  factory AntrenorCalismaGunuModel.fromJson(Map<String, dynamic> json) =>
      AntrenorCalismaGunuModel(
        id: json['id'] as int,
        antrenorId: json['antrenor'] as int,
        gun: HaftaGunleri.fromValue(json['gun'] as int),
        baslangicSaat: json['baslangic_saat'] as String,
        bitisSaat: json['bitis_saat'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'antrenor': antrenorId,
        'gun': gun.value,
        'baslangic_saat': baslangicSaat,
        'bitis_saat': bitisSaat,
      };
}
