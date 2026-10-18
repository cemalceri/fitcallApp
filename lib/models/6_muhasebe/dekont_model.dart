// lib/models/6_muhasebe/dekont_model.dart
//
// Üyenin yüklediği havale/EFT dekontu ("Dekontlarım"). Personelin iç notu,
// hesap ve ödeme şekli sunucudan BİLEREK gelmez; üye yalnız durumu, ret
// gerekçesini ve işlenen tutarı görür.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';

enum DekontDurumu { bekliyor, islendi, reddedildi, geriCekildi, bilinmiyor }

DekontDurumu dekontDurumuCoz(String? deger) => switch (deger) {
      'BEKLIYOR' => DekontDurumu.bekliyor,
      'ISLENDI' => DekontDurumu.islendi,
      'REDDEDILDI' => DekontDurumu.reddedildi,
      'GERI_CEKILDI' => DekontDurumu.geriCekildi,
      _ => DekontDurumu.bilinmiyor,
    };

class DekontModel {
  final int id;
  final DekontDurumu durum;
  final String durumEtiketi;
  final DateTime? yuklenme;
  final double? beyanTutar;
  final String aciklama;
  final String redNedeni;
  final String dosyaAdi;
  final String dosyaTuru;
  final bool pdfMi;
  final double? islenenTutar;

  /// Ödemenin yazıldığı profiller (veli tek havaleyle iki çocuğu ödediyse iki ad).
  final List<String> islenenUyeler;

  /// İşlenmişken ödeme kaydı silindi ya da onay geri alındı: yeniden kontrolde.
  final bool yenidenKontrol;

  const DekontModel({
    required this.id,
    required this.durum,
    required this.durumEtiketi,
    this.yuklenme,
    this.beyanTutar,
    this.aciklama = '',
    this.redNedeni = '',
    this.dosyaAdi = '',
    this.dosyaTuru = '',
    this.pdfMi = false,
    this.islenenTutar,
    this.islenenUyeler = const [],
    this.yenidenKontrol = false,
  });

  factory DekontModel.fromJson(Map<String, dynamic> json) {
    final uyeler = (json['islenen_uyeler'] as List? ?? const [])
        .map((e) => e is Map ? (e['ad'] ?? '').toString() : e.toString())
        .where((ad) => ad.isNotEmpty)
        .toList();
    return DekontModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      durum: dekontDurumuCoz(json['durum']?.toString()),
      durumEtiketi: (json['durum_etiketi'] ?? '').toString(),
      yuklenme: parseApiTarih(json['olusturulma_zamani']),
      beyanTutar: _sayi(json['beyan_tutar']),
      aciklama: (json['aciklama'] ?? '').toString(),
      redNedeni: (json['red_nedeni'] ?? '').toString(),
      dosyaAdi: (json['dosya_adi'] ?? '').toString(),
      dosyaTuru: (json['dosya_turu'] ?? '').toString(),
      pdfMi: json['pdf_mi'] == true,
      islenenTutar: _sayi(json['islenen_tutar']),
      islenenUyeler: uyeler,
      yenidenKontrol: json['yeniden_kontrol'] == true,
    );
  }

  bool get bekliyor => durum == DekontDurumu.bekliyor;

  /// Listede durum kelimesi (renk tek başına durum anlatmaz).
  String get durumMetni => switch (durum) {
        DekontDurumu.bekliyor =>
          yenidenKontrol ? 'Yeniden kontrol ediliyor' : 'Kontrol bekliyor',
        DekontDurumu.islendi => 'İşlendi',
        DekontDurumu.reddedildi => 'Reddedildi',
        DekontDurumu.geriCekildi => 'Geri çekildi',
        DekontDurumu.bilinmiyor =>
          durumEtiketi.isNotEmpty ? durumEtiketi : 'Bilinmiyor',
      };

  ListeTonu get ton => switch (durum) {
        DekontDurumu.bekliyor => ListeTonu.uyari,
        DekontDurumu.islendi => ListeTonu.basari,
        DekontDurumu.reddedildi => ListeTonu.hata,
        _ => ListeTonu.notr,
      };

  /// Gösterilecek tutar: işlendiyse işlenen, değilse üyenin yazdığı.
  double? get gosterilenTutar =>
      durum == DekontDurumu.islendi ? (islenenTutar ?? beyanTutar) : beyanTutar;
}

class DekontlarimSonucu {
  final List<DekontModel> dekontlar;
  final int bekleyenSayisi;

  const DekontlarimSonucu({required this.dekontlar, required this.bekleyenSayisi});

  factory DekontlarimSonucu.fromJson(dynamic json) {
    final harita = (json as Map? ?? const {}).cast<String, dynamic>();
    final liste = (harita['dekontlar'] as List? ?? const [])
        .map((e) => DekontModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return DekontlarimSonucu(
      dekontlar: liste,
      bekleyenSayisi: (harita['bekleyen_sayisi'] as num?)?.toInt() ??
          liste.where((d) => d.bekliyor).length,
    );
  }
}

double? _sayi(dynamic deger) {
  if (deger == null) return null;
  if (deger is num) return deger.toDouble();
  return double.tryParse(deger.toString());
}
