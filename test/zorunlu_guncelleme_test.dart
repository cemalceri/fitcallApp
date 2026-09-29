// Zorunlu güncellemenin geri tuşuyla atlanamadığını doğrular.
//
// Regresyon: Android'de `force` direktifi geldiğinde Play'in tam ekran
// (immediate) güncelleme akışı açılıyor. Kullanıcı orada geri tuşuna basınca
// Play USER_DENIED_UPDATE döndürüyor — plugin bunu istisna değil DEĞER olarak
// veriyor. Sarmalayıcı bu dönüşü yok sayıp koşulsuz `true` döndürdüğü için
// koordinatör "güncellendi" sanıp bloklayan ekranı hiç açmıyordu; uygulama
// eski sürümle çalışmaya devam ediyordu.

import 'package:fitcall/screens/1_common/3_mobil_app/app_update_page.dart';
import 'package:fitcall/services/core/app_update/in_app_update_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

AppUpdateInfo _bilgi({
  UpdateAvailability durum = UpdateAvailability.updateAvailable,
  bool immediate = true,
  bool flexible = true,
}) =>
    AppUpdateInfo(
      updateAvailability: durum,
      immediateUpdateAllowed: immediate,
      immediateAllowedPreconditions: null,
      flexibleUpdateAllowed: flexible,
      flexibleAllowedPreconditions: null,
      availableVersionCode: 42,
      installStatus: InstallStatus.unknown,
      packageName: 'fit.binay.fitcall',
      clientVersionStalenessDays: null,
      updatePriority: 5,
    );

void main() {
  group('immediate (zorunlu) güncelleme', () {
    test('kullanıcı geri tuşuyla vazgeçerse BAŞARISIZ sayılır', () async {
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(),
        immediateBaslat: () async => AppUpdateResult.userDeniedUpdate,
      );

      // false = koordinatör bloklayan güncelleme ekranını açacak.
      expect(await servis.immediate(), isFalse);
    });

    test('Play tarafında hata olursa başarısız sayılır', () async {
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(),
        immediateBaslat: () async => AppUpdateResult.inAppUpdateFailed,
      );

      expect(await servis.immediate(), isFalse);
    });

    test('güncelleme tamamlanırsa başarılı sayılır', () async {
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(),
        immediateBaslat: () async => AppUpdateResult.success,
      );

      expect(await servis.immediate(), isTrue);
    });

    test('güncelleme yoksa Play akışı hiç başlatılmaz', () async {
      var baslatildi = false;
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async =>
            _bilgi(durum: UpdateAvailability.updateNotAvailable),
        immediateBaslat: () async {
          baslatildi = true;
          return AppUpdateResult.success;
        },
      );

      expect(await servis.immediate(), isFalse);
      expect(baslatildi, isFalse);
    });

    test('immediate akışa izin yoksa başlatılmaz', () async {
      var baslatildi = false;
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(immediate: false),
        immediateBaslat: () async {
          baslatildi = true;
          return AppUpdateResult.success;
        },
      );

      expect(await servis.immediate(), isFalse);
      expect(baslatildi, isFalse);
    });

    test('Play çağrısı istisna atarsa başarısız sayılır', () async {
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => throw Exception('Play servisi yok'),
      );

      expect(await servis.immediate(), isFalse);
    });

    test('Android değilse hiç denenmez', () async {
      final servis = InAppUpdateAndroid(
        androidMi: false,
        kontrolEt: () async => throw StateError('çağrılmamalı'),
      );

      expect(await servis.immediate(), isFalse);
    });
  });

  group('flexible güncelleme', () {
    test('indirme reddedilirse kurulum denenmez', () async {
      var tamamlandi = false;
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(),
        flexibleBaslat: () async => AppUpdateResult.userDeniedUpdate,
        flexibleTamamla: () async => tamamlandi = true,
      );

      expect(await servis.flexible(), isFalse);
      expect(tamamlandi, isFalse);
    });

    test('indirme başarılıysa kurulum tamamlanır', () async {
      var tamamlandi = false;
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(),
        flexibleBaslat: () async => AppUpdateResult.success,
        flexibleTamamla: () async => tamamlandi = true,
      );

      expect(await servis.flexible(), isTrue);
      expect(tamamlandi, isTrue);
    });

    test('flexible akışa izin yoksa başlatılmaz', () async {
      var baslatildi = false;
      final servis = InAppUpdateAndroid(
        androidMi: true,
        kontrolEt: () async => _bilgi(flexible: false),
        flexibleBaslat: () async {
          baslatildi = true;
          return AppUpdateResult.success;
        },
      );

      expect(await servis.flexible(), isFalse);
      expect(baslatildi, isFalse);
    });
  });

  // Eski (3.9.0 altı) Android istemcilere sunucu artık `force` yerine
  // `blocked` gönderiyor; o yol doğrudan BloklayanSayfa'yı açar. Sayfaların
  // sistem geri tuşunu yuttuğu burada sabitleniyor.
  group('bloklayan sayfalar geri tuşuyla kapanmaz', () {
    Future<void> sayfayiAcVeGeriBas(WidgetTester tester, Widget sayfa) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => sayfa)),
            child: const Text('aç'),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      // Android'in sistem geri tuşu
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('BloklayanSayfa', (tester) async {
      await sayfayiAcVeGeriBas(
        tester,
        BloklayanSayfa(
          title: 'Erişim Engellendi',
          message: 'Bu sürüm kullanılamaz.',
          actionText: 'Güncelle',
          onAction: () async {},
        ),
      );
      expect(find.text('Erişim Engellendi'), findsOneWidget);
    });

    testWidgets('ZorunluGuncellemeSayfasi', (tester) async {
      await sayfayiAcVeGeriBas(
        tester,
        const ZorunluGuncellemeSayfasi(
          appStoreUrl: 'https://apps.apple.com/app/id1',
          storeVersion: '3.9.0',
          currentVersion: '3.8.1',
          title: 'Güncelleme gerekli',
          message: 'Devam etmek için güncelleyin.',
        ),
      );
      expect(find.text('Güncelleme gerekli'), findsOneWidget);
      expect(find.text('Mevcut: v3.8.1  •  Mağaza: v3.9.0'), findsOneWidget);
    });
  });

  group('sürüm satırı', () {
    test('iki sürüm de biliniyorsa ikisini yazar', () {
      expect(
          surumSatiri('3.8.1', '3.9.0'), 'Mevcut: v3.8.1  •  Mağaza: v3.9.0');
    });

    test('yüklü sürüm okunamazsa boş "Mevcut: v" yazmaz', () {
      expect(surumSatiri('', '3.9.0'), 'Mağaza: v3.9.0');
    });
  });
}
