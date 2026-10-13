// lib/common/tema.dart
//
// Uygulamanın tek tasarım kaynağı: renk, tipografi, boşluk ve yarıçap
// token'ları ile açık/koyu `ThemeData`.
//
// Neden var: ekranlar uzun süre gömülü hex'lerle çizildi (91 farklı ton) ve
// `MaterialApp` hâlâ Flutter şablonunun mor tohumunu taşıyordu — tema ile
// arayüz birbirinden kopuktu, koyu tema da imkânsızdı. Artık renk seçimi
// buradan yapılır: yeni ekranlar `Theme.of(context).colorScheme` ve
// `context.renkler` üzerinden okur, dosyaya gömülü hex yazmaz.
//
// Marka renkleri kulübün formasından geliyor: turuncu gövde + kobalt mavi yazı.
// Turuncunun canlı hâli (`Marka.turuncu`) büyük dolgu yüzeylerde kullanılır;
// metin ve küçük öğelerde açık zeminde kontrast eşiğini geçen koyu hâli
// (`ColorScheme.primary`) tercih edilir.
//
// Renk temaları (2026-10): kullanıcı Binay Akademi'nin yanında beş takım
// renginden birini seçebilir (`TakimTemasi`). Binay paleti eski değerleriyle
// duruyor; yalnız birincil renk, zemin boyandığında okunur kalsın diye bir tık
// koyulaştı (2026-10-12). Tasarım dili üç token'a dayanır (`TemaGecisleri`): ekranda en
// fazla bir kimlik yüzeyi, takım renginin açık tonunda sayfa zemini, dolu
// takım renginde başlık çubuğu ve alt menü, ikinci takım renginin göründüğü
// ince şerit. Butonlar, listeler, takvim ve durum renkleri
// her temada düz kalır. Her tema × mod çifti test/tema_kontrast_test.dart'ta
// kontrast eşiğine karşı ölçülür.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/* ============================ Marka renkleri ============================ */

class Marka {
  Marka._();

  /// Forma turuncusu — büyük dolgu yüzeyler, QR butonu, vurgu rozetleri.
  /// Beyaz metinle 3.1:1; yalnız 14px+ kalın metinle kullanılmalı.
  static const Color turuncu = Color(0xFFF4661B);

  /// Açık zeminde metin/ikon için güvenli turuncu (beyazla 4.7:1).
  static const Color turuncuKoyu = Color(0xFFC2500B);

  /// Koyu zeminde birincil turuncu.
  static const Color turuncuAcik = Color(0xFFFF9351);

  /// Forma yazısının kobalt mavisi — ikincil renk.
  static const Color mavi = Color(0xFF2438C8);

  /// Koyu zeminde ikincil mavi.
  static const Color maviAcik = Color(0xFFA9B4FF);

  /// Siyah-beyaz logonun zemini: her temada ve modda beyaz.
  static const Color logoZemini = Color(0xFFFFFFFF);
}

