// lib/services/uygulama_guncelleme_servisi.dart

import 'dart:io';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/core/app_update/in_app_update_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/models/1_common/mobil_uygulama_konfig_model.dart';

enum GuncellemeDirektifi {
  none,
  maintenance,
  blocked,
  force,
  immediate,
  flex,
  soft
}

GuncellemeDirektifi _parseDirektif(String? s) {
  switch ((s ?? 'none').toLowerCase()) {
    case 'maintenance':
      return GuncellemeDirektifi.maintenance;
    case 'blocked':
      return GuncellemeDirektifi.blocked;
    case 'force':
      return GuncellemeDirektifi.force;
    case 'immediate':
      return GuncellemeDirektifi.immediate;
    case 'flex':
      return GuncellemeDirektifi.flex;
    case 'soft':
      return GuncellemeDirektifi.soft;
    default:
      return GuncellemeDirektifi.none;
  }
}

class GuncellemeKarari {
  final GuncellemeDirektifi direktif;
  final MobilUygulamaKonfigModel konfig;
  const GuncellemeKarari(this.direktif, this.konfig);
}

class UygulamaGuncellemeServisi {
  UygulamaGuncellemeServisi._();
  static final UygulamaGuncellemeServisi instance =
      UygulamaGuncellemeServisi._();

  /// Context kullanmadan sadece karar üretir. (POST)
  Future<GuncellemeKarari?> kontrolEt() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isFuchsia) {
      return null;
    }

    final pkg = await PackageInfo.fromPlatform();
    final version = pkg.version;
    final build = int.tryParse(pkg.buildNumber);
    final platform =
        Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other');
    if (platform == 'other') return null;

    final locale = Intl.getCurrentLocale();

    final body = <String, dynamic>{
      'platform': platform,
      'version': version,
      'locale': locale,
      if (build != null) 'build': build,
    };

    final res = await ApiClient.postParsed<MobilUygulamaKonfigModel>(
      getMobilConfigs,
      body,
      (j) =>
          MobilUygulamaKonfigModel.fromMap((j as Map).cast<String, dynamic>()),
      auth: false,
    );

    final cfg = res.data;
    if (cfg == null) return null;

    final d = _parseDirektif(cfg.direktif);
    return GuncellemeKarari(d, cfg);
  }

  // Android güncellemeleri: wrapper üzerinden
  Future<bool> androidImmediate() => inAppUpdate.immediate();
  Future<bool> androidFlexible() => inAppUpdate.flexible();
}
