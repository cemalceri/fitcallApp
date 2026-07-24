// lib/common/ui_scale.dart
//
// Uygulama genelinde yazı ölçeği (textScaler) üst sınırı.
//
// Neden var: Android'de kullanıcı sistem yazı boyutunu erişilebilirlik için
// çok büyütebiliyor (2.0x'e kadar). Yoğun ekranlar — haftalık takvim şeritleri,
// kort × saat ızgarası, çok alanlı kartlar — bu ölçekte taşar. Okunabilirlik ile
// yerleşim bütünlüğü arasında denge kurmak için ölçeği makul bir üst sınıra
// çekiyoruz: kullanıcı yazıyı büyütebilir ama bir noktadan sonra düzen bozulmaz.
//
// Alt sınır 1.0: yazıyı KÜÇÜLTMEYE izin verilmiyor (küçültme okunabilirliği
// bozar, taşma riski de yok).

import 'package:flutter/material.dart';

/// Desteklenen en büyük yazı ölçeği. Android sistem "en büyük" ayarı ~1.3x'e
/// denk gelir; testler de bu sınıra kadar taşma olmadığını doğrular.
const double kMaksYaziOlcegi = 1.3;

/// Cihazın yazı ölçeğini [1.0, kMaksYaziOlcegi] aralığına sıkıştırır.
TextScaler sinirliYaziOlcegi(BuildContext context) {
  return MediaQuery.textScalerOf(context).clamp(
    minScaleFactor: 1.0,
    maxScaleFactor: kMaksYaziOlcegi,
  );
}

/// MaterialApp.builder için: alt ağacın gördüğü textScaler'ı sınırlar.
/// main.dart tek yerden uygular; böylece her ekran otomatik korunur.
Widget yaziOlceginiSinirla(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(textScaler: sinirliYaziOlcegi(context)),
    child: child ?? const SizedBox.shrink(),
  );
}