/// İki renk arasındaki WCAG kontrast oranı (1–21). Metin için eşik 4.5,
/// ikon ve grafik öğe için 3.
double kontrastOrani(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

/// Verilen zemin üzerinde okunan metin/ikon rengi (koyu ya da beyaz).
///
/// İki adayın kontrastı karşılaştırılır, yüksek olan seçilir. Eskiden
/// parlaklık 0.45'te kesiliyordu; koyu temanın açık turuncusu (#FF9351) gibi
/// orta tonlarda beyaz seçip 2.2:1'e düşüyordu.
Color uzerineYazi(Color zemin) {
  const koyu = Color(0xFF1B1714);
  return kontrastOrani(koyu, zemin) >= kontrastOrani(Colors.white, zemin)
      ? koyu
      : Colors.white;
}

/* ======================== Boşluk / yarıçap ölçeği ======================== */

/// 4'ün katlarına oturan boşluk ölçeği. Yeni ekranlarda `EdgeInsets` değerleri
/// buradan seçilir; serbest sayı yazmak yerleşimi tutarsızlaştırır.
class Bosluk {
  Bosluk._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Köşe yarıçapı ölçeği.
class Yaricap {
  Yaricap._();
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double sayfa = 28; // alt sayfa (bottom sheet) üst köşeleri
}

/* ===================== Semantik renkler (ThemeExtension) ===================== */

/// `ColorScheme`'in karşılamadığı anlamsal renkler: durum bildirimi (başarı /
/// uyarı / bilgi), nötr gri ve takvim ders durumları. Açık ve koyu temada ayrı
/// değer alır, bu yüzden `ThemeExtension` olarak taşınır.
@immutable
class FitcallRenkleri extends ThemeExtension<FitcallRenkleri> {
  final Color basari;
  final Color basariZemin;
  final Color uyari;
  final Color uyariZemin;
  final Color bilgi;
  final Color bilgiZemin;
  final Color hata;
  final Color hataZemin;
  final Color notr;
  final Color notrZemin;

  /// Marka turuncusunun canlı hâli — dolgu yüzeyler için (metin değil).
  final Color vurgu;
  final Color vurguZemin;

  // Takvim ders durumları
  final Color dersGelecek;
  final Color dersTamamlandi;
  final Color dersBekliyor;
  final Color dersIptal;
  final Color dersYapilmadi;

  // Takvim ızgarası
  final Color saatCizgisi;
  final Color yarimSaatCizgisi;
  final Color simdiCizgisi;
  final Color takvimZemin;

  const FitcallRenkleri({
    required this.basari,
    required this.basariZemin,
    required this.uyari,
    required this.uyariZemin,
    required this.bilgi,
    required this.bilgiZemin,
    required this.hata,
    required this.hataZemin,
    required this.notr,
    required this.notrZemin,
    required this.vurgu,
    required this.vurguZemin,
    required this.dersGelecek,
    required this.dersTamamlandi,
    required this.dersBekliyor,
    required this.dersIptal,
    required this.dersYapilmadi,
    required this.saatCizgisi,
    required this.yarimSaatCizgisi,
    required this.simdiCizgisi,
    required this.takvimZemin,
  });

  static const FitcallRenkleri acik = FitcallRenkleri(
    basari: Color(0xFF0E7C5A),
    basariZemin: Color(0xFFE6F6EF),
    uyari: Color(0xFFB45309),
    uyariZemin: Color(0xFFFEF3C7),
    bilgi: Marka.mavi,
    bilgiZemin: Color(0xFFE4E7FF),
    // DC2626'dan bir ton koyu: sayfa zemini takım tonuna boyanınca borç
    // tutarları 4.2:1'e düşüyordu (eşik 4.5). Şemanın açık error rengi de aynı.
    hata: Color(0xFFC62828),
    hataZemin: Color(0xFFFEE2E2),
    notr: Color(0xFF5C6773),
    notrZemin: Color(0xFFF1F3F5),
    vurgu: Marka.turuncu,
    vurguZemin: Color(0xFFFFEDE0),
    dersGelecek: Marka.mavi,
    dersTamamlandi: Color(0xFF0E7C5A),
    dersBekliyor: Color(0xFFB45309),
    dersIptal: Color(0xFFDC2626),
    dersYapilmadi: Color(0xFF5C6773),
    saatCizgisi: Color(0xFFE3DED9),
    yarimSaatCizgisi: Color(0xFFF2EEEA),
    simdiCizgisi: Marka.turuncu,
    takvimZemin: Color(0xFFFAF9F8),
  );

  static const FitcallRenkleri koyu = FitcallRenkleri(
    basari: Color(0xFF43D6A0),
    basariZemin: Color(0xFF10332A),
    uyari: Color(0xFFFBBF24),
    uyariZemin: Color(0xFF3A2A08),
    bilgi: Marka.maviAcik,
    bilgiZemin: Color(0xFF1B2159),
    hata: Color(0xFFFF7B72),
    hataZemin: Color(0xFF3E1614),
    notr: Color(0xFFA3ABB5),
    notrZemin: Color(0xFF262A2E),
    vurgu: Marka.turuncuAcik,
    vurguZemin: Color(0xFF3A2213),
    dersGelecek: Marka.maviAcik,
    dersTamamlandi: Color(0xFF43D6A0),
    dersBekliyor: Color(0xFFFBBF24),
    dersIptal: Color(0xFFFF7B72),
    dersYapilmadi: Color(0xFFA3ABB5),
    saatCizgisi: Color(0xFF3A322D),
    yarimSaatCizgisi: Color(0xFF272220),
    simdiCizgisi: Marka.turuncuAcik,
    takvimZemin: Color(0xFF1A1613),
  );

  @override
  FitcallRenkleri copyWith({
    Color? basari,
    Color? basariZemin,
    Color? uyari,
    Color? uyariZemin,
    Color? bilgi,
    Color? bilgiZemin,
    Color? hata,
    Color? hataZemin,
    Color? notr,
    Color? notrZemin,
    Color? vurgu,
    Color? vurguZemin,
    Color? dersGelecek,
    Color? dersTamamlandi,
    Color? dersBekliyor,
    Color? dersIptal,
    Color? dersYapilmadi,
    Color? saatCizgisi,
    Color? yarimSaatCizgisi,
    Color? simdiCizgisi,
    Color? takvimZemin,
  }) {
    return FitcallRenkleri(
      basari: basari ?? this.basari,
      basariZemin: basariZemin ?? this.basariZemin,
      uyari: uyari ?? this.uyari,
      uyariZemin: uyariZemin ?? this.uyariZemin,
      bilgi: bilgi ?? this.bilgi,
      bilgiZemin: bilgiZemin ?? this.bilgiZemin,
      hata: hata ?? this.hata,
      hataZemin: hataZemin ?? this.hataZemin,
      notr: notr ?? this.notr,
      notrZemin: notrZemin ?? this.notrZemin,
      vurgu: vurgu ?? this.vurgu,
      vurguZemin: vurguZemin ?? this.vurguZemin,
      dersGelecek: dersGelecek ?? this.dersGelecek,
      dersTamamlandi: dersTamamlandi ?? this.dersTamamlandi,
      dersBekliyor: dersBekliyor ?? this.dersBekliyor,
      dersIptal: dersIptal ?? this.dersIptal,
      dersYapilmadi: dersYapilmadi ?? this.dersYapilmadi,
      saatCizgisi: saatCizgisi ?? this.saatCizgisi,
      yarimSaatCizgisi: yarimSaatCizgisi ?? this.yarimSaatCizgisi,
      simdiCizgisi: simdiCizgisi ?? this.simdiCizgisi,
      takvimZemin: takvimZemin ?? this.takvimZemin,
    );
  }

  @override
  FitcallRenkleri lerp(ThemeExtension<FitcallRenkleri>? other, double t) {
    if (other is! FitcallRenkleri) return this;
    Color k(Color a, Color b) => Color.lerp(a, b, t)!;
    return FitcallRenkleri(
      basari: k(basari, other.basari),
      basariZemin: k(basariZemin, other.basariZemin),
      uyari: k(uyari, other.uyari),
      uyariZemin: k(uyariZemin, other.uyariZemin),
      bilgi: k(bilgi, other.bilgi),
      bilgiZemin: k(bilgiZemin, other.bilgiZemin),
      hata: k(hata, other.hata),
      hataZemin: k(hataZemin, other.hataZemin),
      notr: k(notr, other.notr),
      notrZemin: k(notrZemin, other.notrZemin),
      vurgu: k(vurgu, other.vurgu),
      vurguZemin: k(vurguZemin, other.vurguZemin),
      dersGelecek: k(dersGelecek, other.dersGelecek),
      dersTamamlandi: k(dersTamamlandi, other.dersTamamlandi),
      dersBekliyor: k(dersBekliyor, other.dersBekliyor),
      dersIptal: k(dersIptal, other.dersIptal),
      dersYapilmadi: k(dersYapilmadi, other.dersYapilmadi),
      saatCizgisi: k(saatCizgisi, other.saatCizgisi),
      yarimSaatCizgisi: k(yarimSaatCizgisi, other.yarimSaatCizgisi),
      simdiCizgisi: k(simdiCizgisi, other.simdiCizgisi),
      takvimZemin: k(takvimZemin, other.takvimZemin),
    );
  }
}

/// Bir öğenin anlam tonu — avatar/ikon zeminini ve değer rengini belirler.
///
/// BuildContext görmeyen yerler (model getter'ları) renk yerine bunu döndürür;
/// ekran `ton.on(context)` ile temaya çevirir. Böylece model gömülü hex
/// taşımaz ve renk temayla birlikte değişir.
enum ListeTonu { notr, vurgu, basari, uyari, hata, bilgi }

extension ListeTonuRenkleri on ListeTonu {
  /// Ön plan (metin/ikon) rengi.
  Color on(BuildContext context) {
    final r = context.renkler;
    return switch (this) {
      ListeTonu.notr => context.cs.onSurfaceVariant,
      ListeTonu.vurgu => context.cs.primary,
      ListeTonu.basari => r.basari,
      ListeTonu.uyari => r.uyari,
      ListeTonu.hata => r.hata,
      ListeTonu.bilgi => r.bilgi,
    };
  }

  /// Zemin rengi.
  Color zemin(BuildContext context) {
    final r = context.renkler;
    return switch (this) {
      ListeTonu.notr => r.notrZemin,
      ListeTonu.vurgu => r.vurguZemin,
      ListeTonu.basari => r.basariZemin,
      ListeTonu.uyari => r.uyariZemin,
      ListeTonu.hata => r.hataZemin,
      ListeTonu.bilgi => r.bilgiZemin,
    };
  }
}

/// Kısayollar: `context.renkler.basari`, `context.cs.primary`, `context.metin`.
extension TemaKisayollari on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get metin => Theme.of(this).textTheme;
  FitcallRenkleri get renkler =>
      Theme.of(this).extension<FitcallRenkleri>() ?? FitcallRenkleri.acik;
  TemaGecisleri get gecis =>
      Theme.of(this).extension<TemaGecisleri>() ?? TemaGecisleri.binayAcik;
  bool get koyuTema => Theme.of(this).brightness == Brightness.dark;
}

/* ===================== Geçiş token'ları (ThemeExtension) ===================== */

/// Renk temasının gradyanlı öğeleri. Ekranlar gradyanı kendisi yazmaz, buradan
/// okur; böylece takım değişince her ekran birlikte değişir.
///
/// Kurallar (üç tasarımcının ortak kararı, 2026-10-12'de takım rengi
/// sayfalara yayıldı):
/// * [kimlik] ekranın içeriğinde en fazla bir yüzeyde kullanılır (sonraki
///   ders, bakiye, bugünün özeti, detay başlığı). Üstündeki yazı her zaman
///   [onKimlik] ve tam opaktır; ikincil bilgi şeffaflıkla değil
///   boyut/kalınlıkla ayrılır.
/// * [sayfaRengi] her sayfanın baştan sona zemini: takım renginin çok açık
///   (koyu modda derin) tonu (bkz. [SayfaZemini]). Kartlar, sayfalar ve
///   diyaloglar `surface`'ta kalır, zeminden ayrışır.
/// * [baslik] her sayfanın başlık çubuğu (AppBar ve elle çizilen başlık
///   bantları, bkz. `BaslikBandi`), [altBar] kabukların alt menüsü — ikisi de
///   dolu takım rengi; üstlerindeki yazı ve ikon [onBaslik] / [onAltBar], tam
///   opak. Önceden renk yalnız sayfanın üst 280 px'inde sönen bir yıkamaydı;
///   temalar birbirine benziyordu.
/// * [serit] ikinci takım renginin göründüğü yer: kimlik yüzeyinin alt
///   kenarı, QR butonunun halkası, ödül çubuğu. Yazı taşımaz.
/// * [qr] uygulamadaki tek gradyanlı kontrol (alt bardaki QR butonu).
@immutable
class TemaGecisleri extends ThemeExtension<TemaGecisleri> {
  final LinearGradient kimlik;
  final Color onKimlik;
  final Color sayfaRengi;
  final Color baslik;
  final Color onBaslik;
  final Color altBar;
  final Color onAltBar;
  final LinearGradient serit;
  final LinearGradient qr;
  final Color onQr;

  const TemaGecisleri({
    required this.kimlik,
    required this.onKimlik,
    required this.sayfaRengi,
    required this.baslik,
    this.onBaslik = Colors.white,
    required this.altBar,
    this.onAltBar = Colors.white,
    required this.serit,
    required this.qr,
    required this.onQr,
  });

  /// Kimlik yüzeyi üstündeki kapsül ve avatar zemini: yüzeyi %22 koyulaştırır,
  /// beyaz yazının kontrastı her temada artar.
  static const Color kapsulZemini = Color(0x38000000);

  /// Binay: yalnız bugünkü token'lardan türer, yeni renk yoktur.
  static const TemaGecisleri binayAcik = TemaGecisleri(
    kimlik: _Gradyan.kimlik(
        [Color(0xFF8A3600), Color(0xFFA64306), Marka.turuncuKoyu]),
    onKimlik: Colors.white,
    sayfaRengi: Color(0xFFF8F1EC),
    baslik: Marka.turuncuKoyu,
    altBar: Color(0xFF8A3600),
    serit: _Gradyan.serit(
        [Color(0xFFFFE3D1), Color(0xFFFFE3D1), Color(0xFFFFE3D1)]),
    qr: _Gradyan.qr([Marka.turuncu, Marka.turuncuKoyu]),
    onQr: Colors.white,
  );

  static const TemaGecisleri binayKoyu = TemaGecisleri(
    kimlik: _Gradyan.kimlik(
        [Color(0xFF4A1A00), Color(0xFF6A2800), Color(0xFF8A3600)]),
    onKimlik: Colors.white,
    sayfaRengi: Color(0xFF28170C),
    baslik: Color(0xFF8A3600),
    altBar: Color(0xFF4A1A00),
    serit: _Gradyan.serit(
        [Marka.turuncuAcik, Marka.turuncuAcik, Marka.turuncuAcik]),
    qr: _Gradyan.qr([Marka.turuncuAcik, Marka.turuncu]),
    onQr: Color(0xFF4A1A00),
  );

  @override
  TemaGecisleri copyWith({
    LinearGradient? kimlik,
    Color? onKimlik,
    Color? sayfaRengi,
    Color? baslik,
    Color? onBaslik,
    Color? altBar,
    Color? onAltBar,
    LinearGradient? serit,
    LinearGradient? qr,
    Color? onQr,
  }) {
    return TemaGecisleri(
      kimlik: kimlik ?? this.kimlik,
      onKimlik: onKimlik ?? this.onKimlik,
      sayfaRengi: sayfaRengi ?? this.sayfaRengi,
      baslik: baslik ?? this.baslik,
      onBaslik: onBaslik ?? this.onBaslik,
      altBar: altBar ?? this.altBar,
      onAltBar: onAltBar ?? this.onAltBar,
      serit: serit ?? this.serit,
      qr: qr ?? this.qr,
      onQr: onQr ?? this.onQr,
    );
  }

  @override
  TemaGecisleri lerp(ThemeExtension<TemaGecisleri>? other, double t) {
    if (other is! TemaGecisleri) return this;
    return TemaGecisleri(
      kimlik: LinearGradient.lerp(kimlik, other.kimlik, t)!,
      onKimlik: Color.lerp(onKimlik, other.onKimlik, t)!,
      sayfaRengi: Color.lerp(sayfaRengi, other.sayfaRengi, t)!,
      baslik: Color.lerp(baslik, other.baslik, t)!,
      onBaslik: Color.lerp(onBaslik, other.onBaslik, t)!,
      altBar: Color.lerp(altBar, other.altBar, t)!,
      onAltBar: Color.lerp(onAltBar, other.onAltBar, t)!,
      serit: LinearGradient.lerp(serit, other.serit, t)!,
      qr: LinearGradient.lerp(qr, other.qr, t)!,
      onQr: Color.lerp(onQr, other.onQr, t)!,
    );
  }
}

/// Gradyan yönleri tek yerde: kimlik sol üstten (koyu uç, yazının başladığı
/// yer) sağ alta; şerit soldan sağa.
class _Gradyan extends LinearGradient {
  const _Gradyan.kimlik(List<Color> renkler, [List<double> duraklar = _ucDurak])
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: renkler,
          stops: duraklar,
        );
  const _Gradyan.serit(List<Color> renkler)
      : super(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: renkler,
          stops: _ucDurak,
        );
  const _Gradyan.qr(List<Color> renkler)
      : super(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: renkler,
        );

  static const List<double> _ucDurak = [0, 0.5, 1];
}

