// Renk temalarının okunurluk sözleşmesi.
//
// Her renk teması (Binay + beş takım) açık ve koyu modda tüm yazı/zemin
// çiftleri için WCAG eşiğini geçmek zorunda: metin 4.5:1, ikon ve grafik öğe
// 3:1. Gradyanlı yüzeylerde (kimlik, QR butonu) yazı gradyan boyunca 41
// noktanın en kötüsüne karşı ölçülür — Flutter'ın sRGB'de karıştırdığı ara
// tonlar dahil. "Beyaz zemine beyaz yazı" bu test geçtikçe hiçbir temada
// oluşamaz; yeni bir palet ya da renk değişikliği eşiğin altına düşerse test
// kırılır ve hangi tema/mod/çift olduğunu söyler.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/gradyan.dart';

/// [yazi] ile [zeminler] arasındaki en düşük kontrast.
double enKotu(Color yazi, Iterable<Color> zeminler) =>
    zeminler.map((z) => kontrastOrani(yazi, z)).reduce((a, b) => a < b ? a : b);

/// Kapsül zemini (yüzeyin %22 koyulaştırılmışı) altındaki gerçek renk.
Color kapsulAlti(Color zemin) =>
    Color.alphaBlend(TemaGecisleri.kapsulZemini, zemin);

const List<Brightness> _modlar = [Brightness.light, Brightness.dark];

String _ad(TakimTemasi t, Brightness b) =>
    '${t.etiket} (${b == Brightness.light ? 'açık' : 'koyu'})';

