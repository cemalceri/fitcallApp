// lib/services/core/tema_service.dart
//
// Tema tercihleri: mod (Sistem / Açık / Koyu) ve renk teması (Binay ya da
// takım renkleri).
//
// İki tercih birbirinden bağımsızdır ("Sarı-Lacivert + Koyu" gibi her
// kombinasyon geçerli). İkisi de cihazda saklanır, yani telefondaki tüm
// profiller aynı temayı görür. Uygulama açılışında `TemaKontrol.yukle()` ile
// okunur; `main.dart` iki notifier'ı dinleyip `MaterialApp`'i besler. Çıkışta
// güvenli depo temizlendiği için anahtarlar `StorageService.clearAll()` içinde
// korunup geri yazılır — kullanıcı oturumdan çıkınca teması sıfırlanmasın.

import 'package:flutter/material.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/services/core/storage_service.dart';

class TemaKontrol {
  TemaKontrol._();

  static const String anahtar = 'tema_modu';
  static const String takimAnahtari = 'tema_takim';

  /// Aktif tema modu. `MaterialApp` bunu dinler.
  static final ValueNotifier<ThemeMode> modu =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Aktif renk teması. Kayıt yoksa Binay Akademi.
  static final ValueNotifier<TakimTemasi> takim =
      ValueNotifier<TakimTemasi>(TakimTemasi.binay);

  /// Açılışta cihazdaki tercihleri okur. Kayıt yoksa sistem modu ve Binay.
  static Future<void> yukle() async {
    final kayitlar = await Future.wait([
      SecureStorageService.getValue<String>(anahtar),
      SecureStorageService.getValue<String>(takimAnahtari),
    ]);
    modu.value = cozumle(kayitlar[0]);
    takim.value = TakimTemasi.cozumle(kayitlar[1]);
  }

  /// Mod tercihini değiştirir ve cihaza yazar.
  static Future<void> ayarla(ThemeMode yeni) async {
    modu.value = yeni;
    await SecureStorageService.setValue<String>(anahtar, kodla(yeni));
  }

  /// Renk temasını değiştirir ve cihaza yazar. Değişiklik anında uygulanır;
  /// geri almak tek dokunuş.
  static Future<void> takimAyarla(TakimTemasi yeni) async {
    takim.value = yeni;
    await SecureStorageService.setValue<String>(takimAnahtari, yeni.kod);
  }

  static String kodla(ThemeMode m) => switch (m) {
        ThemeMode.light => 'acik',
        ThemeMode.dark => 'koyu',
        ThemeMode.system => 'sistem',
      };

  static ThemeMode cozumle(String? kayit) => switch (kayit) {
        'acik' => ThemeMode.light,
        'koyu' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String etiket(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Açık',
        ThemeMode.dark => 'Koyu',
        ThemeMode.system => 'Sistem',
      };

  static IconData ikon(ThemeMode m) => switch (m) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };
}