/* ============================== Renk temaları ============================== */

/// Kullanıcının seçebildiği renk temaları. Kulüp adları yalnız alt etikette
/// (tescilli marka; arma ve logo hiçbir yerde yok), ana etiket renk adıdır.
enum TakimTemasi {
  binay('binay', 'Binay Akademi', 'Kurumsal'),
  sariKirmizi('sari_kirmizi', 'Sarı-Kırmızı', 'Galatasaray renkleri'),
  sariLacivert('sari_lacivert', 'Sarı-Lacivert', 'Fenerbahçe renkleri'),
  bordoMavi('bordo_mavi', 'Bordo-Mavi', 'Trabzonspor renkleri'),
  siyahBeyaz('siyah_beyaz', 'Siyah-Beyaz', 'Beşiktaş renkleri'),
  ayYildiz('ay_yildiz', 'Ay-Yıldız', 'Türkiye renkleri');

  const TakimTemasi(this.kod, this.etiket, this.altEtiket);

  /// Cihazda saklanan değer. Değiştirilirse kullanıcıların seçimi kaybolur.
  final String kod;
  final String etiket;
  final String altEtiket;

  static TakimTemasi cozumle(String? kod) => TakimTemasi.values.firstWhere(
        (t) => t.kod == kod,
        orElse: () => TakimTemasi.binay,
      );
}

