// API tarih/saat sözleşmesinin mobil tarafındaki regresyon testleri.
// Backend karşılığı: tests/api/test_tarih_sozlesmesi.py
//
// Buradaki testlerin sebebi (2026-08-02'de düzeltilen hata):
// Dart'ta DateTime.parse offset'li bir metni UTC'ye çevirip isUtc=true yapar.
// Eskiden parseApiTarih .toLocal() uyguluyordu; .toLocal() CİHAZIN saat
// dilimini kullandığı için saat dilimi Europe/Istanbul olmayan bir telefonda
// 08:30 başlayan ders 11:30 (ya da 05:30) görünüyordu — üstelik aynı dersin
// bildirim metni sunucuda üretildiği için 08:30 diyordu.
//
// Artık kural: gelen her an KULÜP duvar saatine (Europe/Istanbul, sabit UTC+3)
// indirgenir. Aşağıdaki beklentiler bu yüzden cihazın saat diliminden bağımsız
// yazılmıştır — "toLocal() ile aynı" gibi bir karşılaştırma YOKTUR, çünkü öyle
// bir test yalnızca Türkiye saatindeki makinede geçer.

import 'package:fitcall/common/tarih_util.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bir anın kulüp duvar saati — testin bağımsız referansı.
/// (Cihaz saat dilimini hiç kullanmaz.)
DateTime _kulupBeklenen(String isoAn) {
  final d = DateTime.parse(isoAn).toUtc().add(const Duration(hours: 3));
  return DateTime(d.year, d.month, d.day, d.hour, d.minute, d.second,
      d.millisecond, d.microsecond);
}

void main() {
  group('parseApiTarih — okuma (kulüp saati)', () {
    test('offsetli değeri kulüp duvar saatiyle verir', () {
      final d = parseApiTarih('2026-07-23T10:00:00+03:00')!;
      expect(d.isUtc, isFalse);
      expect(d.hour, 10);
      expect(d.minute, 0);
      expect(d.day, 23);
    });

    test('Z ile gelen değeri kulüp saatine çevirir', () {
      final d = parseApiTarih('2026-07-23T07:00:00Z')!;
      expect(d.isUtc, isFalse);
      expect(d.hour, 10, reason: '07:00 UTC = 10:00 Istanbul');
    });

    test('offsetsiz değer zaten kulüp saatidir, kaydırılmaz', () {
      final d = parseApiTarih('2026-07-23T10:00:00')!;
      expect(d.isUtc, isFalse);
      expect(d.hour, 10);
      expect(d.day, 23);
    });

    test('aynı anı gösteren üç biçim aynı duvar saatini verir', () {
      final a = parseApiTarih('2026-07-23T10:00:00+03:00')!;
      final b = parseApiTarih('2026-07-23T07:00:00Z')!;
      final c = parseApiTarih('2026-07-23T10:00:00')!;
      expect(a, b);
      expect(b, c);
    });

    test('sonuç cihazın saat diliminden bağımsızdır', () {
      // Beklenen değer yalnızca "an" üzerinden hesaplanıyor; makinenin saat
      // dilimi ne olursa olsun bu eşitlik korunmalı.
      for (final metin in [
        '2026-08-01T08:30:00+03:00',
        '2026-08-01T05:30:00Z',
        '2026-01-15T22:45:00+03:00',
        '2026-12-31T23:59:00Z',
      ]) {
        expect(parseApiTarih(metin), _kulupBeklenen(metin), reason: metin);
      }
    });

    test('canlı vaka: 08:30 dersi 08:30 görünür (11:30 değil)', () {
      // Etkinlik 86512 — DB 2026-08-01T05:30:00Z, API "+03:00" ile gönderiyor.
      final d = parseApiTarih('2026-08-01T08:30:00+03:00')!;
      expect(
          '${d.hour.toString().padLeft(2, '0')}:'
              '${d.minute.toString().padLeft(2, '0')}',
          '08:30');
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

    test('DateTime verilirse UTC olanı kulüp saatine çevirir', () {
      final utc = DateTime.utc(2026, 7, 23, 7);
      final d = parseApiTarih(utc)!;
      expect(d.isUtc, isFalse);
      expect(d.hour, 10);
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

  group('simdiKulup / bugunKulup', () {
    test('şimdi, anın kulüp karşılığıdır (cihaz saat diliminden bağımsız)', () {
      final beklenen = DateTime.now().toUtc().add(const Duration(hours: 3));
      final s = simdiKulup();
      expect(s.isUtc, isFalse);
      expect(
        s
            .difference(DateTime(beklenen.year, beklenen.month, beklenen.day,
                beklenen.hour, beklenen.minute, beklenen.second))
            .inSeconds
            .abs(),
        lessThanOrEqualTo(2),
      );
    });

    test('bugün, kulüp saatine göre gün başlangıcıdır', () {
      final b = bugunKulup();
      final s = simdiKulup();
      expect(b.hour, 0);
      expect(b.minute, 0);
      expect(b.year, s.year);
      expect(b.month, s.month);
      expect(b.day, s.day);
    });
  });

  group('kulupAnI — gerçek an', () {
    test('kulüp duvar saatini doğru UTC anına çevirir', () {
      final kulup = parseApiTarih('2026-08-01T08:30:00+03:00')!;
      expect(
        kulupAnI(kulup).millisecondsSinceEpoch,
        DateTime.parse('2026-08-01T08:30:00+03:00').millisecondsSinceEpoch,
      );
      expect(kulupAnI(kulup).isUtc, isTrue);
    });

    test('parse -> kulupAnI gidiş-dönüşü anı korur', () {
      for (final metin in [
        '2026-08-01T08:30:00+03:00',
        '2026-01-15T22:45:00Z',
        '2026-12-31T23:59:00+03:00',
      ]) {
        expect(
          kulupAnI(parseApiTarih(metin)!).millisecondsSinceEpoch,
          DateTime.parse(metin).millisecondsSinceEpoch,
          reason: metin,
        );
      }
    });
  });

  group('formatApiTarih — yazma', () {
    test('offsetsiz kulüp saati ISO üretir', () {
      final metin = formatApiTarih(DateTime(2026, 7, 23, 10, 0));
      expect(metin, '2026-07-23T10:00:00');
      expect(metin.contains('Z'), isFalse, reason: 'UTC göstergesi olmamalı');
      expect(metin.contains('+'), isFalse, reason: 'offset olmamalı');
    });

    test('tek haneli ay/gün/saat sıfırla doldurulur', () {
      expect(formatApiTarih(DateTime(2026, 1, 5, 9, 5)), '2026-01-05T09:05:00');
    });

    test('UTC DateTime verilirse kulüp duvar saatine çevirir', () {
      expect(
          formatApiTarih(DateTime.utc(2026, 7, 23, 7)), '2026-07-23T10:00:00');
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
      expect(parseApiTarih(formatApiTarih(asil)), asil);
    });

    test('backend formatı okunup tekrar yazılınca saat korunur', () {
      // Sunucu kulüp saati + offset döner, mobil offsetsiz kulüp saati gönderir.
      final okunan = parseApiTarih('2026-07-23T10:00:00+03:00')!;
      expect(formatApiTarih(okunan), '2026-07-23T10:00:00');
      expect(parseApiTarih(formatApiTarih(okunan)), okunan);
    });
  });
}
