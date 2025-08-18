import 'dart:io' show Platform;
import 'package:fitcall/services/core/app_update/in_app_update_interface.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateAndroid implements IInAppUpdate {
  @override
  Future<bool> immediate() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      final hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final allowed = info.immediateUpdateAllowed == true;
      if (hasUpdate && allowed) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<bool> flexible() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      final hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final allowed = info.flexibleUpdateAllowed == true;
      if (hasUpdate && allowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

IInAppUpdate createInAppUpdate() => InAppUpdateAndroid();