/// Bir temanın tek moddaki tüm renkleri.
class TakimPaleti {
  final ColorScheme sema;
  final FitcallRenkleri renkler;
  final TemaGecisleri gecisler;

  const TakimPaleti({
    required this.sema,
    required this.renkler,
    required this.gecisler,
  });
}

/* ================================ Şemalar ================================ */

const ColorScheme _acikSema = ColorScheme(
  brightness: Brightness.light,
  // Marka koyu turuncusunun (C2500B) bir tık koyusu: sayfa zemini takımın açık
  // tonuna boyanınca C2500B yazı/link olarak 4.2:1'e düşüyordu (eşik 4.5).
  // Başlık çubuğu marka turuncusunun kendisi.
  primary: Color(0xFFB54A0A),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFFFE3D1),
  onPrimaryContainer: Color(0xFF5E2200),
  secondary: Marka.mavi,
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFDFE2FF),
  onSecondaryContainer: Color(0xFF101A64),
  tertiary: Color(0xFF0E7C5A),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFD7F2E7),
  onTertiaryContainer: Color(0xFF06301F),
  // C62828: renkli sayfa zemininde DC2626 4.2:1'e düşüyordu (renkler.hata ile
  // aynı ton; yıkıcı buton ve form hata yazıları bunu kullanır).
  error: Color(0xFFC62828),
  onError: Colors.white,
  errorContainer: Color(0xFFFEE2E2),
  onErrorContainer: Color(0xFF7F1D1D),
  surface: Colors.white,
  onSurface: Color(0xFF1B1714),
  onSurfaceVariant: Color(0xFF5C5450),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFFAF9F8),
  surfaceContainer: Color(0xFFF5F2F0),
  surfaceContainerHigh: Color(0xFFEFEBE8),
  surfaceContainerHighest: Color(0xFFE9E4E0),
  surfaceTint: Marka.turuncuKoyu,
  outline: Color(0xFF8A807A),
  outlineVariant: Color(0xFFDED7D2),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFF302A27),
  onInverseSurface: Color(0xFFF6F1EE),
  inversePrimary: Marka.turuncuAcik,
);

