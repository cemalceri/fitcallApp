// lib/models/9_yonetici/uye_filtreleri.dart
//
// Yönetici Üyeler sekmesinin birlikte çalışan filtreleri ve sıralaması.
// Hepsi sunucuda uygulanır (`yoneticiUyeler` → `filtreler`, `siralama`,
// `yon`); filtreler VE ile birleşir. Sözleşme backend'de
// api/yonetici/metots.py: `yonetici_uye_filtrele`, `UYE_SIRALAMA_VARSAYILAN_YON`.
//
// Seçimler cihazda saklanmaz: sekme değişince korunur (IndexedStack),
// uygulama yeniden açılınca sıfırlanır (kullanıcı kararı 2026-10-18).

import 'package:fitcall/common/tarih_util.dart';
import 'package:intl/intl.dart';

enum UyeDurumFiltresi { aktif, pasif }

enum BorcDurumFiltresi { borclu, borcsuz, fazlaOdemis }

extension BorcDurumFiltresiApi on BorcDurumFiltresi {
  String get api => switch (this) {
        BorcDurumFiltresi.borclu => 'borclu',
        BorcDurumFiltresi.borcsuz => 'borcsuz',
        BorcDurumFiltresi.fazlaOdemis => 'fazla_odemis',
      };

  String get etiket => switch (this) {
        BorcDurumFiltresi.borclu => 'Borçlu',
        BorcDurumFiltresi.borcsuz => 'Borçsuz',
        BorcDurumFiltresi.fazlaOdemis => 'Fazla ödemiş',
      };
}

/// Etkin filtrenin listenin üstündeki çipi: etiket + yalnız onu kaldıran hal.
class FiltreCipi {
  final String etiket;
  final UyeFiltreleri kaldirilmis;

  const FiltreCipi(this.etiket, this.kaldirilmis);
}

const Object _degismez = Object();

/// Değişmez filtre durumu. Boş alan uygulanmaz.
class UyeFiltreleri {
  final UyeDurumFiltresi? durum;
  final BorcDurumFiltresi? borc;

  /// Borç tutarı (TL, = −bakiye), iki uç dahil.
  final int? borcMin;
  final int? borcMax;

  /// null: tümü. Kontrol satırı olmayan üye kesinleşmemiş sayılır.
  final bool? kesinlesti;

  /// Son kontrol tarihi aralığı (uçlar dahil) ya da hiç kontrol edilmemiş.
  final DateTime? kontrolSonra;
  final DateTime? kontrolOnce;
  final bool kontrolYok;

  /// Son ödeme (yalnız ÖDEME türü) aralığı ya da hiç ödeme yapmamış.
  final DateTime? odemeSonra;
  final DateTime? odemeOnce;
  final bool odemeYok;

  /// Son dersi bu günden önce: "o günden beri derse gelmeyen". Hiç dersi
  /// olmayan da dahil (sunucu kuralı).
  final DateTime? dersOnce;

  /// Bu günden sonra kaydolan.
  final DateTime? kayitSonra;

  const UyeFiltreleri({
    this.durum,
    this.borc,
    this.borcMin,
    this.borcMax,
    this.kesinlesti,
    this.kontrolSonra,
    this.kontrolOnce,
    this.kontrolYok = false,
    this.odemeSonra,
    this.odemeOnce,
    this.odemeYok = false,
    this.dersOnce,
    this.kayitSonra,
  });

  static const bos = UyeFiltreleri();