void main() {
  group('Kontrast hesabı', () {
    test('siyah/beyaz 21:1, aynı renk 1:1', () {
      expect(kontrastOrani(Colors.black, Colors.white), closeTo(21, 0.01));
      expect(kontrastOrani(Colors.white, Colors.white), closeTo(1, 0.0001));
    });

    test('sıra fark etmez', () {
      const a = Color(0xFFA90432), b = Color(0xFFFDB912);
      expect(kontrastOrani(a, b), kontrastOrani(b, a));
    });

    test('gradyan örneklemesi uçları ve ara tonları içerir', () {
      const g = LinearGradient(colors: [Colors.black, Colors.white]);
      final o = gradyanOrnekle(g, n: 3);
      expect(o.first, Colors.black);
      expect(o.last, Colors.white);
      expect(o[1].computeLuminance(), inExclusiveRange(0.1, 0.4));
    });
  });

  group('uzerineYazi', () {
    test('iki adaydan kontrastı yüksek olanı seçer', () {
      for (final zemin in const [
        Color(0xFFFF9351), // koyu temanın turuncusu (eski eşik beyaz seçiyordu)
        Color(0xFFFDB912), // altın sarısı
        Color(0xFF0F2A5C), // lacivert
        Color(0xFFDC2626), // hata kırmızısı
        Color(0xFF62B5E5), // gök mavisi
      ]) {
        final secilen = uzerineYazi(zemin);
        final diger =
            secilen == Colors.white ? const Color(0xFF1B1714) : Colors.white;
        expect(
          kontrastOrani(secilen, zemin),
          greaterThanOrEqualTo(kontrastOrani(diger, zemin)),
          reason: 'zemin $zemin',
        );
      }
    });

    test('açık turuncuda koyu yazı seçilir (eski 2.2:1 hatası)', () {
      expect(uzerineYazi(const Color(0xFFFF9351)), isNot(Colors.white));
    });
  });

  for (final takim in TakimTemasi.values) {
    for (final mod in _modlar) {
      group(_ad(takim, mod), () {
        final p = takimPaleti(takim, mod);
        final cs = p.sema;
        final r = p.renkler;
        final g = p.gecisler;
        final sayfa = g.sayfaRengi;

        void metin(String ad, Color yazi, Color zemin, [double esik = 4.5]) {
          final oran = kontrastOrani(yazi, zemin);
          expect(
            oran,
            greaterThanOrEqualTo(esik),
            reason: '${_ad(takim, mod)} · $ad: $yazi / $zemin = '
                '${oran.toStringAsFixed(2)}:1 (eşik $esik)',
          );
        }

        test('şema modla uyumlu', () {
          expect(cs.brightness, mod);
        });

        test('gövde ve ikincil metin her zeminde okunur', () {
          metin('gövde / zemin', cs.onSurface, cs.surface);
          metin('ikincil / zemin', cs.onSurfaceVariant, cs.surface);
          metin('ikincil / kart', cs.onSurfaceVariant, cs.surfaceContainer);
          metin('ikincil / alan', cs.onSurfaceVariant, cs.surfaceContainerLow);
          metin('ikincil / yükseltilmiş', cs.onSurfaceVariant,
              cs.surfaceContainerHigh);
          metin('gövde / en yüksek kap', cs.onSurface,
              cs.surfaceContainerHighest);
        });

        test('takım tonundaki sayfa zemininde metin okunur', () {
          // Liste satırları şeffaf: yazıları doğrudan sayfa zemininde.
          metin('gövde / sayfa', cs.onSurface, sayfa);
          metin('ikincil / sayfa', cs.onSurfaceVariant, sayfa);
          metin('link / sayfa', cs.primary, sayfa);
          metin('hata / sayfa (borç tutarı)', r.hata, sayfa);
          // Yıkıcı buton ve "Fotoğrafı kaldır" şemanın hata rengiyle.
          metin('şema hatası / sayfa', cs.error, sayfa);
          metin('şema hatası / zemin', cs.error, cs.surface);
          metin('başarı / sayfa', r.basari, sayfa);
          metin('bilgi / sayfa', r.bilgi, sayfa);
          // Uyarı rengi metinde kendi zemininde kullanılır; sayfada ikon.
          metin('uyarı ikon / sayfa', r.uyari, sayfa, 3);
          metin('düz buton / sayfa', cs.primary, sayfa, 3);
        });

        test('sayfa zemini temanın rengini taşır, kartlar ondan ayrışır', () {
          // Beyaz/zemin rengiyle aynı değil: temalar birbirine benzemesin.
          expect(sayfa, isNot(cs.surface));
          expect(kontrastOrani(sayfa, cs.surface), greaterThan(1.03));
        });

        test('durum çubuğu ikonları başlık yazısıyla aynı kutupta', () {
          // baslikDurumCubugu ikon rengini uzerineYazi ile seçiyor; başlık
          // yazısı açıkken ikonlar koyu kalırsa saat/pil başlıkta kaybolur.
          expect(uzerineYazi(g.baslik).computeLuminance() > 0.5,
              g.onBaslik.computeLuminance() > 0.5);
        });

        test('başlık çubuğu ve alt menüde yazı okunur', () {
          metin('başlık', g.onBaslik, g.baslik);
          metin('alt menü', g.onAltBar, g.altBar);
          // Seçili başlık çipi / dönem sekmesi: yazı başlık renginde.
          metin('seçili başlık çipi', g.baslik, g.onBaslik);
          // İkon kutuları ve seçili sekme kapsülü yarı saydam açık ton.
          metin(
              'başlık ikon kutusu',
              g.onBaslik,
              Color.alphaBlend(g.onBaslik.withValues(alpha: 0.16), g.baslik),
              3);
          metin('alt menü seçili kapsül', g.onAltBar,
              Color.alphaBlend(g.onAltBar.withValues(alpha: 0.18), g.altBar));
          // Devre dışı başlık butonu yine seçilebilir (ikon eşiği).
          metin(
              'başlıkta devre dışı',
              Color.alphaBlend(g.onBaslik.withValues(alpha: 0.45), g.baslik),
              g.baslik,
              1.5);
        });

        test('alt menüde QR butonu ayrışır (halka ya da dolgu)', () {
          final enIyi = [...g.serit.colors, ...g.qr.colors]
              .map((c) => kontrastOrani(c, g.altBar))
              .reduce((a, b) => a > b ? a : b);
          expect(enIyi, greaterThanOrEqualTo(3),
              reason: '${_ad(takim, mod)} · QR / alt menü '
                  '${enIyi.toStringAsFixed(2)}:1');
        });

        test('ana renk rolleri', () {
          metin('düz buton yazısı', cs.onPrimary, cs.primary);
          metin('link / seçili sekme', cs.primary, cs.surface);
          metin('seçili çip / avatar', cs.onPrimaryContainer,
              cs.primaryContainer);
          metin('ikincil renk / zemin', cs.secondary, cs.surface);
          metin('ikincil kap', cs.onSecondaryContainer, cs.secondaryContainer);
          metin('snackbar', cs.onInverseSurface, cs.inverseSurface);
        });

        test('kimlik yüzeyinde yazı gradyanın her noktasında okunur', () {
          final ornekler = gradyanOrnekle(g.kimlik);
          final oran = enKotu(g.onKimlik, ornekler);
          expect(oran, greaterThanOrEqualTo(4.5),
              reason: '${_ad(takim, mod)} · kimlik yüzeyi en kötü nokta '
                  '${oran.toStringAsFixed(2)}:1');
          // Kapsül zemini yazıyı her zaman güçlendirir.
          expect(enKotu(g.onKimlik, ornekler.map(kapsulAlti)),
              greaterThanOrEqualTo(oran));
        });

        test('kimlik yüzeyi üstündeki durum kapsülü okunur', () {
          // Bakiye kartında borç/alacak, zemin renkli kapsülde.
          metin('borç kapsülü', r.hata, cs.surface);
          metin('alacak kapsülü', r.basari, cs.surface);
        });

        test('QR butonunun ikonu gradyan boyunca görünür', () {
          final oran = enKotu(g.onQr, gradyanOrnekle(g.qr));
          expect(oran, greaterThanOrEqualTo(3),
              reason: '${_ad(takim, mod)} · QR ikonu '
                  '${oran.toStringAsFixed(2)}:1');
        });

        test('durum renkleri düz zeminde okunur', () {
          metin('hata', r.hata, cs.surface);
          metin('başarı', r.basari, cs.surface);
          metin('uyarı', r.uyari, cs.surface);
          metin('bilgi', r.bilgi, cs.surface);
          metin('uyarı / uyarı zemini', r.uyari, r.uyariZemin);
          metin('hata kabı', cs.onErrorContainer, cs.errorContainer);
          metin('başarı kabı (trend)', cs.onTertiaryContainer,
              cs.tertiaryContainer);
        });

        test('ders bloğu metni her durum zemininde okunur', () {
          for (final (ad, zemin) in [
            ('gelecek', r.bilgiZemin),
            ('tamamlandı', r.basariZemin),
            ('bekliyor', r.uyariZemin),
            ('iptal', r.hataZemin),
            ('nötr', r.notrZemin),
          ]) {
            metin('blok başlığı / $ad', cs.onSurface, zemin);
            metin('blok alt satırı / $ad', cs.onSurfaceVariant, zemin);
          }
        });

        test('ödül çubuğunun dolgusu rayın üstünde görünür', () {
          final dolgu = ilerlemeGradyani(cs, g);
          final ray = cs.surfaceContainerHighest;
          final enIyi = dolgu.colors
              .map((c) => kontrastOrani(c, ray))
              .reduce((a, b) => a > b ? a : b);
          expect(enIyi, greaterThanOrEqualTo(3),
              reason: '${_ad(takim, mod)} · ilerleme dolgusu en iyi ton '
                  '${enIyi.toStringAsFixed(2)}:1');
        });

        test('"şimdi" çizgisinin etiketi okunur', () {
          metin('şimdi etiketi', uzerineYazi(r.simdiCizgisi), r.simdiCizgisi);
        });
      });
    }
  }

  group('Tasarım kararları', () {
    test('durum renkleri her temada aynı (yalnız moda göre değişir)', () {
      for (final mod in _modlar) {
        final binay = takimPaleti(TakimTemasi.binay, mod).renkler;
        for (final t in TakimTemasi.values) {
          final r = takimPaleti(t, mod).renkler;
          expect(r.hata, binay.hata, reason: t.etiket);
          expect(r.basari, binay.basari, reason: t.etiket);
          expect(r.uyari, binay.uyari, reason: t.etiket);
          expect(r.bilgi, binay.bilgi, reason: t.etiket);
          expect(r.dersIptal, binay.dersIptal, reason: t.etiket);
          expect(r.dersTamamlandi, binay.dersTamamlandi, reason: t.etiket);
          expect(takimPaleti(t, mod).sema.error,
              takimPaleti(TakimTemasi.binay, mod).sema.error,
              reason: t.etiket);
        }
      }
    });

    test('Ay-Yıldız: butonlar ve seçili öğeler kırmızı değil (antrasit)', () {
      // Bayrak kırmızısı hata kırmızısından ayırt edilemiyor; kırmızı yalnız
      // kimlik yüzeyinde.
      for (final mod in _modlar) {
        final cs = takimPaleti(TakimTemasi.ayYildiz, mod).sema;
        final ana = HSVColor.fromColor(cs.primary);
        final hata = HSVColor.fromColor(cs.error);
        final tonFarki = (ana.hue - hata.hue).abs() % 360;
        final tonUzakligi = tonFarki > 180 ? 360 - tonFarki : tonFarki;
        // Ya neredeyse renksiz ya da tonu kırmızıdan belirgin uzak olmalı.
        expect(ana.saturation < 0.3 || tonUzakligi > 60, isTrue,
            reason: 'mod $mod: doygunluk ${ana.saturation}, '
                'ton farkı $tonUzakligi°');
        // Kimlik yüzeyi ise kırmızı kalır (bayrak rengi).
        final kimlik = HSVColor.fromColor(
            takimPaleti(TakimTemasi.ayYildiz, mod).gecisler.kimlik.colors.last);
        expect(kimlik.saturation, greaterThan(0.6));
      }
    });

    test('Binay paleti duruyor; yalnız birincil bir tık koyu', () {
      final acik = takimPaleti(TakimTemasi.binay, Brightness.light).sema;
      final koyu = takimPaleti(TakimTemasi.binay, Brightness.dark).sema;
      // C2500B renkli sayfa zemininde 4.2:1'e düşüyordu (bkz. tema.dart).
      expect(acik.primary, const Color(0xFFB54A0A));
      expect(takimPaleti(TakimTemasi.binay, Brightness.light).gecisler.baslik,
          Marka.turuncuKoyu);
      expect(acik.secondary, Marka.mavi);
      expect(acik.surface, Colors.white);
      expect(acik.onSurface, const Color(0xFF1B1714));
      expect(koyu.primary, const Color(0xFFFF9351));
      expect(koyu.surface, const Color(0xFF15120F));
      expect(takimPaleti(TakimTemasi.binay, Brightness.light).renkler,
          FitcallRenkleri.acik);
    });

    test('her temada gradyan uzunlukları eşit (tema geçişi pürüzsüz lerp)', () {
      final ref = takimPaleti(TakimTemasi.binay, Brightness.light).gecisler;
      for (final t in TakimTemasi.values) {
        for (final mod in _modlar) {
          final g = takimPaleti(t, mod).gecisler;
          expect(g.kimlik.colors.length, ref.kimlik.colors.length);
          expect(g.serit.colors.length, ref.serit.colors.length);
          expect(g.qr.colors.length, ref.qr.colors.length);
        }
      }
    });

    test('kimlik gradyanında koyu uç sol üstte (yazının başladığı yer)', () {
      for (final t in TakimTemasi.values) {
        for (final mod in _modlar) {
          final k = takimPaleti(t, mod).gecisler.kimlik;
          expect(k.begin, Alignment.topLeft);
          expect(
            k.colors.first.computeLuminance(),
            lessThanOrEqualTo(k.colors.last.computeLuminance() + 0.001),
            reason: _ad(t, mod),
          );
        }
      }
    });
  });
}