const ColorScheme _koyuSema = ColorScheme(
  brightness: Brightness.dark,
  primary: Marka.turuncuAcik,
  onPrimary: Color(0xFF4A1A00),
  primaryContainer: Color(0xFF8A3600),
  onPrimaryContainer: Color(0xFFFFDBC7),
  secondary: Marka.maviAcik,
  onSecondary: Color(0xFF111C6E),
  secondaryContainer: Color(0xFF2A36A8),
  onSecondaryContainer: Color(0xFFDFE2FF),
  tertiary: Color(0xFF43D6A0),
  onTertiary: Color(0xFF00382A),
  tertiaryContainer: Color(0xFF0B5140),
  onTertiaryContainer: Color(0xFFB9F2DD),
  error: Color(0xFFFF7B72),
  onError: Color(0xFF4A0A08),
  errorContainer: Color(0xFF7F1D1D),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF15120F),
  onSurface: Color(0xFFF0EAE5),
  onSurfaceVariant: Color(0xFFC7BDB6),
  surfaceContainerLowest: Color(0xFF0E0B09),
  surfaceContainerLow: Color(0xFF1C1815),
  surfaceContainer: Color(0xFF211C19),
  surfaceContainerHigh: Color(0xFF2C2622),
  surfaceContainerHighest: Color(0xFF37302B),
  surfaceTint: Marka.turuncuAcik,
  outline: Color(0xFF9A8F87),
  outlineVariant: Color(0xFF443C37),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFF0EAE5),
  onInverseSurface: Color(0xFF2B2521),
  inversePrimary: Marka.turuncuKoyu,
);

/* ============================= Takım paletleri ============================= */

/// Bir takım temasının tek moddaki paletini, Binay şemasını temel alarak
/// üretir. Hata, başarı, uyarı gibi durum renkleri ve takvim ders renkleri
/// temelden gelir ve değişmez; yalnız marka rolleri ile nötrler takıma göre
/// ayarlanır.
TakimPaleti _takimPaleti({
  required Brightness parlaklik,
  required Color ana,
  required Color anaUzeri,
  required Color anaKap,
  required Color anaKapUzeri,
  required Color ikincil,
  required Color zemin,
  required Color yazi,
  required Color ikincilYazi,
  required Color kap,
  required Color kapYuksek,
  required Color cizgi,
  required Color tersAna,
  required TemaGecisleri gecisler,
}) {
  final koyu = parlaklik == Brightness.dark;
  final sema = (koyu ? _koyuSema : _acikSema).copyWith(
    primary: ana,
    onPrimary: anaUzeri,
    primaryContainer: anaKap,
    onPrimaryContainer: anaKapUzeri,
    secondary: ikincil,
    onSecondary: uzerineYazi(ikincil),
    secondaryContainer: Color.lerp(zemin, ikincil, koyu ? 0.30 : 0.14),
    onSecondaryContainer: yazi,
    surface: zemin,
    onSurface: yazi,
    onSurfaceVariant: ikincilYazi,
    surfaceContainerLowest:
        koyu ? Color.lerp(zemin, Colors.black, 0.35) : zemin,
    surfaceContainerLow: Color.lerp(zemin, kap, 0.5),
    surfaceContainer: kap,
    surfaceContainerHigh: kapYuksek,
    surfaceContainerHighest: Color.lerp(kapYuksek, cizgi, 0.4),
    outline: Color.lerp(ikincilYazi, zemin, 0.25),
    outlineVariant: cizgi,
    surfaceTint: ana,
    inverseSurface: koyu ? yazi : Color.lerp(yazi, zemin, 0.08),
    onInverseSurface: koyu ? zemin : Color.lerp(zemin, yazi, 0.04),
    inversePrimary: tersAna,
  );
  final renkler = (koyu ? FitcallRenkleri.koyu : FitcallRenkleri.acik).copyWith(
    vurgu: ana,
    vurguZemin: anaKap,
    // Takım rengi "şimdi" çizgisinde kullanılmaz; nötr çizgi.
    simdiCizgisi: yazi,
    takvimZemin: Color.lerp(zemin, kap, 0.5),
    saatCizgisi: cizgi,
    yarimSaatCizgisi: Color.lerp(cizgi, zemin, 0.5),
  );
  return TakimPaleti(sema: sema, renkler: renkler, gecisler: gecisler);
}

