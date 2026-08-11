// lib/services/core/tema_service.dart
//
// Tema modu tercihi (Sistem / Açık / Koyu).
//
// Tercih cihazda saklanır; uygulama açılışında `TemaKontrol.yukle()` ile
// okunur ve `main.dart` bu notifier'ı dinleyerek `MaterialApp.themeMode`'u
// besler. Çıkış yapıldığında güvenli depo temizlendiği için tercih
// `StorageService.cikisYap()` içinde korunup geri yazılır — kullanıcı
// oturumdan çıkınca teması sıfırlanmasın.

import 'package:flutter/material.dart';
import 'package:fitcall/services/core/storage_service.dart';

class TemaKontrol {
  TemaKontrol._();

  static const String anahtar = 'tema_modu';

  /// Aktif tema modu. `MaterialApp` bunu dinler.
  static final ValueNotifier<ThemeMode> modu =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Açılışta cihazdaki tercihi okur. Kayıt yoksa sistem teması kullanılır.
  static Future<void> yukle() async {
    final kayit = await SecureStorageService.getValue<String>(anahtar);
    modu.value = cozumle(kayit);
  }

  /// Tercihi değiştirir ve cihaza yazar.
  static Future<void> ayarla(ThemeMode yeni) async {
    modu.value = yeni;
    await SecureStorageService.setValue<String>(anahtar, kodla(yeni));
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
