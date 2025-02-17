import 'dart:convert';

class OdemeBorcModel {
  int id;
  bool isActive;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;
  dynamic isletme; // null veya başka tipte veri olabilir
  String hareketTuru;
  String ucretTuru;
  String tutar;
  dynamic odemeSekli; // null veya başka tipte veri olabilir
  DateTime tarih;
  String aciklama;
  int uye;
  dynamic paket; // null veya başka tipte veri olabilir
  dynamic abonelik; // null veya başka tipte veri olabilir
  int etkinlik;
  dynamic user; // null veya başka tipte veri olabilir

  OdemeBorcModel({
    required this.id,
    required this.isActive,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.isletme,
    required this.hareketTuru,
    required this.ucretTuru,
    required this.tutar,
    this.odemeSekli,
    required this.tarih,
    required this.aciklama,
    required this.uye,
    this.paket,
    this.abonelik,
    required this.etkinlik,
    this.user,
  });

  factory OdemeBorcModel.fromJson(Map<String, dynamic> jsonData) {
    return OdemeBorcModel(
      id: jsonData['id'] ?? 0,
      isActive: jsonData['is_active'] ?? false,
      isDeleted: jsonData['is_deleted'] ?? false,
      createdAt: DateTime.parse(jsonData['created_at']),
      updatedAt: DateTime.parse(jsonData['updated_at']),
      isletme: jsonData['isletme'],
      hareketTuru: jsonData['hareket_turu'] ?? '',
      ucretTuru: jsonData['ucret_turu'] ?? '',
      tutar: jsonData['tutar'] ?? '',
      odemeSekli: jsonData['odeme_sekli'],
      tarih: DateTime.parse(jsonData['tarih']),
      aciklama: jsonData['aciklama'] ?? '',
      uye: jsonData['uye'] ?? 0,
      paket: jsonData['paket'],
      abonelik: jsonData['abonelik'],
      etkinlik: jsonData['etkinlik'] ?? 0,
      user: jsonData['user'],
    );
  }

  static List<OdemeBorcModel?> fromJsonList(String responseBody) {
    final List<dynamic> parsedList = json.decode(responseBody);
    return parsedList
        .map((jsonData) => OdemeBorcModel.fromJson(jsonData))
        .toList();
  }
}
