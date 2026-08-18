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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Desteklenen en büyük yazı ölçeği. Android sistem "en büyük" ayarı ~1.3x'e
/// denk gelir; testler de bu sınıra kadar taşma olmadığını doğrular.
const double kMaksYaziOlcegi = 1.3;

/// Cihazın yazı ölçeğini [1.0, kMaksYaziOlcegi] aralığına sıkıştırır.
TextScaler sinirliYaziOlcegi(BuildContext context) {
  return _SinirliYaziOlcegi(MediaQuery.textScalerOf(context));
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

/// Cihaz ölçeğini [1.0, kMaksYaziOlcegi] arasına sıkıştıran ölçekleyici.
///
/// Neden hazır `TextScaler.clamp` değil: clamp'in döndürdüğü tip, üstüne ikinci
/// bir clamp gelip aralık bir noktaya çöktüğünde (alt sınır = üst sınır)
/// `maxScale > minScale` doğrulamasıyla patlıyor. Material'in tarih seçicisi tam
/// bunu yapıyor — başlığı `min(mevcut ölçek, 1.4)` ile sınırlıyor; cihaz ölçeği
/// 1.0 iken bu bizim alt sınırımızla çakışıyor ve doğum tarihi takvimi açılmıyordu.
/// TextScaler'ın taban `clamp`'i bu durumu güvenle sabit ölçeğe indiriyor; kendi
/// sınıfımızı yazınca o davranışı miras alıyoruz.
///
/// Ölçekleme cihazın kendi eğrisiyle yapılır (Android 14+ doğrusal olmayan yazı
/// ölçeği korunur), yalnız sonucu sınırlarız.
class _SinirliYaziOlcegi extends TextScaler {
  const _SinirliYaziOlcegi(this.cihaz);

  final TextScaler cihaz;

  @override
  double scale(double yaziBoyutu) => clampDouble(
        cihaz.scale(yaziBoyutu),
        yaziBoyutu,
        yaziBoyutu * kMaksYaziOlcegi,
      );

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => clampDouble(
        // ignore: deprecated_member_use
        cihaz.textScaleFactor,
        1.0,
        kMaksYaziOlcegi,
      );

  @override
  bool operator ==(Object other) =>
      other is _SinirliYaziOlcegi && other.cihaz == cihaz;

  @override
  int get hashCode => cihaz.hashCode;

  @override
  String toString() => 'sinirli(1.0–$kMaksYaziOlcegi, $cihaz)';
}
