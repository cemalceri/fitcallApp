import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// Generic yazma.
  /// Eğer [value] bir String ise direkt saklar,
  /// aksi halde JSON encode edip saklar.
  static Future<void> setValue<T>(String key, T value) async {
    if (value is String) {
      // String ise doğrudan sakla
      await _storage.write(key: key, value: value);
    } else {
      // Başka tip (örn. Map, List) -> JSON'a çevir
      final jsonStr = jsonEncode(value);
      await _storage.write(key: key, value: jsonStr);
    }
  }

  /// Generic okuma.
  /// T == String ise doğrudan döndürür,
  /// aksi halde JSON decode edip T'ye cast etmeye çalışır.
  static Future<T?> getValue<T>(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;

    if (T == String) {
      return raw as T;
    } else {
      // decode
      try {
        final decoded = jsonDecode(raw);
        return decoded as T;
      } catch (e) {
        return null;
      }
    }
  }

  /// Silme
  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }

  /// Tümünü silme
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