  /// Alanı null'a çekmek için açıkça `null` verin; verilmeyen alan korunur.
  UyeFiltreleri copyWith({
    Object? durum = _degismez,
    Object? borc = _degismez,
    Object? borcMin = _degismez,
    Object? borcMax = _degismez,
    Object? kesinlesti = _degismez,
    Object? kontrolSonra = _degismez,
    Object? kontrolOnce = _degismez,
    bool? kontrolYok,
    Object? odemeSonra = _degismez,
    Object? odemeOnce = _degismez,
    bool? odemeYok,
    Object? dersOnce = _degismez,
    Object? kayitSonra = _degismez,
  }) {
    T? sec<T>(Object? yeni, T? eski) =>
        identical(yeni, _degismez) ? eski : yeni as T?;
    return UyeFiltreleri(
      durum: sec(durum, this.durum),
      borc: sec(borc, this.borc),
      borcMin: sec(borcMin, this.borcMin),
      borcMax: sec(borcMax, this.borcMax),
      kesinlesti: sec(kesinlesti, this.kesinlesti),
      kontrolSonra: sec(kontrolSonra, this.kontrolSonra),
      kontrolOnce: sec(kontrolOnce, this.kontrolOnce),
      kontrolYok: kontrolYok ?? this.kontrolYok,
      odemeSonra: sec(odemeSonra, this.odemeSonra),
      odemeOnce: sec(odemeOnce, this.odemeOnce),
      odemeYok: odemeYok ?? this.odemeYok,
      dersOnce: sec(dersOnce, this.dersOnce),
      kayitSonra: sec(kayitSonra, this.kayitSonra),
    );
  }

  /// İstek gövdesindeki `filtreler` nesnesi; yalnız dolu alanlar gider.
  Map<String, dynamic> toJson() => {
        if (durum != null) 'durum': durum!.name,
        if (borc != null) 'borc': borc!.api,
        if (borcMin != null) 'borc_min': borcMin,
        if (borcMax != null) 'borc_max': borcMax,
        if (kesinlesti != null) 'kesinlesti': kesinlesti,
        if (kontrolSonra != null) 'kontrol_sonra': formatApiGun(kontrolSonra!),
        if (kontrolOnce != null) 'kontrol_once': formatApiGun(kontrolOnce!),
        if (kontrolYok) 'kontrol_yok': true,
        if (odemeSonra != null) 'odeme_sonra': formatApiGun(odemeSonra!),
        if (odemeOnce != null) 'odeme_once': formatApiGun(odemeOnce!),
        if (odemeYok) 'odeme_yok': true,
        if (dersOnce != null) 'ders_once': formatApiGun(dersOnce!),
        if (kayitSonra != null) 'kayit_sonra': formatApiGun(kayitSonra!),
      };

  static final _gun = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final _tl = NumberFormat.decimalPattern('tr_TR');

  static String _aralik(String ad, DateTime? sonra, DateTime? once) {
    if (sonra != null && once != null) {
      return '$ad: ${_gun.format(sonra)}–${_gun.format(once)}';
    }
    if (sonra != null) return '$ad: ${_gun.format(sonra)} ve sonrası';
    return '$ad: ${_gun.format(once!)} ve öncesi';
  }

  /// Listenin üstündeki çipler; her biri yalnız kendi filtresini kaldırır.
  List<FiltreCipi> get cipler => [
        if (durum != null)
          FiltreCipi(
            durum == UyeDurumFiltresi.aktif ? 'Aktif' : 'Pasif',
            copyWith(durum: null),
          ),
        if (borc != null) FiltreCipi(borc!.etiket, copyWith(borc: null)),
        if (borcMin != null || borcMax != null)
          FiltreCipi(
            borcMin != null && borcMax != null
                ? 'Borç ${_tl.format(borcMin)}–${_tl.format(borcMax)} ₺'
                : borcMin != null
                    ? 'Borç ≥ ${_tl.format(borcMin)} ₺'
                    : 'Borç ≤ ${_tl.format(borcMax)} ₺',
            copyWith(borcMin: null, borcMax: null),
          ),
        if (kesinlesti != null)
          FiltreCipi(
            kesinlesti! ? 'Kesinleşti' : 'Kesinleşmedi',
            copyWith(kesinlesti: null),
          ),
        if (kontrolYok)
          FiltreCipi('Hiç kontrol edilmedi', copyWith(kontrolYok: false)),
        if (kontrolSonra != null || kontrolOnce != null)
          FiltreCipi(
            _aralik('Kontrol', kontrolSonra, kontrolOnce),
            copyWith(kontrolSonra: null, kontrolOnce: null),
          ),
        if (odemeYok) FiltreCipi('Hiç ödeme yok', copyWith(odemeYok: false)),
        if (odemeSonra != null || odemeOnce != null)
          FiltreCipi(
            _aralik('Ödeme', odemeSonra, odemeOnce),
            copyWith(odemeSonra: null, odemeOnce: null),
          ),
        if (dersOnce != null)
          FiltreCipi(
            '${_gun.format(dersOnce!)} beri derse gelmeyen',
            copyWith(dersOnce: null),
          ),
        if (kayitSonra != null)
          FiltreCipi(
            'Kayıt: ${_gun.format(kayitSonra!)} ve sonrası',
            copyWith(kayitSonra: null),
          ),
      ];

