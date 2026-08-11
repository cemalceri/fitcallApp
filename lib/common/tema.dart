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

import 'package:flutter/material.dart';

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
}

/// Verilen zemin üzerinde okunan metin/ikon rengi (siyah ya da beyaz).
///
/// Durum renkleri koyu temada açılıyor (amber, açık turuncu): üzerlerine sabit
/// beyaz yazmak orada okunmaz hâle geliyordu.
Color uzerineYazi(Color zemin) =>
    zemin.computeLuminance() > 0.45 ? const Color(0xFF1B1714) : Colors.white;

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
    hata: Color(0xFFDC2626),
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

/// Kısayollar: `context.renkler.basari`, `context.cs.primary`, `context.metin`.
extension TemaKisayollari on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get metin => Theme.of(this).textTheme;
  FitcallRenkleri get renkler =>
      Theme.of(this).extension<FitcallRenkleri>() ?? FitcallRenkleri.acik;
  bool get koyuTema => Theme.of(this).brightness == Brightness.dark;
}

/* ================================ Şemalar ================================ */

const ColorScheme _acikSema = ColorScheme(
  brightness: Brightness.light,
  primary: Marka.turuncuKoyu,
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
  error: Color(0xFFDC2626),
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

/* ============================== ThemeData =============================== */

class FitcallTema {
  FitcallTema._();

  static ThemeData get acik => _tema(_acikSema, FitcallRenkleri.acik);
  static ThemeData get koyu => _tema(_koyuSema, FitcallRenkleri.koyu);

  static ThemeData _tema(ColorScheme cs, FitcallRenkleri renkler) {
    final metin = _metinTemasi(cs);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      textTheme: metin,
      extensions: <ThemeExtension<dynamic>>[renkler],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: metin.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
