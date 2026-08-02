import 'package:fitcall/common/tarih_util.dart';

// lib/models/duyuru/duyuru_model.dart

class DuyuruModel {
  final int id;
  final String baslik;
  final String altBaslik;
  final String icerik;
  final String hedefKitle;
  final String? hedefKitleDisplay;
  final bool onemliMi;
  final String? kapakResmi;
  final int resimSayisi;
  final List<DuyuruResimModel> resimler;
  final DateTime yayinBaslangic;
  final DateTime? yayinBitis;
  final DateTime olusturulmaZamani;
  final DateTime? guncellenmeZamani;

  DuyuruModel({
    required this.id,
    required this.baslik,
    this.altBaslik = '',
    this.icerik = '',
    this.hedefKitle = 'herkes',
    this.hedefKitleDisplay,
    this.onemliMi = false,
    this.kapakResmi,
    this.resimSayisi = 0,
    this.resimler = const [],
    required this.yayinBaslangic,
    this.yayinBitis,
    required this.olusturulmaZamani,
    this.guncellenmeZamani,
  });

  // Helper: DateTime parse
  static DateTime _parseDate(dynamic value) {
    if (value == null) return simdiKulup();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return parseApiTarih(value) ?? simdiKulup();
    }
    return simdiKulup();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return parseApiTarih(value);
    }
    return null;
  }

  factory DuyuruModel.fromMap(Map<String, dynamic> map) {
    // Resimler listesini parse et
    List<DuyuruResimModel> resimler = [];
    if (map['resimler'] != null && map['resimler'] is List) {
      resimler = (map['resimler'] as List)
          .map((r) => DuyuruResimModel.fromMap(r as Map<String, dynamic>))
          .toList();
    }

    return DuyuruModel(
      id: map['id'] ?? 0,
      baslik: map['baslik'] ?? map['title'] ?? '',
      altBaslik: map['alt_baslik'] ?? map['subtitle'] ?? '',
      icerik: map['icerik'] ?? map['content'] ?? '',
      hedefKitle: map['hedef_kitle'] ?? 'herkes',
      hedefKitleDisplay: map['hedef_kitle_display'],
      onemliMi: map['onemli_mi'] ?? false,
      kapakResmi: map['kapak_resmi'],
      resimSayisi: map['resim_sayisi'] ?? resimler.length,
      resimler: resimler,
      yayinBaslangic: _parseDate(map['yayin_baslangic']),
      yayinBitis: _parseDateNullable(map['yayin_bitis']),
      olusturulmaZamani: _parseDate(map['olusturulma_zamani']),
      guncellenmeZamani: _parseDateNullable(map['guncellenme_zamani']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baslik': baslik,
      'alt_baslik': altBaslik,
      'icerik': icerik,
      'hedef_kitle': hedefKitle,
      'hedef_kitle_display': hedefKitleDisplay,
      'onemli_mi': onemliMi,
      'kapak_resmi': kapakResmi,
      'resim_sayisi': resimSayisi,
      'resimler': resimler.map((r) => r.toMap()).toList(),
      'yayin_baslangic': yayinBaslangic.toIso8601String(),
      'yayin_bitis': yayinBitis?.toIso8601String(),
      'olusturulma_zamani': olusturulmaZamani.toIso8601String(),
      'guncellenme_zamani': guncellenmeZamani?.toIso8601String(),
    };
  }

  // Yardımcı getter'lar
  bool get resimVar => kapakResmi != null || resimler.isNotEmpty;

  String get ilkResim =>
      kapakResmi ?? (resimler.isNotEmpty ? resimler.first.url : '');

  List<String> get tumResimUrlleri {
    if (resimler.isNotEmpty) {
      return resimler.map((r) => r.url).toList();
    }
    if (kapakResmi != null) {
      return [kapakResmi!];
    }
    return [];
  }

  // Boş model
  static DuyuruModel empty() => DuyuruModel(
        id: 0,
        baslik: '',
        yayinBaslangic: simdiKulup(),
        olusturulmaZamani: simdiKulup(),
      );

  @override
  String toString() => 'DuyuruModel(id: $id, baslik: $baslik)';
}

/// Duyuru Resim Modeli
class DuyuruResimModel {
  final int id;
  final String url;
  final int sira;
  final bool kapakMi;

  DuyuruResimModel({
    required this.id,
    required this.url,
    this.sira = 0,
    this.kapakMi = false,
  });

  factory DuyuruResimModel.fromMap(Map<String, dynamic> map) {
    return DuyuruResimModel(
      id: map['id'] ?? 0,
      url: map['url'] ?? '',
      sira: map['sira'] ?? 0,
      kapakMi: map['kapak_mi'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'sira': sira,
      'kapak_mi': kapakMi,
    };
  }

  @override
  String toString() => 'DuyuruResimModel(id: $id, kapak: $kapakMi)';
}
