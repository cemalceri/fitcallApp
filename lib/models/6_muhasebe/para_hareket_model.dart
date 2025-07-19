// lib/models/2_uye/para_hareket_model.dart
// Django: calendarapp.models.concrete.para_hareket.ParaHareketiModel
// Alanlar bire-bir; BaseAbstract alanları dâhil.

import 'dart:convert';

class ParaHareketModel {
  // ---- BaseAbstract ----
  final int id;
  final bool isActive;
  final bool isDeleted;
  final DateTime olusturulmaZamani;
  final DateTime guncellenmeZamani;
  final int? isletme; // null olabilir
  final int? ekleyen; // null olabilir
  final int? guncelleyen; // null olabilir

  // ---- ParaHareketiModel özgün alanları ----
  final int uye;
  final String hareketTuru; // "Alacak" | "Odeme"
  final double tutar;
  final String? odemeSekli;
  final DateTime tarih;
  final int? urun;
  final String? aciklama;

  const ParaHareketModel({
    required this.id,
    required this.isActive,
    required this.isDeleted,
    required this.olusturulmaZamani,
    required this.guncellenmeZamani,
    this.isletme,
    this.ekleyen,
    this.guncelleyen,
    required this.uye,
    required this.hareketTuru,
    required this.tutar,
    this.odemeSekli,
    required this.tarih,
    this.urun,
    this.aciklama,
  });

  factory ParaHareketModel.fromJson(Map<String, dynamic> json) {
    return ParaHareketModel(
      id: json['id'],
      isActive: json['is_active'],
      isDeleted: json['is_deleted'],
      olusturulmaZamani: DateTime.parse(json['olusturulma_zamani']),
      guncellenmeZamani: DateTime.parse(json['guncellenme_zamani']),
      isletme: json['isletme'],
      ekleyen: json['ekleyen'],
      guncelleyen: json['guncelleyen'],
      uye: json['uye'],
      hareketTuru: json['hareket_turu'],
      tutar: double.parse(json['tutar'].toString()),
      odemeSekli: json['odeme_sekli'],
      tarih: DateTime.parse(json['tarih']),
      urun: json['urun'],
      aciklama: json['aciklama'],
    );
  }

  static List<ParaHareketModel> listFromResponse(String body) =>
      (jsonDecode(body) as List)
          .map((e) => ParaHareketModel.fromJson(e as Map<String, dynamic>))
          .toList();
}
