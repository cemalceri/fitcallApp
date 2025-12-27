import 'dart:convert';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/services/core/storage_service.dart';

class PendingActionStore {
  PendingActionStore._();
  static final PendingActionStore instance = PendingActionStore._();

  static const _key = 'pending_action';
  static const _attemptKey = 'pending_action_attempts';
  static const _maxAttempts = 3;

  PendingAction? _current;

  PendingAction? get current => _current;
  bool get hasPending => _current != null;

  Future<void> load() async {
    final raw = await SecureStorageService.getValue<String>(_key);
    if (raw == null) return;
    try {
      _current = PendingAction.fromJson(jsonDecode(raw));
    } catch (e) {
      await SecureStorageService.remove(_key);
      await SecureStorageService.remove(_attemptKey);
    }
  }

  Future<void> set(PendingAction action) async {
    _current = action;
    await SecureStorageService.setValue<String>(
        _key, jsonEncode(action.toJson()));
    await SecureStorageService.remove(_attemptKey);
  }

  Future<PendingAction?> take() async {
    if (_current == null) {
      await load();
    }

    if (_current == null) return null;

    final attemptCountStr =
        await SecureStorageService.getValue<String>(_attemptKey);
    final attemptCount = int.tryParse(attemptCountStr ?? '0') ?? 0;

    if (attemptCount >= _maxAttempts) {
      await clear();
      return null;
    }

    await SecureStorageService.setValue<String>(
        _attemptKey, '${attemptCount + 1}');
    return _current;
  }

  Future<void> clear() async {
    _current = null;
    await SecureStorageService.remove(_key);
    await SecureStorageService.remove(_attemptKey);
  }
}