  /// "Filtrele (n)" düğmesindeki sayı.
  int get aktifSayisi => cipler.length;

  bool get bosMu => aktifSayisi == 0;

  @override
  String toString() => 'UyeFiltreleri(${toJson()})';

  @override
  bool operator ==(Object other) =>
      other is UyeFiltreleri &&
      other.durum == durum &&
      other.borc == borc &&
      other.borcMin == borcMin &&
      other.borcMax == borcMax &&
      other.kesinlesti == kesinlesti &&
      other.kontrolSonra == kontrolSonra &&
      other.kontrolOnce == kontrolOnce &&
      other.kontrolYok == kontrolYok &&
      other.odemeSonra == odemeSonra &&
      other.odemeOnce == odemeOnce &&
      other.odemeYok == odemeYok &&
      other.dersOnce == dersOnce &&
      other.kayitSonra == kayitSonra;

  @override
  int get hashCode => Object.hash(
        durum,
        borc,
        borcMin,
        borcMax,
        kesinlesti,
        kontrolSonra,
        kontrolOnce,
        kontrolYok,
        odemeSonra,
        odemeOnce,
        odemeYok,
        dersOnce,
        kayitSonra,
      );
}

// ==================== SIRALAMA ====================

enum UyeSiralamaAlani { ad, uyeNo, borc, sonKontrol, sonOdeme, sonDers }

enum SiralamaYonu { artan, azalan }

class UyeSiralama {
  final UyeSiralamaAlani alan;
  final SiralamaYonu yon;

  const UyeSiralama(this.alan, this.yon);

  static const varsayilan =
      UyeSiralama(UyeSiralamaAlani.ad, SiralamaYonu.artan);

  /// Sırala sayfasındaki seçenekler, her alan önce varsayılan yönüyle.
  static const secenekler = [
    UyeSiralama(UyeSiralamaAlani.ad, SiralamaYonu.artan),
    UyeSiralama(UyeSiralamaAlani.ad, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.uyeNo, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.uyeNo, SiralamaYonu.artan),
    UyeSiralama(UyeSiralamaAlani.borc, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.borc, SiralamaYonu.artan),
    UyeSiralama(UyeSiralamaAlani.sonKontrol, SiralamaYonu.artan),
    UyeSiralama(UyeSiralamaAlani.sonKontrol, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.sonOdeme, SiralamaYonu.artan),
    UyeSiralama(UyeSiralamaAlani.sonOdeme, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.sonDers, SiralamaYonu.azalan),
    UyeSiralama(UyeSiralamaAlani.sonDers, SiralamaYonu.artan),
  ];

  String get apiAlani => switch (alan) {
        UyeSiralamaAlani.ad => 'ad',
        UyeSiralamaAlani.uyeNo => 'uye_no',
        UyeSiralamaAlani.borc => 'borc',
        UyeSiralamaAlani.sonKontrol => 'son_kontrol',
        UyeSiralamaAlani.sonOdeme => 'son_odeme',
        UyeSiralamaAlani.sonDers => 'son_ders',
      };

  String get apiYonu => yon.name;

  bool get _artan => yon == SiralamaYonu.artan;

