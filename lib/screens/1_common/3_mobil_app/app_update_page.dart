// lib/screens/1_common/update/guncelleme_sayfalari.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/1_common/mobil_uygulama_konfig_model.dart';
import 'package:fitcall/services/core/app_update/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// Koordinatör: servis kararını alır, UI’ı uygular.
class GuncellemeKoordinatoru {
  static Future<void> kontrolVeUygula(
    BuildContext context, {
    UygulamaGuncellemeServisi? servis,
  }) async {
    final s = servis ?? UygulamaGuncellemeServisi.instance;
    final karar = await s.kontrolEt();
    if (karar == null) return;

    switch (karar.direktif) {
      case GuncellemeDirektifi.maintenance:
        await _pushBloklayan(
          context,
          title: karar.konfig.mesajBaslik ?? 'Bakımdayız',
          message: karar.konfig.mesaj ?? 'Kısa süreli bakım çalışması.',
          actionText: 'Yenile',
          onAction: () async => await kontrolVeUygula(context, servis: s),
        );
        break;

      case GuncellemeDirektifi.blocked:
        await _pushBloklayan(
          context,
          title: karar.konfig.mesajBaslik ?? 'Erişim Engellendi',
          message: karar.konfig.mesaj ??
              'Bu sürüm kullanılamaz. Lütfen güncelleyin.',
          actionText: 'Güncelle',
          onAction: () async => await _openStore(karar.konfig.magazaUrl),
        );
        break;

      case GuncellemeDirektifi.force:
        if (Platform.isAndroid) {
          final ok = await s.androidImmediate();
          if (ok) return;
          await _pushBloklayan(
            context,
            title: karar.konfig.mesajBaslik ?? 'Güncelleme gerekli',
            message: karar.konfig.mesaj ??
                'Devam etmek için uygulamayı güncelleyiniz.',
            actionText: 'Güncelle',
            onAction: () async => await _openStore(karar.konfig.magazaUrl),
          );
        } else {
          await _pushZorunlu(
            context,
            cfg: karar.konfig,
            currentVersionText: await _mevcutSurum(),
          );
        }
        break;

      case GuncellemeDirektifi.immediate:
        if (Platform.isAndroid) {
          await s.androidImmediate();
        } else {
          await _openStore(karar.konfig.magazaUrl);
        }
        break;

      case GuncellemeDirektifi.flex:
        if (Platform.isAndroid) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Güncelleme indiriliyor...')));
          final ok = await s.androidFlexible();
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güncelleme tamamlandı.')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Güncelleme başlatılamadı.')));
          }
        } else {
          await _openStore(karar.konfig.magazaUrl);
        }
        break;

      case GuncellemeDirektifi.soft:
        await _showSoftDialog(
          context,
          title: karar.konfig.mesajBaslik ?? 'Yeni sürüm mevcut',
          message: karar.konfig.mesaj ?? 'Güncellemeniz önerilir.',
          storeUrl: karar.konfig.magazaUrl,
        );
        break;

      case GuncellemeDirektifi.none:
        break;
    }
  }

  /// Yüklü sürüm; okunamazsa null (sayfa o parçayı yazmaz).
  static Future<String?> _mevcutSurum() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _openStore(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _showSoftDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String? storeUrl,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Daha sonra')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openStore(storeUrl);
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  static Future<void> _pushZorunlu(
    BuildContext context, {
    required MobilUygulamaKonfigModel cfg,
    String? currentVersionText,
  }) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ZorunluGuncellemeSayfasi(
        appStoreUrl: cfg.magazaUrl ?? '',
        storeVersion: cfg.enSon,
        currentVersion: currentVersionText ?? '',
        title: cfg.mesajBaslik ?? 'Güncelleme gerekli',
        message: cfg.mesaj ?? 'Devam etmek için güncelleme zorunlu.',
      ),
    ));
  }

  static Future<void> _pushBloklayan(
    BuildContext context, {
    required String title,
    required String message,
    required String actionText,
    required Future<void> Function() onAction,
  }) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BloklayanSayfa(
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
      ),
    ));
  }
}

/// "Mevcut: v3.8.1  •  Mağaza: v3.9.0". Bilinmeyen parça yazılmaz — eskiden
/// yüklü sürüm hiç iletilmediği için ekranda boş "Mevcut: v" duruyordu.
String surumSatiri(String mevcut, String magaza) => [
      if (mevcut.isNotEmpty) 'Mevcut: v$mevcut',
      if (magaza.isNotEmpty) 'Mağaza: v$magaza',
    ].join('  •  ');

/// iOS (ve genel) zorunlu güncelleme sayfası
class ZorunluGuncellemeSayfasi extends StatelessWidget {
  final String appStoreUrl;
  final String storeVersion;
  final String currentVersion;
  final String title;
  final String message;

  const ZorunluGuncellemeSayfasi({
    super.key,
    required this.appStoreUrl,
    required this.storeVersion,
    required this.currentVersion,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          // Başlık ve mesaj sunucudan gelir, uzunluğu bilinmez: küçük ekran +
          // büyük yazıda sabit Column taşıyordu. Kısa içerik yine ortada durur.
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 72),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(surumSatiri(currentVersion, storeVersion),
                      textAlign: TextAlign.center),
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
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bakım/blocked gibi bloklayan durumlar için genel sayfa
class BloklayanSayfa extends StatelessWidget {
  final String title;
  final String message;
  final String actionText;
  final Future<void> Function() onAction;

  const BloklayanSayfa({
    super.key,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          // Başlık ve mesaj sunucudan gelir, uzunluğu bilinmez: küçük ekran +
          // büyük yazıda sabit Column taşıyordu. Kısa içerik yine ortada durur.
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 72),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await onAction();
                    },
                    child: Text(actionText),
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
