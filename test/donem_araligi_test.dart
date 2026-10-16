// Raporlar başlığındaki dönem aralığı. Sunucudaki `get_tarih_araligi` ile
// aynı günleri saymalı: dönem bugünde biter, hafta pazartesi, ay ayın 1'i
// başlar (api/yonetici/metots.py).

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  // 15 Ekim 2026 perşembe.
  final persembe = DateTime(2026, 10, 15, 21, 30);

  test('aralık sunucuyla aynı günleri kapsıyor', () {
    expect(DonemFiltresi.bugun.aralik(persembe),
        (DateTime(2026, 10, 15), DateTime(2026, 10, 15)));
    expect(DonemFiltresi.buHafta.aralik(persembe),
        (DateTime(2026, 10, 12), DateTime(2026, 10, 15)));
    expect(DonemFiltresi.buAy.aralik(persembe),
        (DateTime(2026, 10, 1), DateTime(2026, 10, 15)));
  });

  test('aynı ay içinde başlangıçta yalnız gün yazılır', () {
    expect(DonemFiltresi.bugun.aralikMetni(persembe), '15 Eki');
    expect(DonemFiltresi.buHafta.aralikMetni(persembe), '12 – 15 Eki');
    expect(DonemFiltresi.buAy.aralikMetni(persembe), '1 – 15 Eki');
  });

  test('pazartesi ve ayın 1\'i tek gün', () {
    expect(DonemFiltresi.buHafta.aralikMetni(DateTime(2026, 10, 12)),
        '12 Eki');
    expect(DonemFiltresi.buAy.aralikMetni(DateTime(2026, 10, 1)), '1 Eki');
  });

  test('ay ve yıl dönen hafta iki ayı da yazar', () {
    // 2 Ekim 2026 cuma → hafta 28 Eylül pazartesi başlar.
    expect(DonemFiltresi.buHafta.aralikMetni(DateTime(2026, 10, 2)),
        '28 Eyl – 2 Eki');
    // 1 Ocak 2027 cuma → hafta 28 Aralık 2026.
    expect(DonemFiltresi.buHafta.aralikMetni(DateTime(2027, 1, 1)),
        '28 Ara – 1 Oca');
  });
}
