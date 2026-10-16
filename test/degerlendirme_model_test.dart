// Değerlendirme listesi modeli — backend biçimiyle (api/etkinlik/
// degerlendirmeler.py) birebir.

import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/degerlendirme_ornekleri.dart';

void main() {
  test('satır ders ve katılımcılarıyla çözülür', () {
    final d = ornekDegerlendirme(yardimci: true);
    expect(d.puan, 5);
    expect(d.degerlendiren.adSoyad, 'Deniz Ayşegül ARSLANOĞULLARI');
    // Sunucu yerel saati offset'le gönderir; okunan saat kayma yapmamalı.
    expect(d.ders.baslangic.hour, 10);
    expect(d.ders.bitis.hour, 11);
    expect(d.ders.yardimciAntrenorAdi, 'Ayşe Öğretmenoğlu TAN');
    expect(d.ders.katilimcilar, hasLength(4));
  });

  test('diğer katılımcılar puanı vereni içermez', () {
    final digerleri = ornekDegerlendirme().ders.digerKatilimcilar;
    expect(digerleri, hasLength(3));
    expect(digerleri.any((k) => k.degerlendirenMi), isFalse);
    expect(digerleri.first.puan, 3);
    expect(digerleri[1].katildi, isFalse);
    expect(digerleri.last.misafir, isTrue);
  });

  test('yorumsuz satır null yorum taşır', () {
    expect(ornekDegerlendirme(yorum: null).yorum, isNull);
  });

  test('özet yalnız gelen sayfada çözülür', () {
    final ilk = DegerlendirmeSayfasi.fromJson({
      'degerlendirmeler': [ornekDegerlendirmeJson()],
      'toplam': 21,
      'toplam_sayfa': 2,
      'ozet': {'ortalama': '4.57', 'adet': 21},
    });
    expect(ilk.ozet?.ortalama, closeTo(4.57, 0.001));
    expect(ilk.ozet?.adet, 21);
    expect(ilk.toplamSayfa, 2);

    final ikinci = DegerlendirmeSayfasi.fromJson({
      'degerlendirmeler': const [],
      'toplam': 21,
      'toplam_sayfa': 2,
    });
    expect(ikinci.ozet, isNull);
  });
}