/// Verilen tema ve moddaki palet. Değerler tasarım maketiyle aynıdır;
/// her çift test/tema_kontrast_test.dart'ta ölçülür.
TakimPaleti takimPaleti(TakimTemasi takim, Brightness parlaklik) {
  final koyu = parlaklik == Brightness.dark;
  switch (takim) {
    case TakimTemasi.binay:
      return koyu
          ? const TakimPaleti(
              sema: _koyuSema,
              renkler: FitcallRenkleri.koyu,
              gecisler: TemaGecisleri.binayKoyu)
          : const TakimPaleti(
              sema: _acikSema,
              renkler: FitcallRenkleri.acik,
              gecisler: TemaGecisleri.binayAcik);

    // Sarı-Kırmızı: kırmızıdan yanık turuncuya iner; sarıya şerit ulaşır.
    // Sarı açık zeminde yazı olamaz (1.7:1), yalnız dolgu ve şeritte.
    case TakimTemasi.sariKirmizi:
      return koyu
          ? _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFFFDB912),
              anaUzeri: const Color(0xFF3D0012),
              anaKap: const Color(0xFF5E0820),
              anaKapUzeri: const Color(0xFFFFE6A6),
              ikincil: const Color(0xFFFF8A9B),
              zemin: const Color(0xFF160F10),
              yazi: const Color(0xFFF2E9EA),
              ikincilYazi: const Color(0xFFCDBDC0),
              kap: const Color(0xFF231819),
              kapYuksek: const Color(0xFF2E2123),
              cizgi: const Color(0xFF48373A),
              tersAna: const Color(0xFFA90432),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF5E0820),
                  Color(0xFF8E0A2C),
                  Color(0xFF8A4A00),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFF300E16),
                baslik: Color(0xFF8E0A2C),
                altBar: Color(0xFF5E0820),
                serit: _Gradyan.serit([
                  Color(0xFFD0103F),
                  Color(0xFFF07000),
                  Color(0xFFFDB912),
                ]),
                qr: _Gradyan.qr([Color(0xFFFFC83D), Color(0xFFF4A30E)]),
                onQr: Color(0xFF3D0012),
              ),
            )
          : _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFFA90432),
              anaUzeri: Colors.white,
              anaKap: const Color(0xFFFFEFC7),
              anaKapUzeri: const Color(0xFF7E0A26),
              ikincil: const Color(0xFF8A5D00),
              zemin: Colors.white,
              yazi: const Color(0xFF1C1416),
              ikincilYazi: const Color(0xFF5E5254),
              kap: const Color(0xFFF7F2F3),
              kapYuksek: const Color(0xFFF0E9EA),
              cizgi: const Color(0xFFE2D7D9),
              tersAna: const Color(0xFFFDB912),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF7E0A26),
                  Color(0xFFA90432),
                  Color(0xFFAE5800),
                ], [
                  0,
                  0.45,
                  1
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFFF9ECF0),
                baslik: Color(0xFFA90432),
                altBar: Color(0xFF7E0A26),
                serit: _Gradyan.serit([
                  Color(0xFFA90432),
                  Color(0xFFDE6600),
                  Color(0xFFFDB912),
                ]),
                qr: _Gradyan.qr([Color(0xFFA90432), Color(0xFFDE6600)]),
                onQr: Colors.white,
              ),
            );

    // Sarı-Lacivert: lacivertle sarı karıştırılmaz (ara ton zeytine düşer);
    // yüzey lacivert ailesinde kalır, sarı keskin kenarlı şeritte.
    case TakimTemasi.sariLacivert:
      return koyu
          ? _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFFFFD100),
              anaUzeri: const Color(0xFF0F2A5C),
              anaKap: const Color(0xFF1A3A7A),
              anaKapUzeri: const Color(0xFFFFE98A),
              ikincil: const Color(0xFF9DB8F0),
              zemin: const Color(0xFF0C111B),
              yazi: const Color(0xFFE8ECF4),
              ikincilYazi: const Color(0xFFB8C0CF),
              kap: const Color(0xFF161D2B),
              kapYuksek: const Color(0xFF1F2738),
              cizgi: const Color(0xFF343E52),
              tersAna: const Color(0xFF0F2A5C),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF0D2250),
                  Color(0xFF163470),
                  Color(0xFF24489A),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFF0E192E),
                baslik: Color(0xFF163470),
                altBar: Color(0xFF0D2250),
                serit: _Gradyan.serit([
                  Color(0xFFFFE14D),
                  Color(0xFFFFD226),
                  Color(0xFFFFC400),
                ]),
                qr: _Gradyan.qr([Color(0xFFFFDA33), Color(0xFFF5C000)]),
                onQr: Color(0xFF0F2A5C),
              ),
            )
          : _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFF0F2A5C),
              anaUzeri: Colors.white,
              anaKap: const Color(0xFFFFF2B3),
              anaKapUzeri: const Color(0xFF0F2A5C),
              ikincil: const Color(0xFF2F5597),
              zemin: Colors.white,
              yazi: const Color(0xFF121826),
              ikincilYazi: const Color(0xFF525B6B),
              kap: const Color(0xFFF2F4F8),
              kapYuksek: const Color(0xFFEAEEF4),
              cizgi: const Color(0xFFD9DFE8),
              tersAna: const Color(0xFFFFD100),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF0F2A5C),
                  Color(0xFF1A3A7A),
                  Color(0xFF2A4FA0),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFFEEF0F5),
                baslik: Color(0xFF1A3A7A),
                altBar: Color(0xFF0F2A5C),
                serit: _Gradyan.serit([
                  Color(0xFFFFE14D),
                  Color(0xFFFFD226),
                  Color(0xFFFFC400),
                ]),
                qr: _Gradyan.qr([Color(0xFF1A3A7A), Color(0xFF0F2A5C)]),
                onQr: Colors.white,
              ),
            );

    // Bordo-Mavi: bordo ile mavi karışınca gri-lilaya döner; yüzey bordo
    // ailesinde, gök mavisi şeritte.
    case TakimTemasi.bordoMavi:
      return koyu
          ? _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFF8FCBF0),
              anaUzeri: const Color(0xFF2A0612),
              anaKap: const Color(0xFF5C0F27),
              anaKapUzeri: const Color(0xFFCDE9FA),
              ikincil: const Color(0xFFF08AA8),
              zemin: const Color(0xFF140D11),
              yazi: const Color(0xFFF1E9EE),
              ikincilYazi: const Color(0xFFC9BCC4),
              kap: const Color(0xFF21171D),
              kapYuksek: const Color(0xFF2B2027),
              cizgi: const Color(0xFF45363F),
              tersAna: const Color(0xFF7A1734),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF561025),
                  Color(0xFF741835),
                  Color(0xFF8E1F42),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFF290F19),
                baslik: Color(0xFF741835),
                altBar: Color(0xFF561025),
                serit: _Gradyan.serit([
                  Color(0xFF62B5E5),
                  Color(0xFF85C6ED),
                  Color(0xFFA9D8F5),
                ]),
                qr: _Gradyan.qr([Color(0xFFA3D5F3), Color(0xFF79BDEA)]),
                onQr: Color(0xFF2A0612),
              ),
            )
          : _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFF7A1734),
              anaUzeri: Colors.white,
              anaKap: const Color(0xFFDDF0FB),
              anaKapUzeri: const Color(0xFF5C0F27),
              ikincil: const Color(0xFF0B6FB0),
              zemin: Colors.white,
              yazi: const Color(0xFF1A1418),
              ikincilYazi: const Color(0xFF5A5258),
              kap: const Color(0xFFF6F2F4),
              kapYuksek: const Color(0xFFEFE9EC),
              cizgi: const Color(0xFFDED6DA),
              tersAna: const Color(0xFF8FCBF0),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF5C0F27),
                  Color(0xFF7A1734),
                  Color(0xFF8E1F42),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFFF5EEF0),
                baslik: Color(0xFF7A1734),
                altBar: Color(0xFF5C0F27),
                serit: _Gradyan.serit([
                  Color(0xFF62B5E5),
                  Color(0xFF85C6ED),
                  Color(0xFFA9D8F5),
                ]),
                qr: _Gradyan.qr([Color(0xFF8E1F42), Color(0xFF7A1734)]),
                onQr: Colors.white,
              ),
            );

    // Siyah-Beyaz: sahte bir renk eklenmez; vurgu tersine çevirmeden gelir.
    case TakimTemasi.siyahBeyaz:
      return koyu
          ? _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFFF2F2F2),
              anaUzeri: const Color(0xFF111111),
              anaKap: const Color(0xFF3A3A3A),
              anaKapUzeri: const Color(0xFFF2F2F2),
              ikincil: const Color(0xFFA8ADB3),
              zemin: const Color(0xFF0F0F0F),
              yazi: const Color(0xFFEDEDED),
              ikincilYazi: const Color(0xFFBDBDBD),
              kap: const Color(0xFF1C1C1C),
              kapYuksek: const Color(0xFF262626),
              cizgi: const Color(0xFF3D3D3D),
              tersAna: const Color(0xFF111111),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF181818),
                  Color(0xFF262626),
                  Color(0xFF383838),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFF141414),
                baslik: Color(0xFF262626),
                altBar: Color(0xFF181818),
                serit: _Gradyan.serit([
                  Color(0xFFF2F2F2),
                  Color(0xFFC6C6C6),
                  Color(0xFF9A9A9A),
                ]),
                qr: _Gradyan.qr([Colors.white, Color(0xFFE2E2E2)]),
                onQr: Color(0xFF111111),
              ),
            )
          : _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFF111111),
              anaUzeri: Colors.white,
              anaKap: const Color(0xFFEBEBEB),
              anaKapUzeri: const Color(0xFF111111),
              ikincil: const Color(0xFF5F6368),
              zemin: Colors.white,
              yazi: const Color(0xFF141414),
              ikincilYazi: const Color(0xFF575757),
              kap: const Color(0xFFF3F3F3),
              kapYuksek: const Color(0xFFEBEBEB),
              cizgi: const Color(0xFFDADADA),
              tersAna: const Color(0xFFF2F2F2),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF111111),
                  Color(0xFF232323),
                  Color(0xFF3A3A3A),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFFF1F1F1),
                baslik: Color(0xFF232323),
                altBar: Color(0xFF111111),
                serit: _Gradyan.serit([
                  Colors.white,
                  Color(0xFFCECECE),
                  Color(0xFF9E9E9E),
                ]),
                qr: _Gradyan.qr([Color(0xFF3A3A3A), Color(0xFF111111)]),
                onQr: Colors.white,
              ),
            );

    // Ay-Yıldız: bayrak kırmızısı hata kırmızısından ayırt edilemiyor; bu
    // yüzden butonlar ve seçili öğeler antrasit, kırmızı yalnız kimlik yüzeyinde.
    case TakimTemasi.ayYildiz:
      return koyu
          ? _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFFE6E8EB),
              anaUzeri: const Color(0xFF141414),
              anaKap: const Color(0xFF3A3F48),
              anaKapUzeri: const Color(0xFFF0F1F3),
              ikincil: const Color(0xFFC9CDD3),
              zemin: const Color(0xFF140E0E),
              yazi: const Color(0xFFF2EAEA),
              ikincilYazi: const Color(0xFFCDBEBE),
              kap: const Color(0xFF221818),
              kapYuksek: const Color(0xFF2D2121),
              cizgi: const Color(0xFF473838),
              tersAna: const Color(0xFF2B2F36),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF6E0818),
                  Color(0xFF9E0B24),
                  Color(0xFFC8102E),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFF320D13),
                baslik: Color(0xFF9E0B24),
                altBar: Color(0xFF6E0818),
                serit: _Gradyan.serit([
                  Colors.white,
                  Color(0xFFF8F8F8),
                  Color(0xFFF2F2F2),
                ]),
                qr: _Gradyan.qr([Color(0xFFF0F1F3), Color(0xFFD5D9DF)]),
                onQr: Color(0xFF2B2F36),
              ),
            )
          : _takimPaleti(
              parlaklik: parlaklik,
              ana: const Color(0xFF2B2F36),
              anaUzeri: Colors.white,
              anaKap: const Color(0xFFECEDEF),
              anaKapUzeri: const Color(0xFF2B2F36),
              ikincil: const Color(0xFF4A4F57),
              zemin: Colors.white,
              yazi: const Color(0xFF1A1515),
              ikincilYazi: const Color(0xFF5C5454),
              kap: const Color(0xFFF6F2F2),
              kapYuksek: const Color(0xFFEFE9E9),
              cizgi: const Color(0xFFDFD7D7),
              tersAna: const Color(0xFFE6E8EB),
              gecisler: const TemaGecisleri(
                kimlik: _Gradyan.kimlik([
                  Color(0xFF9E0B22),
                  Color(0xFFC8102E),
                  Color(0xFFE30A17),
                ]),
                onKimlik: Colors.white,
                sayfaRengi: Color(0xFFFBEDEF),
                baslik: Color(0xFFC8102E),
                altBar: Color(0xFF9E0B22),
                serit: _Gradyan.serit([
                  Colors.white,
                  Color(0xFFFAE7E9),
                  Color(0xFFF6D0D3),
                ]),
                qr: _Gradyan.qr([Color(0xFF3A3F48), Color(0xFF2B2F36)]),
                onQr: Colors.white,
              ),
            );
  }
}

