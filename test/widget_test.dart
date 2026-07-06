// Rota tanımlarının tutarlılığını doğrulayan temel testler.
// (Eski dosya, Flutter şablonundan kalan ve hiç geçmeyen sayaç testiydi.)

import 'package:fitcall/common/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her SayfaAdi için rota tanımlı', () {
    for (final sayfa in SayfaAdi.values) {
      expect(routeEnums.containsKey(sayfa), true,
          reason: '$sayfa için rota stringi eksik');
    }
  });

  test('her rota stringi için builder tanımlı', () {
    for (final entry in routeEnums.entries) {
      expect(routes.containsKey(entry.value), true,
          reason: '${entry.key} (${entry.value}) için builder eksik');
    }
  });

  test('public rotalar rota tablosunda mevcut', () {
    for (final route in publicRoutes) {
      expect(routes.containsKey(route), true,
          reason: 'Public rota $route tanımsız');
    }
  });

  test('erişim politikası tanımlı rotalar geçerli', () {
    for (final route in accessPolicies.keys) {
      expect(routes.containsKey(route), true,
          reason: 'Erişim politikası tanımlı $route rotası tabloda yok');
    }
  });
}
