// App Store ekran görüntüleri.
//
// Uygulamanın gerçek sayfaları iOS modunda (SF Pro, iOS geçişleri, güvenli
// alan) her cihazın kendi çözünürlüğünde çizilir; veri sahte API'den gelir.
// Çalıştırma (fontlar için bkz. README.md):
//   flutter test tool/magaza_gorselleri/magaza_gorselleri_test.dart
// Çıktı: build/magaza_gorselleri/<cihaz>/<sıra>_<sahne>.png

import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/common/ui_scale.dart';
import 'package:firebase_core/firebase_core.dart';
// Firebase'in kendi test yardımcısı (geçişli bağımlılık).
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'cihazlar.dart';
import 'ios_durum_cubugu.dart';
import 'sahneler.dart';
import 'sahte_api.dart';
import 'yenilik_sahneleri.dart';

// --dart-define=SAHNELER=yenilik → "Neler yeni" dokümanının sahneleri
// (build/yenilikler/ altına); --dart-define=CIHAZ=<kod> → yalnız o cihaz.
const _sahneSecimi = String.fromEnvironment('SAHNELER');
const _cihazSecimi = String.fromEnvironment('CIHAZ');
const _cikti = _sahneSecimi == 'yenilik' ? 'yenilikler' : 'magaza_gorselleri';

final _kok = GlobalKey();
const emojiAilesi = 'MagazaEmoji';
final _navigator = GlobalKey<NavigatorState>();

Future<void> _fontlariYukle() async {
  final dizin = Directory('tool/magaza_gorselleri/fontlar');
  if (!dizin.existsSync()) {
    fail('SF Pro fontları yok: ${dizin.path} (bkz. README.md)');
  }
  Future<void> aile(String ad, Iterable<File> dosyalar) async {
    final yukleyici = FontLoader(ad);
    for (final f in dosyalar) {
      yukleyici.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await yukleyici.load();
  }

  final sf = dizin.listSync().whereType<File>().toList();
  await aile('CupertinoSystemText',
      sf.where((f) => f.uri.pathSegments.last.startsWith('SF-Pro-Text-')));
  await aile('CupertinoSystemDisplay',
      sf.where((f) => f.uri.pathSegments.last.startsWith('SF-Pro-Display-')));

  // flutter_tester.exe: <flutter>/bin/cache/artifacts/engine/<platform>/
  final cache = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  await aile('MaterialIcons', [
    File('${cache.path}/artifacts/material_fonts/materialicons-regular.otf')
  ]);
  // Apple Color Emoji indirilemiyor; en yakın renkli emoji fontu (Windows).
  final emoji = File('C:/Windows/Fonts/seguiemj.ttf');
  if (emoji.existsSync()) await aile(emojiAilesi, [emoji]);
  // 'monospace' (IBAN): iOS'ta Menlo; en yakın yerel eşi Consolas.
  final mono = [for (final f in ['consola.ttf', 'consolab.ttf']) File('C:/Windows/Fonts/$f')]
      .where((f) => f.existsSync());
  if (mono.isNotEmpty) await aile('monospace', mono);

  final cupertino = _paketYolu('cupertino_icons');
  if (cupertino != null) {
    await aile('packages/cupertino_icons/CupertinoIcons',
        [File('$cupertino/assets/CupertinoIcons.ttf')]);
  }
}

/// Aile belirtmeyen bileşen stilleri iPhone'da sistem fontuyla (SF Pro)
/// çizilir; test motorunun varsayılanı ise kutu çizen 'FlutterTest' fontu.
/// Burada o stillere iOS'un ailesi açıkça verilir — görünüm cihazdakiyle aynı.
ThemeData _iosSistemFontu(ThemeData t) {
  TextStyle? f(TextStyle? s) => s?.copyWith(
        fontFamily: s.fontFamily ?? 'CupertinoSystemText',
        fontFamilyFallback: const [emojiAilesi],
      );
  WidgetStateProperty<TextStyle?>? w(WidgetStateProperty<TextStyle?>? p) =>
      p == null ? null : WidgetStateProperty.resolveWith((d) => f(p.resolve(d)));
  ButtonStyle? b(ButtonStyle? s) => s?.copyWith(textStyle: w(s.textStyle));
  final i = t.inputDecorationTheme;
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamilyFallback: [emojiAilesi]),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamilyFallback: [emojiAilesi]),
    appBarTheme: t.appBarTheme.copyWith(
      titleTextStyle: f(t.appBarTheme.titleTextStyle),
      toolbarTextStyle: f(t.appBarTheme.toolbarTextStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(style: b(t.filledButtonTheme.style)),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: b(t.elevatedButtonTheme.style)),
    outlinedButtonTheme:
        OutlinedButtonThemeData(style: b(t.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(style: b(t.textButtonTheme.style)),
    inputDecorationTheme: i.copyWith(
      hintStyle: f(i.hintStyle),
      labelStyle: f(i.labelStyle),
      floatingLabelStyle: f(i.floatingLabelStyle),
      helperStyle: f(i.helperStyle),
      errorStyle: f(i.errorStyle),
    ),
    chipTheme: t.chipTheme.copyWith(
      labelStyle: f(t.chipTheme.labelStyle),
      secondaryLabelStyle: f(t.chipTheme.secondaryLabelStyle),
    ),
    snackBarTheme: t.snackBarTheme.copyWith(
        contentTextStyle: f(t.snackBarTheme.contentTextStyle)),
    tooltipTheme: t.tooltipTheme.copyWith(textStyle: f(t.tooltipTheme.textStyle)),
    listTileTheme: t.listTileTheme.copyWith(
      titleTextStyle: f(t.listTileTheme.titleTextStyle),
      subtitleTextStyle: f(t.listTileTheme.subtitleTextStyle),
      leadingAndTrailingTextStyle:
          f(t.listTileTheme.leadingAndTrailingTextStyle),
    ),
    dialogTheme: t.dialogTheme.copyWith(
      titleTextStyle: f(t.dialogTheme.titleTextStyle),
      contentTextStyle: f(t.dialogTheme.contentTextStyle),
    ),
    tabBarTheme: t.tabBarTheme.copyWith(
      labelStyle: f(t.tabBarTheme.labelStyle),
      unselectedLabelStyle: f(t.tabBarTheme.unselectedLabelStyle),
    ),
    navigationBarTheme: t.navigationBarTheme.copyWith(
        labelTextStyle: w(t.navigationBarTheme.labelTextStyle)),
    popupMenuTheme:
        t.popupMenuTheme.copyWith(textStyle: f(t.popupMenuTheme.textStyle)),
  );
}

String? _paketYolu(String paket) {
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final m = RegExp('"name": "$paket",\\s*"rootUri": "([^"]+)"').firstMatch(config);
  if (m == null) return null;
  return Uri.parse(m.group(1)!).toFilePath();
}

Future<void> _kaydet(WidgetTester tester, MagazaCihazi cihaz, String ad) async {
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_kok));
  await tester.runAsync(() async {
    final img = await ro.toImage(pixelRatio: cihaz.pikselOrani);
    final veri = await img.toByteData(format: ui.ImageByteFormat.png);
    final dosya = File('build/$_cikti/${cihaz.kod}/$ad.png');
    dosya.parent.createSync(recursive: true);
    dosya.writeAsBytesSync(veri!.buffer.asUint8List());
    img.dispose();
  });
}

