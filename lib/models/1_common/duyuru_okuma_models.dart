// lib/models/1_common/duyuru_okuma_models.dart
//
// Yönetici/ofis "Duyurular" ekranının modelleri (yoneticiDuyurular,
// yoneticiDuyuruOkumaDurumu). İki kabuk aynı uçları kullanır; sunucu hesap
// (veli) adını ve kullanıcı adını hiç göndermez — hesap, bu işletmedeki profil
// adlarıyla gösterilir.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';

enum DuyuruYayinDurumu { yayinda, planli, gecmis }

DuyuruYayinDurumu _durum(dynamic v) => switch (v) {
      'yayinda' => DuyuruYayinDurumu.yayinda,
      'planli' => DuyuruYayinDurumu.planli,
      _ => DuyuruYayinDurumu.gecmis,
    };

/// Hedef kitlenin kısa adı ("Sadece Üyeler" yerine "Üyeler").
String hedefKitleKisa(String kod) => switch (kod) {
      'uyeler' => 'Üyeler',
      'antrenorler' => 'Antrenörler',
      'yoneticiler' => 'Yöneticiler',
      _ => 'Herkes',
    };

/// Listedeki bir duyuru: durum + gören / hedef hesap sayısı.
class DuyuruYonetimSatiri {
  final int id;
  final String baslik;
  final String altBaslik;
  final String hedefKitle;
  final bool onemliMi;
  final bool popupGoster;
  final bool aktifMi;
  final DuyuruYayinDurumu durum;
  final DateTime yayinBaslangic;
  final DateTime? yayinBitis;

  /// Hedef kitle uygulamada ölçülemiyorsa (antrenör + popupsuz) null.
  final int? gorenSayisi;
  final int? hedefSayisi;

  const DuyuruYonetimSatiri({
    required this.id,
    required this.baslik,
    this.altBaslik = '',
    this.hedefKitle = 'herkes',
    this.onemliMi = false,
    this.popupGoster = false,
    this.aktifMi = true,
    required this.durum,
    required this.yayinBaslangic,
    this.yayinBitis,
    this.gorenSayisi,
    this.hedefSayisi,
  });

  bool get olculuyor => hedefSayisi != null;

  /// 0–1 arası oran; ölçülmüyorsa ya da hedef boşsa null.
  double? get oran {
    final h = hedefSayisi, g = gorenSayisi;
    if (h == null || g == null || h == 0) return null;
    return g / h;
  }

  factory DuyuruYonetimSatiri.fromJson(Map<String, dynamic> j) =>
      DuyuruYonetimSatiri(
        id: j['id'] ?? 0,
        baslik: j['baslik'] ?? '',
        altBaslik: j['alt_baslik'] ?? '',
        hedefKitle: j['hedef_kitle'] ?? 'herkes',
        onemliMi: j['onemli_mi'] ?? false,
        popupGoster: j['popup_goster'] ?? false,
        aktifMi: j['aktif_mi'] ?? true,
        durum: _durum(j['durum']),
        yayinBaslangic: parseApiTarihOrNow(j['yayin_baslangic']),
        yayinBitis: parseApiTarih(j['yayin_bitis']),
        gorenSayisi: j['goren_sayisi'],
        hedefSayisi: j['hedef_sayisi'],
      );
}

/// Hesaba bağlı, bu işletmedeki bir profil (üye ya da antrenör).
class HesapProfili {
  final String ad;

  /// 'uye' | 'antrenor' | null (profili olmayan hesap)
  final String? rol;

  /// Üye profiliyse üye detay sayfasına gitmek için.
  final int? uyeId;

  const HesapProfili({required this.ad, this.rol, this.uyeId});

  factory HesapProfili.fromJson(Map<String, dynamic> j) => HesapProfili(
        ad: j['ad'] ?? '',
        rol: j['rol'],
        uyeId: j['uye_id'],
      );
}

/// Okuma listesindeki bir hesap (görmüş ya da görmemiş).
class DuyuruHesabi {
  final int hesapId;

  /// Ana hesap profili önce; en az bir öğe.
  final List<HesapProfili> profiller;

  const DuyuruHesabi({required this.hesapId, required this.profiller});

  String get adlar => profiller.map((p) => p.ad).join(', ');

  /// Üye detayına gidilebilecek profiller.
  List<HesapProfili> get uyeProfilleri =>
      profiller.where((p) => p.uyeId != null).toList();