  /// Sırala sayfasındaki satır.
  String get etiket => switch (alan) {
        UyeSiralamaAlani.ad => _artan ? 'Ad (A→Z)' : 'Ad (Z→A)',
        UyeSiralamaAlani.uyeNo =>
          _artan ? 'Üye no (eski kayıt önce)' : 'Üye no (yeni kayıt önce)',
        UyeSiralamaAlani.borc =>
          _artan ? 'Borç (en az borçlu önce)' : 'Borç (en borçlu önce)',
        UyeSiralamaAlani.sonKontrol =>
          _artan ? 'Son kontrol (en eski önce)' : 'Son kontrol (en yeni önce)',
        UyeSiralamaAlani.sonOdeme =>
          _artan ? 'Son ödeme (en eski önce)' : 'Son ödeme (en yeni önce)',
        UyeSiralamaAlani.sonDers =>
          _artan ? 'Son ders (en eski önce)' : 'Son ders (en yeni önce)',
      };

  /// "Sırala: …" düğmesindeki kısa hal.
  String get kisaEtiket => switch (alan) {
        UyeSiralamaAlani.ad => _artan ? 'A→Z' : 'Z→A',
        UyeSiralamaAlani.uyeNo => _artan ? 'Eski kayıt' : 'Yeni kayıt',
        UyeSiralamaAlani.borc => _artan ? 'En az borçlu' : 'En borçlu',
        UyeSiralamaAlani.sonKontrol => _artan ? 'Eski kontrol' : 'Yeni kontrol',
        UyeSiralamaAlani.sonOdeme => _artan ? 'Eski ödeme' : 'Yeni ödeme',
        UyeSiralamaAlani.sonDers => _artan ? 'Eski ders' : 'Yeni ders',
      };

  @override
  bool operator ==(Object other) =>
      other is UyeSiralama && other.alan == alan && other.yon == yon;

  @override
  int get hashCode => Object.hash(alan, yon);
}

// ==================== ÖN AYARLAR ====================

/// Sayılı kartlar (Toplam · Aktif · Pasif · Borçlu · Yeni): dokununca filtre
/// ve sıralama bu ön ayara geçer. Kart yalnız filtreler tam ön ayara
/// eşitken vurgulu (sıralama değişse de vurgu kalır).
enum UyeOnAyari { tumu, aktif, pasif, borclu, yeni }

extension UyeOnAyariDegerleri on UyeOnAyari {
  /// [bugun] "Yeni" için: kulüp gününe göre bu ayın ilk günü.
  UyeFiltreleri filtreler(DateTime bugun) => switch (this) {
        UyeOnAyari.tumu => UyeFiltreleri.bos,
        UyeOnAyari.aktif => const UyeFiltreleri(durum: UyeDurumFiltresi.aktif),
        UyeOnAyari.pasif => const UyeFiltreleri(durum: UyeDurumFiltresi.pasif),
        UyeOnAyari.borclu =>
          const UyeFiltreleri(borc: BorcDurumFiltresi.borclu),
        UyeOnAyari.yeni =>
          UyeFiltreleri(kayitSonra: DateTime(bugun.year, bugun.month)),
      };

  UyeSiralama get siralama => switch (this) {
        UyeOnAyari.borclu =>
          const UyeSiralama(UyeSiralamaAlani.borc, SiralamaYonu.azalan),
        UyeOnAyari.yeni =>
          const UyeSiralama(UyeSiralamaAlani.uyeNo, SiralamaYonu.azalan),
        _ => UyeSiralama.varsayilan,
      };
}

/// Filtreleri tam bir ön ayara eşitse o kart (vurgulanır); değilse null.
UyeOnAyari? eslesenOnAyar(UyeFiltreleri filtreler, DateTime bugun) {
  for (final o in UyeOnAyari.values) {
    if (o.filtreler(bugun) == filtreler) return o;
  }
  return null;
}

/// Süzülen kümenin özeti: "37 üye · 48.200 ₺ borç". İlk sayfayla gelir.
class UyeFiltreOzeti {
  final int uyeSayisi;
  final double toplamBorc;

  const UyeFiltreOzeti({required this.uyeSayisi, required this.toplamBorc});

  factory UyeFiltreOzeti.fromJson(Map<String, dynamic> json) => UyeFiltreOzeti(
        uyeSayisi: (json['uye_sayisi'] as num?)?.toInt() ?? 0,
        toplamBorc:
            double.tryParse(json['toplam_borc']?.toString() ?? '') ?? 0,
      );
}
