import 'dart:convert';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/services/core/storage_service.dart';

/// Terminated senaryosu için pending action’u hem bellekte hem SecureStorage’ta saklar.
class PendingActionStore {
  PendingActionStore._();
  static final PendingActionStore instance = PendingActionStore._();

  static const _key = 'pending_action';
  PendingAction? _current;

  PendingAction? get current => _current;
  bool get hasPending => _current != null;

  /* ---------------- load / save / take ---------------- */
  Future<void> load() async {
    final raw = await SecureStorageService.getValue<String>(_key);
    if (raw == null) return;
    _current = PendingAction.fromJson(jsonDecode(raw));
  }

  Future<void> set(PendingAction action) async {
    _current = action;
    await SecureStorageService.setValue<String>(
        _key, jsonEncode(action.toJson()));
  }

  /// Döner ve temizler
  Future<PendingAction?> take() async {
    final tmp = _current;
    _current = null;
    await SecureStorageService.remove(_key);
    return tmp;
  }
}