/// Ağdan gelmeyen görselleri (logo vb.) çözüp bir kare daha çizer.
Future<void> _gorselleriBekle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      final img = e.widget as Image;
      try {
        await precacheImage(img.image, e);
      } catch (_) {}
    }
  });
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    // tool/ altı test klasörü sayılmıyor; bu dosya bir test düzeneği.
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Binay Akademi',
      packageName: 'fit.binay.fitcall',
      version: '3.12.0',
      buildNumber: '46',
      buildSignature: '',
    );
    // Bildirim izni açık (iOS'ta izin verilmiş cihaz).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (c) async => switch (c.method) {
        'checkPermissionStatus' => 1,
        'requestPermissions' => <int, int>{},
        _ => null,
      },
    );
    await Firebase.initializeApp();
    await _fontlariYukle();
    await initializeDateFormatting('tr', null);
  });

  final secilenler = _sahneSecimi == 'yenilik' ? yenilikSahneleri : sahneler;
  for (final cihaz in tumCihazlar
        .where((c) => _cihazSecimi.isEmpty || c.kod == _cihazSecimi)) {
    for (final (sira, sahne) in secilenler.indexed) {
      testWidgets('${cihaz.kod} ${sahne.ad}', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        tester.view.physicalSize = cihaz.piksel;
        tester.view.devicePixelRatio = cihaz.pikselOrani;
        tester.view.padding = FakeViewPadding(
          top: cihaz.guvenliAlan.top * cihaz.pikselOrani,
          bottom: cihaz.guvenliAlan.bottom * cihaz.pikselOrani,
        );
        tester.view.viewPadding = tester.view.padding;
        tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearAllTestValues();
        });

        // ignore: invalid_use_of_visible_for_testing_member
        FlutterSecureStorage.setMockInitialValues(sahne.depo());
        SahteApi.senaryo = sahne;

        await http.runWithClient(() async {
          // Tek fark: emoji için yedek font (iOS'ta sistem kendisi bulur).
          final asil = FitcallTema.temasi(TakimTemasi.binay, Brightness.light);
          final tema = _iosSistemFontu(asil);
          final gecis = tema.extension<TemaGecisleri>()!;
          final cubukRengi = sahne.cubukRengi?.call(tema) ?? gecis.onBaslik;

          await tester.pumpWidget(RepaintBoundary(
            key: _kok,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(children: [
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  navigatorKey: _navigator,
                  title: 'Binay Akademi',
                  theme: tema,
                  themeMode: ThemeMode.light,
                  onGenerateRoute: myRouteGenerator,
                  home: Builder(builder: sahne.kur),
                  locale: const Locale('tr', 'TR'),
                  supportedLocales: const [Locale('tr', 'TR')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  builder: yaziOlceginiSinirla,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(
                    child: IosDurumCubugu(
                      cihaz: cihaz,
                      renk: cubukRengi,
                      tarih: DateTime.now(),
                    ),
                  ),
                ),
              ]),
            ),
          ));
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          await sahne.hazirla?.call(tester, _navigator);
          await _gorselleriBekle(tester);
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          await _kaydet(tester, cihaz, '${sira + 1}_${sahne.ad}');
          // Zamanlayıcılar (carousel vb.) test bitmeden temizlensin.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 30));
        }, () => SahteApi.istemci);

        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