/* ============================== Sayfa zemini ============================== */

/// Her sayfanın arkasındaki zemin: takım renginin açık tonu
/// ([TemaGecisleri.sayfaRengi]), baştan sona düz.
///
/// Sayfalar bunu kendileri koymaz: tema, sayfa geçişini sararak her rotanın
/// altına yerleştirir (bkz. [_ZeminliGecis]); Scaffold şeffaftır. Böylece
/// 50'yi aşkın ekran tek noktadan temaya uyar. Düz zemin isteyen bir ekran
/// (form, kamera) Scaffold'a kendi rengini verir.
///
/// Düz renk bilerek: yapışkan grup başlıkları ve sabit bantlar aynı rengi
/// boyayıp zeminle birleşebilsin. Gradyanda kaydırınca bant zeminden
/// ayrışırdı.
class SayfaZemini extends StatelessWidget {
  final Widget child;

  const SayfaZemini({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Durum çubuğu varsayılanı sayfa zeminine göre (açık zeminde koyu ikon).
    // Renkli başlıklar (AppBar, BaslikBandi) kendi bölgeleriyle bunun üstüne
    // çizer ve kazanır; başlıksız sayfalar (giriş, QR) önceki ekranın beyaz
    // ikonlarını devralmasın.
    final zemin = context.gecis.sayfaRengi;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: baslikDurumCubugu(zemin),
      child: ColoredBox(color: zemin, child: child),
    );
  }
}

