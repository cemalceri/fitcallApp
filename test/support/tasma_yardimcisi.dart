// test/support/tasma_yardimcisi.dart
//
// Taşma (RenderFlex overflow) testleri için ortak altyapı.
//
// Neden var: bir widget yalnızca "normal" telefonda ve varsayılan yazı
// ölçeğinde test edilirse, dar ekranda veya erişilebilirlik ayarıyla yazı
// büyütüldüğünde taşabilir. Gün şeridindeki 1 piksellik taşma tam olarak böyle
// gözden kaçmıştı. Bu yardımcı her widget'ı bir ekran boyutu × yazı ölçeği
// matrisinde render edip hiç taşma olmadığını doğrular.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/common/ui_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test edilen ekran boyutları: küçük telefon → normal → uzun/geniş
const List<Size> kEkranBoyutlari = [
  Size(320, 568), // iPhone SE / eski küçük Android
  Size(360, 640), // en yaygın Android
  Size(412, 915), // Pixel sınıfı
];

/// Yazı ölçekleri. Üst sınır uygulamanın gerçek clamp'iyle (kMaksYaziOlcegi)
/// aynıdır — kullanıcı sistem fontunu 2.0x yapsa bile uygulama bunu
/// kMaksYaziOlcegi'ne çeker (bkz. lib/common/ui_scale.dart). Bu yüzden test de
/// o sınıra kadar taşma olmadığını doğrular; üstünü test etmek gerçekte
/// oluşmayan bir durumu ölçmek olurdu.
const List<double> kYaziOlcekleri = [1.0, 1.15, kMaksYaziOlcegi];

/// [yapici] ile üretilen widget'ı boyut × yazı ölçeği matrisinde render eder ve
/// hiçbir kombinasyonda taşma/istisna olmadığını doğrular.
///
/// [sar]: widget'ı Scaffold gövdesine koymadan önce özel bir sarmalayıcı
/// gerekiyorsa (örn. sabit yükseklik) kullanılır.
void tasmaTesti(
  String ad,
  Widget Function() yapici, {
  List<Size> boyutlar = kEkranBoyutlari,
  List<double> yaziOlcekleri = kYaziOlcekleri,
  Widget Function(Widget)? sar,
  bool koyuTemaDa = true,
}) {
  for (final boyut in boyutlar) {
    for (final olcek in yaziOlcekleri) {
      testWidgets(
        '$ad — ${boyut.width.toInt()}x${boyut.height.toInt()} @${olcek}x taşmıyor',
        (tester) async {
          await tasmaKontrol(
            tester,
            yapici(),
            boyut: boyut,
            yaziOlcegi: olcek,
            sar: sar,
          );
        },
      );
    }
  }

  // Koyu tema tek kombinasyonda: amaç taşmayı değil, tema token'ı eksikliğinden
  // doğan çalışma zamanı hatalarını yakalamak (ThemeExtension okunamazsa burada
  // patlar). Tam matrisi ikiye katlamak test süresini boşuna uzatırdı.
  if (koyuTemaDa) {
    testWidgets('$ad — koyu temada hatasız', (tester) async {
      await tasmaKontrol(
        tester,
        yapici(),
        boyut: const Size(360, 640),
        sar: sar,
        koyu: true,
      );
    });
  }
}

/// Tek bir boyut/ölçek kombinasyonunda taşma kontrolü.
Future<void> tasmaKontrol(
  WidgetTester tester,
  Widget widget, {
  Size boyut = const Size(360, 640),
  double yaziOlcegi = 1.0,
  Widget Function(Widget)? sar,
  bool koyu = false,
}) async {
  tester.view.physicalSize = boyut;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final govde = sar == null ? widget : sar(widget);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr', 'TR'),
      theme: koyu ? FitcallTema.koyu : FitcallTema.acik,
      home: MediaQuery(
        data: MediaQueryData(
          size: boyut,
          textScaler: TextScaler.linear(yaziOlcegi),
        ),
        child: Scaffold(body: govde),
      ),
    ),
  );
  // pumpAndSettle KULLANILMAZ: sürekli animasyonlu bir widget (ör.
  // LinearProgressIndicator) varsa settle olmaz ve testi timeout'a düşürür.
  // Taşma layout anında oluşur; birkaç frame yeterli.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  final istisna = tester.takeException();
  expect(
    istisna,
    isNull,
    reason: '${boyut.width.toInt()}x${boyut.height.toInt()} @${yaziOlcegi}x '
        'render edilirken hata/taşma oluştu: $istisna',
  );
}
