// Ofis ve yönetici üye listeleri artık sayfalı (20'şer, arama sunucuda).
// SayfaliListe'nin durum geçişleri ve rehber tarzı harf grupları.

import 'dart:async';

import 'package:fitcall/common/harf_gruplari.dart';
import 'package:fitcall/common/sayfali_liste.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// [toplam] öğelik sahte sunucu; sayfa boyu 20.
SayfaGetirici<int> _sunucu(int toplam, {List<int>? istenenler}) {
  return (sayfa) async {
    istenenler?.add(sayfa);
    final bas = (sayfa - 1) * 20;
    final son = (bas + 20).clamp(0, toplam);
    return SayfaSonucu(
      ogeler: [for (var i = bas; i < son; i++) i],
      toplamSayfa: (toplam + 19) ~/ 20,
      toplam: toplam,
    );
  };
}

void main() {
  group('SayfaliListe', () {
    test('ilk sayfa, sonra sırayla diğerleri; son sayfadan sonra istek yok',
        () async {
      final istenen = <int>[];
      final liste = SayfaliListe<int>(_sunucu(45, istenenler: istenen));
      expect(liste.ilkYukleniyor, isTrue);

      await liste.yenile();
      expect(liste.ogeler.length, 20);
      expect(liste.toplam, 45);
      expect(liste.dahaVar, isTrue);

      await liste.dahaFazla();
      await liste.dahaFazla();
      expect(liste.ogeler, [for (var i = 0; i < 45; i++) i]);
      expect(liste.dahaVar, isFalse);

      await liste.dahaFazla();
      expect(istenen, [1, 2, 3]);
    });

    test('yükleme sürerken ikinci dahaFazla aynı sayfayı tekrar istemez',
        () async {
      final istenen = <int>[];
      final liste = SayfaliListe<int>(_sunucu(60, istenenler: istenen));
      await liste.yenile();

      // Kaydırma her karede çağırabilir.
      final a = liste.dahaFazla();
      final b = liste.dahaFazla();
      await Future.wait([a, b]);
      expect(istenen, [1, 2]);
      expect(liste.ogeler.length, 40);
    });

    test('ek veri de nesil korumasından geçer', () async {
      // İstatistik kartları getiricinin içinde setState ile yazılıyordu:
      // nesil korumasının dışında kaldığı için yavaş bağlantıda eski
      // aramanın sayıları yeni listenin üstünde kalıyordu.
      final eski = Completer<SayfaSonucu<int>>();
      final liste = SayfaliListe<int>((_) => eski.future);
      final ilk = liste.yenile();

      await liste.yenile(
        getir: (_) async => const SayfaSonucu(
            ogeler: [7], toplamSayfa: 1, toplam: 1, ek: 'yeni'),
      );
      eski.complete(const SayfaSonucu(
          ogeler: [1, 2, 3], toplamSayfa: 1, toplam: 3, ek: 'eski'));
      await ilk;

      expect(liste.ek, 'yeni');
    });

    test('sonraki sayfa ek vermezse eldeki korunur', () async {
      final liste = SayfaliListe<int>((sayfa) async => SayfaSonucu(
            ogeler: [sayfa],
            toplamSayfa: 3,
            toplam: 3,
            ek: sayfa == 1 ? 'istatistik' : null,
          ));
      await liste.yenile();
      expect(liste.ek, 'istatistik');
      await liste.dahaFazla();
      expect(liste.ek, 'istatistik');
    });

    test('arama değişince eski aramanın geç dönen cevabı atılır', () async {
      final eski = Completer<SayfaSonucu<int>>();
      final liste = SayfaliListe<int>((_) => eski.future);
      final ilk = liste.yenile();

      final yeni = liste.yenile(
        getir: (_) async =>
            const SayfaSonucu(ogeler: [7], toplamSayfa: 1, toplam: 1),
      );
      await yeni;
      eski.complete(
          const SayfaSonucu(ogeler: [1, 2, 3], toplamSayfa: 1, toplam: 3));
      await ilk;

      expect(liste.ogeler, [7]);
      expect(liste.toplam, 1);
    });

    test('ilk sayfa hatası liste yerine mesaj olur', () async {
      final liste = SayfaliListe<int>(
          (_) async => throw ApiException('X', 'Sunucuya ulaşılamadı'));
      await liste.yenile();
      expect(liste.hata, 'Sunucuya ulaşılamadı');
      expect(liste.ilkYukleniyor, isFalse);
    });

    test('sonraki sayfa hatası listeyi bozmaz, tekrar denenince devam eder',
        () async {
      var bozuk = true;
      final sunucu = _sunucu(30);
      final liste = SayfaliListe<int>((sayfa) {
        if (sayfa == 2 && bozuk) throw ApiException('X', 'Zaman aşımı');
        return sunucu(sayfa);
      });
      await liste.yenile();
      await liste.dahaFazla();
      expect(liste.ogeler.length, 20);
      expect(liste.dahaHatasi, 'Zaman aşımı');

      // Hata varken kaydırma kendiliğinden tekrar istemez.
      await liste.dahaFazla();
      expect(liste.dahaHatasi, 'Zaman aşımı');

      bozuk = false;
      await liste.dahaTekrarDene();
      expect(liste.dahaHatasi, isNull);
      expect(liste.ogeler.length, 30);
    });

    test('aşağı çekip yenilemede mevcut liste iskelete dönmez', () async {
      final liste = SayfaliListe<int>(_sunucu(5));
      await liste.yenile();
      final f = liste.yenile(iskelet: false);
      expect(liste.ilkYukleniyor, isFalse);
      expect(liste.ogeler.length, 5);
      await f;
    });

    test('yenileme sürerken sonraki sayfa istenmez', () async {
      final istenen = <int>[];
      final sunucu = _sunucu(60, istenenler: istenen);
      final liste = SayfaliListe<int>(sunucu);
      await liste.yenile();

      final bekleyen = Completer<SayfaSonucu<int>>();
      final yenileme = liste.yenile(
        iskelet: false,
        getir: (sayfa) => sayfa == 1 ? bekleyen.future : sunucu(sayfa),
      );
      // Eski sayfa numarasıyla 2. sayfa yeni listenin arkasına eklenmesin.
      await liste.dahaFazla();
      expect(istenen, [1]);

      bekleyen.complete(await sunucu(1));
      await yenileme;
      expect(liste.ogeler, [for (var i = 0; i < 20; i++) i]);
    });

    test('sayfa sınırında ikinci kez gelen kayıt eklenmez', () async {
      // Kaydırırken araya kayıt eklendi: 2. sayfa 19'la başlıyor.
      final liste = SayfaliListe<int>(
        (sayfa) async => SayfaSonucu(
          ogeler: sayfa == 1
              ? [for (var i = 0; i < 20; i++) i]
              : [for (var i = 19; i < 30; i++) i],
          toplamSayfa: 2,
          toplam: 30,
        ),
        anahtar: (o) => o,
      );
      await liste.yenile();
      await liste.dahaFazla();
      expect(liste.ogeler, [for (var i = 0; i < 30; i++) i]);
    });

    test('aşağı çekip yenileme hatasında liste kalır, hata sonda', () async {
      var bozuk = false;
      final sunucu = _sunucu(30);
      final liste = SayfaliListe<int>((sayfa) {
        if (bozuk) throw ApiException('X', 'Bağlantı yok');
        return sunucu(sayfa);
      });
      await liste.yenile();
      bozuk = true;
      await liste.yenile(iskelet: false);
      expect(liste.hata, isNull);
      expect(liste.dahaHatasi, 'Bağlantı yok');
      expect(liste.ogeler.length, 20);

      bozuk = false;
      await liste.dahaTekrarDene();
      expect(liste.dahaHatasi, isNull);
      expect(liste.ogeler.length, 20);
      expect(liste.dahaVar, isTrue);
    });

    test('kapandıktan sonra dönen cevap dinleyici çağırmaz', () async {
      final c = Completer<SayfaSonucu<int>>();
      final liste = SayfaliListe<int>((_) => c.future);
      var cagri = 0;
      final f = liste.yenile();
      liste.addListener(() => cagri++);
      liste.dispose();
      c.complete(const SayfaSonucu(ogeler: [1], toplamSayfa: 1, toplam: 1));
      await f;
      expect(cagri, 0);
    });
  });

  group('harfGruplari', () {
    test('Türkçe harfler temel harfe katlanır, ardışık aynı harf birleşir', () {
      // en_US harmanlamasının döndürdüğü sıra.
      final adlar = ['Can', 'Çağla', 'Cem', 'ılgaz', 'İlker', 'Işık', 'Ömer'];
      final gruplar = harfGruplari(adlar, (a) => a);
      expect(gruplar.map((g) => g.$1), ['C', 'I', 'O']);
      expect(gruplar[0].$2, ['Can', 'Çağla', 'Cem']);
      expect(gruplar[1].$2, ['ılgaz', 'İlker', 'Işık']);
    });

    test('küçük i büyük İ olur, harf dışı #', () {
      expect(basHarf('ilknur'), 'I');
      expect(basHarf('şule'), 'S');
      expect(basHarf('  ümit'), 'U');
      expect(basHarf('2. Takım'), '#');
      expect(basHarf(''), '#');
    });

    test('sunucunun sırası değiştirilmez', () {
      final gruplar = harfGruplari(['Ali', 'Bora', 'Ayşe'], (a) => a);
      expect(gruplar.map((g) => g.$1), ['A', 'B', 'A']);
    });
  });
}
