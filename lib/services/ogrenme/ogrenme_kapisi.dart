// lib/services/ogrenme/ogrenme_kapisi.dart
//
// Öğrenme modunun ağdaki güvenlik ağı. Rehber son adımda butonu zaten
// kilitler; bu kapı, ekranda gözden kaçan bir yol olsa bile hiçbir yazma
// isteğinin sunucuya gitmemesini garanti eder. ApiClient'ın her yöntemi
// isteği açmadan önce [denetle]'yi çağırır.

import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ogrenme/uc_siniflari.dart';

abstract final class OgrenmeKapisi {
  /// Rehber açıkken true. Kapalıyken maliyet tek bir bool okumasıdır.
  static bool acik = false;

  /// Bu oturumda engellenen uçlar (testler boş kalmasını ister).
  static final List<String> engellenenler = [];

  /// Kapı açıkken okuma ve altyapı dışındaki her isteği ağa çıkmadan durdurur.
  /// [dosya] true ise (dosya yükleme) uç adına bakılmadan engellenir.
  static void denetle(String url, {bool dosya = false}) {
    if (!acik) return;
    final ad = ucAdi(url);
    if (!dosya && (okumaUclari.contains(ad) || altyapiUclari.contains(ad))) {
      return;
    }
    engellenenler.add(ad);
    throw ApiException('OGRENME_MODU', 'Rehber açıkken bir şey değişmez.');
  }
}
