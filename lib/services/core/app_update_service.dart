import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  Future<void> checkAndForceUpdate(BuildContext context) async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await _checkAndroidImmediateUpdate();
    } else if (Platform.isIOS) {
      await _checkIosAndBlockIfNeeded(context);
    }
  }

  /* ---------------- ANDROID: Immediate In-App Update ---------------- */
  Future<void> _checkAndroidImmediateUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      // Güncelleme var mı ve immediate izinli mi?
      final hasUpdate =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      final immediateAllowed = info.immediateUpdateAllowed == true;

      if (hasUpdate && immediateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        debugPrint(
            '[InAppUpdate] hasUpdate=$hasUpdate immediateAllowed=$immediateAllowed (güncelleme yok ya da immediate izinli değil)');
      }
    } on PlatformException catch (e, s) {
      // Örn: app Play Store’dan kurulmadıysa, Play Services yoksa vb.
      debugPrint(
          '[InAppUpdate][PlatformException] code=${e.code}, message=${e.message}');
      debugPrint('$s');
    } on Exception catch (e, s) {
      // Genel hata
      debugPrint('[InAppUpdate][Exception] $e');
      debugPrint('$s');
    }
  }

  /* ---------------- iOS: App Store sürümü ile karşılaştır ---------------- */
  Future<void> _checkIosAndBlockIfNeeded(BuildContext context) async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final bundleId = pkg.packageName;
      final current = pkg.version;

      final url =
          Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId');
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body);
      if (data['resultCount'] == 0) return;

      final result = data['results'][0];
      final storeVersion = (result['version'] as String).trim();
      final trackUrl = (result['trackViewUrl'] as String?) ??
          'https://apps.apple.com/app/id${result['trackId']}';

      if (_isStoreNewer(storeVersion, current)) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _ForceUpdatePage(
              appStoreUrl: trackUrl,
              storeVersion: storeVersion,
              currentVersion: current,
            ),
          ),
        );
      }
    } on Exception catch (e, s) {
      debugPrint('[iOS Update Check] $e');
      debugPrint('$s');
    }
  }

  /// x.y.z karşılaştırması: store > current ?
  bool _isStoreNewer(String store, String current) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final a = parse(store);
    final b = parse(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai > bi) return true;
      if (ai < bi) return false;
    }
    return false;
  }
}

/* ---------------- iOS zorunlu güncelleme ekranı ---------------- */
class _ForceUpdatePage extends StatelessWidget {
  final String appStoreUrl;
  final String storeVersion;
  final String currentVersion;

  const _ForceUpdatePage({
    required this.appStoreUrl,
    required this.storeVersion,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // geri tuşunu kapat
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.system_update, size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'Yeni bir sürüm mevcut',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mevcut: v$currentVersion  •  Mağaza: v$storeVersion',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(appStoreUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Güncelle'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Devam etmek için uygulamayı güncellemeniz gerekiyor.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
