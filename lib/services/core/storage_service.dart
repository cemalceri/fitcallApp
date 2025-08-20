import 'dart:convert';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/4_auth/group_model.dart';
import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  /* ================== TOKEN & STORAGE ================== */
  static Future<bool> tokenGecerliMi() async {
    final exp = await SecureStorageService.getValue<String>('token_exp');
    final dt = exp != null ? DateTime.tryParse(exp) : null;
    return dt != null && dt.isAfter(DateTime.now());
  }

  static Future<String?> getToken() =>
      SecureStorageService.getValue<String>('token');

  static Future<void> clearAll() async {
    await SecureStorageService.clearAll();
  }

  static Future<UyeModel?> uyeBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('uye');
    return s == null ? null : UyeModel.fromJson(json.decode(s));
  }

  static Future<AntrenorModel?> antrenorBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('antrenor');
    return s == null ? null : AntrenorModel.fromJson(json.decode(s));
  }

  static Future<GroupModel?> groupBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('gruplar');
    if (s == null) return null;

    final parsed = json.decode(s);
    if (parsed is List && parsed.isNotEmpty) {
      return GroupModel.fromJson(parsed.first);
    }
    return null;
  }

  static Future<UserModel?> userBilgileriniGetir() async {
    final s = await SecureStorageService.getValue<String>('user');
    return s == null ? null : UserModel.fromJson(json.decode(s));
  }

  static Future<bool> beniHatirlaIsaretlenmisMi() async {
    final v = await SecureStorageService.getValue<bool>('beni_hatirla');
    return v == true;
  }

  static Future<void> saveProfileData({
    required String? uye,
    required String? antrenor,
    required String user,
    required bool anaHesapMi,
    required String gruplar,
    required String uyeProfil,
  }) async {
    await SecureStorageService.setValue<String>('uye', uye ?? "");
    await SecureStorageService.setValue<String>('antrenor', antrenor ?? "");
    await SecureStorageService.setValue<String>('user', user);
    await SecureStorageService.setValue<bool>('ana_hesap_mi', anaHesapMi);
    await SecureStorageService.setValue<String>('gruplar', gruplar);
    await SecureStorageService.setValue<String>('uye_profil', uyeProfil);
  }

  static Future<void> saveTokenData({
    required String token,
    required DateTime expireDate,
  }) async {
    await SecureStorageService.setValue<String>('token', token);
    await SecureStorageService.setValue<String>(
        'token_exp', expireDate.toIso8601String());
  }

  static setBeniHatirla(bool beniHatirla) {
    SecureStorageService.setValue<bool>('beni_hatirla', beniHatirla);
  }
}

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
