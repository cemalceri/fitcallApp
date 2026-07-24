// lib/models/2_uye/para_hareket_model.dart
// Django: calendarapp.models.concrete.para_hareket.ParaHareketiModel
// Alanlar bire-bir; BaseAbstract alanları dâhil.

import 'package:fitcall/common/tarih_util.dart';
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

  /// Django ParaHareketTuruEnum: ALACAK | FARK_ALACAK (borç artıran)
  /// ODEME | INDIRIM | FARK_IADE | IPTAL | IADE (borç azaltan)
  final String hareketTuru;
  final double tutar;
  final String? odemeSekli;
  final DateTime tarih;
  final DateTime? borcTarihi; // borcun oluştuğu tarih (ders tarihi vb.)
  final int? urun;
  final int? uyeUrun; // kaynak ÜyeÜrün (paket) kaydı
  final String? referansKodu;
  final bool isEkstra;
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
    this.borcTarihi,
    this.urun,
    this.uyeUrun,
    this.referansKodu,
    this.isEkstra = false,
    this.aciklama,
  });

  /// Borç azaltan (ödeme yönlü) hareket türleri — Django enum ile birebir
  static const Set<String> odemeYonluTurler = {
    'ODEME',
    'INDIRIM',
    'FARK_IADE',
    'IPTAL',
    'IADE',
  };

  /// Borç artıran hareket türleri
  static const Set<String> borcYonluTurler = {'ALACAK', 'FARK_ALACAK'};

  /// Bu hareket borcu azaltıyor mu? (renk/işaret için tek doğruluk kaynağı)
  bool get odemeYonlu => odemeYonluTurler.contains(hareketTuru);

  /// Kullanıcıya gösterilecek Türkçe etiket
  String get hareketTuruLabel {
    switch (hareketTuru) {
      case 'ALACAK':
        return 'Borç';
      case 'FARK_ALACAK':
        return 'Fark Borcu';
      case 'ODEME':
        return 'Ödeme';
      case 'INDIRIM':
        return 'İndirim';
      case 'FARK_IADE':
        return 'Fark İadesi';
      case 'IPTAL':
        return 'İptal';
      case 'IADE':
        return 'İade';
      default:
        return hareketTuru;
    }
  }

  factory ParaHareketModel.fromJson(Map<String, dynamic> json) {
    DateTime? dtN(dynamic v) =>
        (v == null || '$v'.isEmpty) ? null : parseApiTarih(v.toString());

    return ParaHareketModel(
      id: json['id'],
      isActive: json['is_active'],
      isDeleted: json['is_deleted'],
      olusturulmaZamani: parseApiTarihOrNow(json['olusturulma_zamani']),
      guncellenmeZamani: parseApiTarihOrNow(json['guncellenme_zamani']),
      isletme: json['isletme'],
      ekleyen: json['ekleyen'],
      guncelleyen: json['guncelleyen'],
      uye: json['uye'],
      hareketTuru: json['hareket_turu'],
      tutar: double.parse(json['tutar'].toString()),
      odemeSekli: json['odeme_sekli'],
      tarih: parseApiTarihOrNow(json['tarih']),
      borcTarihi: dtN(json['borc_tarihi']),
      urun: json['urun'],
      uyeUrun: json['uye_urun'],
      referansKodu: json['referans_kodu'],
      isEkstra: json['is_ekstra'] ?? false,
      aciklama: json['aciklama'],
    );
  }

  static List<ParaHareketModel> listFromResponse(String body) =>
      (jsonDecode(body) as List)
          .map((e) => ParaHareketModel.fromJson(e as Map<String, dynamic>))
          .toList();
}
