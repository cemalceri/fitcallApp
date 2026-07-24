// API tarih/saat sözleşmesinin mobil tarafındaki regresyon testleri.
// Backend karşılığı: tests/api/test_tarih_sozlesmesi.py
//
// Buradaki testlerin sebebi: Dart'ta DateTime.parse offset'li bir metni
// UTC'ye çevirip isUtc=true yapar; .hour ve DateFormat o durumda UTC saatini
// verir. Backend "2026-07-23T10:00:00+03:00" gönderdiğinde ham parse 07:00
// okur. parseApiTarih .toLocal() uygulayarak duvar saatini geri getirir.

import 'package:fitcall/common/tarih_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseApiTarih — okuma', () {
    test('offsetli değeri yerel duvar saatine çevirir', () {
      final d = parseApiTarih('2026-07-23T10:00:00+03:00')!;
      final beklenen = DateTime.parse('2026-07-23T10:00:00+03:00').toLocal();

      expect(d.isUtc, isFalse);
      expect(d, beklenen);
      expect(d.millisecondsSinceEpoch, beklenen.millisecondsSinceEpoch);
    });

    test('ham DateTime.parse ile aynı ANI gösterir (kaydırma yok)', () {
      const metin = '2026-07-23T10:00:00+03:00';
      expect(
        parseApiTarih(metin)!.millisecondsSinceEpoch,
        DateTime.parse(metin).millisecondsSinceEpoch,
      );
    });

    test('Z ile gelen değeri yerele çevirir', () {
      final d = parseApiTarih('2026-07-23T07:00:00Z')!;
      expect(d.isUtc, isFalse);
      expect(d.millisecondsSinceEpoch,
          DateTime.parse('2026-07-23T07:00:00Z').millisecondsSinceEpoch);
    });

    test('offsetsiz değeri olduğu gibi yerel kabul eder', () {
      final d = parseApiTarih('2026-07-23T10:00:00')!;
      expect(d.isUtc, isFalse);
      expect(d.hour, 10);
      expect(d.minute, 0);
      expect(d.day, 23);
    });

    test('saatsiz gün metnini kabul eder', () {
      final d = parseApiTarih('2026-07-23')!;
      expect(d.year, 2026);
      expect(d.month, 7);
      expect(d.day, 23);
    });

    test('boş ve geçersiz değerlerde null döner, fırlatmaz', () {
      expect(parseApiTarih(null), isNull);
      expect(parseApiTarih(''), isNull);
      expect(parseApiTarih('   '), isNull);
      expect(parseApiTarih('dün akşam'), isNull);
    });

    test('DateTime verilirse UTC olanı yerele çevirir', () {
      final utc = DateTime.utc(2026, 7, 23, 7);
      final d = parseApiTarih(utc)!;
      expect(d.isUtc, isFalse);
      expect(d.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
    });

    test('parseApiTarihOrNow geçersizde varsayılanı döner', () {
      final varsayilan = DateTime(2020, 1, 1);
      expect(parseApiTarihOrNow('bozuk', varsayilan: varsayilan), varsayilan);
      expect(parseApiTarihOrNow('2026-07-23T10:00:00').hour, 10);
    });

    test('parseApiGun saat bileşenini sıfırlar', () {
      final d = parseApiGun('2026-07-23T15:45:00')!;
      expect(d.hour, 0);
      expect(d.minute, 0);
      expect(d.day, 23);
    });
  });

  group('formatApiTarih — yazma', () {
    test('offsetsiz yerel ISO üretir', () {
      final metin = formatApiTarih(DateTime(2026, 7, 23, 10, 0));
      expect(metin, '2026-07-23T10:00:00');
      expect(metin.contains('Z'), isFalse, reason: 'UTC göstergesi olmamalı');
      expect(metin.contains('+'), isFalse, reason: 'offset olmamalı');
    });

    test('tek haneli ay/gün/saat sıfırla doldurulur', () {
      expect(formatApiTarih(DateTime(2026, 1, 5, 9, 5)), '2026-01-05T09:05:00');
    });

    test('UTC DateTime verilirse duvar saatine çevirir', () {
      final utc = DateTime.utc(2026, 7, 23, 7);
      expect(formatApiTarih(utc), formatApiTarih(utc.toLocal()));
    });

    test('mikrosaniye/salise taşınmaz', () {
      final d = DateTime(2026, 7, 23, 10, 0, 30, 123, 456);
      expect(formatApiTarih(d), '2026-07-23T10:00:30');
    });

    test('formatApiGun yalnızca günü verir', () {
      expect(formatApiGun(DateTime(2026, 7, 23, 22, 30)), '2026-07-23');
    });
  });

  group('gidiş-dönüş', () {
    test('yazılan değer geri okunduğunda aynı duvar saatini verir', () {
      final asil = DateTime(2026, 7, 23, 10, 0);
      final geri = parseApiTarih(formatApiTarih(asil))!;
      expect(geri, asil);
    });

    test('backend formatı okunup tekrar yazılınca saat korunur', () {
      // Sunucu yerel+offset döner, mobil naive yerel geri gönderir.
      final okunan = parseApiTarih('2026-07-23T10:00:00+03:00')!;
      final geriYazilan = formatApiTarih(okunan);
      expect(parseApiTarih(geriYazilan), okunan);
    });
  });
}