  static List<HesapProfili> _profiller(dynamic v) => (v as List? ?? [])
      .map((e) => HesapProfili.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

class GorenHesap extends DuyuruHesabi {
  /// 'carousel' (ana sayfa şeridinden detay açtı) | 'popup'
  final String kaynak;
  final bool detayAcildi;

  /// İlk görülme.
  final DateTime zaman;

  const GorenHesap({
    required super.hesapId,
    required super.profiller,
    required this.kaynak,
    required this.detayAcildi,
    required this.zaman,
  });

  factory GorenHesap.fromJson(Map<String, dynamic> j) => GorenHesap(
        hesapId: j['hesap_id'] ?? 0,
        profiller: DuyuruHesabi._profiller(j['profiller']),
        kaynak: j['kaynak'] ?? 'carousel',
        detayAcildi: j['detay_acildi'] ?? false,
        zaman: parseApiTarihOrNow(j['zaman']),
      );
}

class GormeyenHesap extends DuyuruHesabi {
  /// Son 60 günde yenilenmiş aktif cihaz kaydı var mı.
  final bool uygulamaKullaniyor;

  const GormeyenHesap({
    required super.hesapId,
    required super.profiller,
    required this.uygulamaKullaniyor,
  });

  factory GormeyenHesap.fromJson(Map<String, dynamic> j) => GormeyenHesap(
        hesapId: j['hesap_id'] ?? 0,
        profiller: DuyuruHesabi._profiller(j['profiller']),
        uygulamaKullaniyor: j['uygulama_kullaniyor'] ?? false,
      );
}

class DuyuruOkumaOzeti {
  final bool olculuyor;
  final int? hedefSayisi;

  /// Gören ∩ bugünkü hedef (oranın payı).
  final int? gorenSayisi;

  /// Hedef dışına düşmüşler dahil tüm kayıtlar.
  final int toplamGoren;
  final int anaSayfa;
  final int popup;
  final int detayAcan;

  /// Görmeyenlerden uygulamayı kullanmayanlar.
  final int kullanmayanSayisi;

  const DuyuruOkumaOzeti({
    required this.olculuyor,
    this.hedefSayisi,
    this.gorenSayisi,
    this.toplamGoren = 0,
    this.anaSayfa = 0,
    this.popup = 0,
    this.detayAcan = 0,
    this.kullanmayanSayisi = 0,
  });

  double? get oran {
    final h = hedefSayisi, g = gorenSayisi;
    if (!olculuyor || h == null || g == null || h == 0) return null;
    return g / h;
  }

  factory DuyuruOkumaOzeti.fromJson(Map<String, dynamic> j) =>
      DuyuruOkumaOzeti(
        olculuyor: j['olculuyor'] ?? false,
        hedefSayisi: j['hedef_sayisi'],
        gorenSayisi: j['goren_sayisi'],
        toplamGoren: j['toplam_goren'] ?? 0,
        anaSayfa: j['ana_sayfa'] ?? 0,
        popup: j['popup'] ?? 0,
        detayAcan: j['detay_acan'] ?? 0,
        kullanmayanSayisi: j['kullanmayan_sayisi'] ?? 0,
      );
}

class DuyuruOkumaDurumu {
  final DuyuruModel duyuru;
  final DuyuruYayinDurumu durum;
  final bool aktifMi;
  final DuyuruOkumaOzeti ozet;

  /// En yeni üstte.
  final List<GorenHesap> gordu;

  /// Alfabetik.
  final List<GormeyenHesap> gormedi;

  /// Web panelindeki düzenleme sayfasının yolu ("/duyuru/12/duzenle/?isletme=1").
  final String webDuzenleYolu;

  const DuyuruOkumaDurumu({
    required this.duyuru,
    required this.durum,
    required this.aktifMi,
    required this.ozet,
    required this.gordu,
    required this.gormedi,
    required this.webDuzenleYolu,
  });

  factory DuyuruOkumaDurumu.fromJson(Map<String, dynamic> j) {
    final d = (j['duyuru'] as Map? ?? {}).cast<String, dynamic>();
    return DuyuruOkumaDurumu(
      duyuru: DuyuruModel.fromMap(d),
      durum: _durum(d['durum']),
      aktifMi: d['aktif_mi'] ?? true,
      ozet: DuyuruOkumaOzeti.fromJson(
          (j['ozet'] as Map? ?? {}).cast<String, dynamic>()),
      gordu: (j['gordu'] as List? ?? [])
          .map((e) => GorenHesap.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      gormedi: (j['gormedi'] as List? ?? [])
          .map((e) =>
              GormeyenHesap.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      webDuzenleYolu: j['web_duzenle_yolu'] ?? '',
    );
  }
}
