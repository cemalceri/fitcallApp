// lib/services/core/app_update/in_app_update_android.dart
//
// Play In-App Update sarmalayıcısı.
//
// Dönen `bool`un anlamı: "güncelleme GERÇEKTEN yapıldı mı". Çağıran taraf
// (GuncellemeKoordinatoru) false görünce zorunlu güncelleme ekranını açıyor,
// true görünce akışa devam ediyor — dolayısıyla burada iyimser davranmak
// zorunlu güncellemeyi tamamen delik hâle getirir.

import 'dart:io' show Platform;
import 'package:fitcall/services/core/app_update/in_app_update_interface.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateAndroid implements IInAppUpdate {
  /// Play çağrıları testte yapılamadığı için platform kontrolü ve üç plugin
  /// çağrısı enjekte edilebilir. Üretimde hepsi varsayılan değerini alır.
  InAppUpdateAndroid({
    bool? androidMi,
    Future<AppUpdateInfo> Function()? kontrolEt,
    Future<AppUpdateResult> Function()? immediateBaslat,
    Future<AppUpdateResult> Function()? flexibleBaslat,
    Future<void> Function()? flexibleTamamla,
  })  : _androidMi = androidMi ?? Platform.isAndroid,
        _kontrolEt = kontrolEt ?? InAppUpdate.checkForUpdate,
        _immediateBaslat = immediateBaslat ?? InAppUpdate.performImmediateUpdate,
        _flexibleBaslat = flexibleBaslat ?? InAppUpdate.startFlexibleUpdate,
        _flexibleTamamla = flexibleTamamla ?? InAppUpdate.completeFlexibleUpdate;

  final bool _androidMi;
  final Future<AppUpdateInfo> Function() _kontrolEt;
  final Future<AppUpdateResult> Function() _immediateBaslat;
  final Future<AppUpdateResult> Function() _flexibleBaslat;
  final Future<void> Function() _flexibleTamamla;

  @override
  Future<bool> immediate() async {
    if (!_androidMi) return false;
    try {
      final info = await _kontrolEt();
      final hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final allowed = info.immediateUpdateAllowed == true;
      if (hasUpdate && allowed) {
        // Kullanıcı Play'in tam ekran güncelleme akışında geri tuşuna basarsa
        // Play USER_DENIED_UPDATE döner ve plugin bunu İSTİSNA DEĞİL, değer
        // olarak verir. Bu dönüş eskiden yok sayılıp koşulsuz true dönülüyordu;
        // sonuç: zorunlu güncelleme Android'de geri tuşuyla atlanabiliyordu
        // (koordinatör true görüp bloklayan ekranı hiç açmıyordu).
        return await _immediateBaslat() == AppUpdateResult.success;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<bool> flexible() async {
    if (!_androidMi) return false;
    try {
      final info = await _kontrolEt();
      final hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final allowed = info.flexibleUpdateAllowed == true;
      if (hasUpdate && allowed) {
        // İndirme onayı reddedilirse kurulumu tamamlamaya çalışmak anlamsız.
        if (await _flexibleBaslat() != AppUpdateResult.success) return false;
        await _flexibleTamamla();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

IInAppUpdate createInAppUpdate() => InAppUpdateAndroid();