/// Platformun varsayılan sayfa geçişini aynen kullanır, yalnız sayfanın
/// altına [SayfaZemini] koyar. Geçiş süresi ve geri hareketi değişmez.
class _ZeminliGecis extends PageTransitionsBuilder {
  final PageTransitionsBuilder temel;

  const _ZeminliGecis(this.temel);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      temel.delegatedTransition;

  @override
  Duration get transitionDuration => temel.transitionDuration;

  @override
  Duration get reverseTransitionDuration => temel.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return temel.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      SayfaZemini(child: child),
    );
  }
}

// iOS/macOS geçişi Flutter'ın varsayılan haritasından alınır, sınıf adı
// yazılmaz: Flutter 3.44'te `CupertinoPageTransitionsBuilder` material'dan
// cupertino kütüphanesine taşındı (yalnız material import eden dosya yeni
// sürümde derlenmiyor, eski sürümde cupertino importu kullanılmıyor uyarısı
// veriyor). Varsayılan harita iki sürümde de iOS için Cupertino geçişi.
final PageTransitionsBuilder _cupertinoGecisi =
    const PageTransitionsTheme().builders[TargetPlatform.iOS]!;

final PageTransitionsTheme _zeminliGecisler = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android:
        const _ZeminliGecis(PredictiveBackPageTransitionsBuilder()),
    TargetPlatform.iOS: _ZeminliGecis(_cupertinoGecisi),
    TargetPlatform.macOS: _ZeminliGecis(_cupertinoGecisi),
    TargetPlatform.windows: const _ZeminliGecis(ZoomPageTransitionsBuilder()),
    TargetPlatform.linux: const _ZeminliGecis(ZoomPageTransitionsBuilder()),
    TargetPlatform.fuchsia: const _ZeminliGecis(ZoomPageTransitionsBuilder()),
  },
);

/// Renkli başlığın arkasındaki durum çubuğu: ikonlar başlık rengine göre.
/// Durum çubuğu şeffaf kalır (verilmezse Android 14 ve altı başlığın üstüne
/// gri örtü koyar); gezinme çubuğu alanlarına bilerek dokunulmaz.
SystemUiOverlayStyle baslikDurumCubugu(Color baslik) {
  final koyuZemin = uzerineYazi(baslik) == Colors.white;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: koyuZemin ? Brightness.light : Brightness.dark,
    // iOS: durum çubuğunun zemini (ikonlar bunun tersi).
    statusBarBrightness: koyuZemin ? Brightness.dark : Brightness.light,
  );
}

/* ============================== ThemeData =============================== */

class FitcallTema {
  FitcallTema._();

  /// Binay Akademi teması (varsayılan).
  static ThemeData get acik => temasi(TakimTemasi.binay, Brightness.light);
  static ThemeData get koyu => temasi(TakimTemasi.binay, Brightness.dark);

  static final Map<(TakimTemasi, Brightness), ThemeData> _onbellek = {};

  /// Seçilen renk teması ve moddaki tema.
  static ThemeData temasi(TakimTemasi takim, Brightness parlaklik) =>
      _onbellek.putIfAbsent((takim, parlaklik), () {
        final p = takimPaleti(takim, parlaklik);
        return _tema(p.sema, p.renkler, p.gecisler);
      });

  static ThemeData _tema(
      ColorScheme cs, FitcallRenkleri renkler, TemaGecisleri gecisler) {
    final metin = _metinTemasi(cs);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      // Scaffold şeffaf: zemini ve yıkamayı her rotanın altındaki
      // SayfaZemini çizer (bkz. _ZeminliGecis).
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: cs.surface,
      textTheme: metin,
      extensions: <ThemeExtension<dynamic>>[renkler, gecisler],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: _zeminliGecisler,
      // Başlık çubuğu dolu takım renginde; yazı, ikon ve ikon butonları
      // onBaslik. İçine elle renk verilen öğeler (sayaç, çip, sekme) bunu
      // almaz — onlar `context.gecis.onBaslik` okur.
      appBarTheme: AppBarTheme(
        backgroundColor: gecisler.baslik,
        foregroundColor: gecisler.onBaslik,
        iconTheme: IconThemeData(color: gecisler.onBaslik),
        actionsIconTheme: IconThemeData(color: gecisler.onBaslik),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: baslikDurumCubugu(gecisler.baslik),
        titleTextStyle: metin.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: gecisler.onBaslik,
        ),
        toolbarTextStyle: metin.bodyMedium?.copyWith(color: gecisler.onBaslik),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.l),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: Bosluk.xl),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Yaricap.m),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(64, 48),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Yaricap.m),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.6)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Yaricap.m),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurfaceVariant,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Bosluk.l,
          vertical: Bosluk.l,
        ),
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        side: BorderSide(color: cs.outlineVariant),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cs.surface,
        showDragHandle: true,
        dragHandleColor: cs.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Yaricap.sayfa)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface, fontSize: 14),
        actionTextColor: cs.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cs.primary
              : cs.surfaceContainerHighest,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.primary : cs.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cs.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        dividerColor: cs.outlineVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(Yaricap.s),
        ),
        textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
      ),
    );
  }

  /// Tipografi: özel font yok (sistem yazı tipi), ama ölçek ve ağırlıklar
  /// tek yerde tanımlı — ekranlar `fontSize:` yazmak yerine bunları kullanır.
  static TextTheme _metinTemasi(ColorScheme cs) {
    final ana = cs.onSurface;
    final ikincil = cs.onSurfaceVariant;
    return TextTheme(
      displaySmall: TextStyle(
          fontSize: 34, fontWeight: FontWeight.w700, color: ana, height: 1.15),
      headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w700, color: ana, height: 1.2),
      headlineSmall: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: ana, height: 1.2),
      titleLarge: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w700, color: ana, height: 1.25),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: ana, height: 1.3),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: ana, height: 1.3),
      bodyLarge: TextStyle(fontSize: 16, color: ana, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, color: ana, height: 1.4),
      bodySmall: TextStyle(fontSize: 13, color: ikincil, height: 1.35),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: ana, height: 1.2),
      labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ikincil,
          height: 1.2),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ikincil,
          height: 1.2),
    );
  }
}
