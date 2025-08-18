import 'in_app_update_interface.dart';

/// iOS/Web/desktop için no-op implementasyon
class InAppUpdateStub implements IInAppUpdate {
  @override
  Future<bool> immediate() async => false;

  @override
  Future<bool> flexible() async => false;
}

/// Koşullu import ile dışarıdan çağrılan factory
IInAppUpdate createInAppUpdate() => InAppUpdateStub();
