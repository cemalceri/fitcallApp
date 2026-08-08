import 'package:fitcall/services/notification/app_badge_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Platform kanalı ve güvenli depolama yerine geçen sahte kanal.
class _SahteKanal implements RozetKanali {
  final List<int> yazilanRozetler = [];
  int saklanan = 0;
  bool rozetYazmaHatasi = false;
  bool okumaHatasi = false;

  @override
  Future<void> rozetiYaz(int sayi) async {
    if (rozetYazmaHatasi) throw Exception('launcher rozeti desteklemiyor');
    yazilanRozetler.add(sayi);
  }

  @override
  Future<int> sonSayiyiOku() async {
    if (okumaHatasi) throw Exception('depolama okunamadı');
    return saklanan;
  }

  @override
  Future<void> sonSayiyiYaz(int sayi) async => saklanan = sayi;
}

void main() {
  late _SahteKanal kanal;

  setUp(() {
    kanal = _SahteKanal();
    AppBadgeService.kanal = kanal;
    // Varsayılan: pozitif rozet yazan platform (iOS). Android davranışı ayrı
    // grupta doğrulanıyor.
    AppBadgeService.pozitifRozetYazilir = true;
  });

  tearDown(() {
    AppBadgeService.kanal = const RozetKanali();
    AppBadgeService.pozitifRozetYazilir = true;
  });

  group('AppBadgeService.senkronla', () {
    test('sayıyı hem rozete hem kalıcı kayda yazar', () async {
      await AppBadgeService.senkronla(5);

      expect(kanal.yazilanRozetler, [5]);
      expect(kanal.saklanan, 5);
    });

    test('0 gönderilince rozeti kaldırır', () async {
      await AppBadgeService.senkronla(3);
      await AppBadgeService.senkronla(0);

      expect(kanal.yazilanRozetler, [3, 0]);
      expect(kanal.saklanan, 0);
    });

    test('negatif sayıyı 0 kabul eder', () async {
      await AppBadgeService.senkronla(-2);

      expect(kanal.yazilanRozetler, [0]);
      expect(kanal.saklanan, 0);
    });

    test('rozeti desteklemeyen cihazda hata fırlatmaz', () async {
      kanal.rozetYazmaHatasi = true;

      await expectLater(AppBadgeService.senkronla(4), completes);
    });
  });

  group('AppBadgeService.artir', () {
    test('saklanan sayacı bir artırıp yeni değeri döndürür', () async {
      kanal.saklanan = 2;

      final sonuc = await AppBadgeService.artir();

      expect(sonuc, 3);
      expect(kanal.yazilanRozetler, [3]);
      expect(kanal.saklanan, 3);
    });

    test('kayıt yokken 1 ile başlar', () async {
      final sonuc = await AppBadgeService.artir();

      expect(sonuc, 1);
      expect(kanal.yazilanRozetler, [1]);
    });

    test('kayıt okunamazsa 1 ile devam eder', () async {
      kanal.okumaHatasi = true;

      final sonuc = await AppBadgeService.artir();

      expect(sonuc, 1);
      expect(kanal.yazilanRozetler, [1]);
    });

    test('arka planda biriken sayaç üst üste artar', () async {
      await AppBadgeService.artir();
      await AppBadgeService.artir();
      final sonuc = await AppBadgeService.artir();

      expect(sonuc, 3);
      expect(kanal.yazilanRozetler, [1, 2, 3]);
    });
  });

  test('temizle rozeti sıfırlar', () async {
    kanal.saklanan = 7;

    await AppBadgeService.temizle();

    expect(kanal.yazilanRozetler, [0]);
    expect(kanal.saklanan, 0);
  });

  // app_badge_plus Xiaomi/HyperOS'ta rozeti N adet SAHTE BİLDİRİM göndererek
  // kuruyor; okunmamışı 15 olan kullanıcıya 15 satır düşüyordu. Android'de
  // pozitif değer plugin'e hiç gitmemeli.
  group('Android: pozitif rozet plugin\'e yazılmaz', () {
    setUp(() => AppBadgeService.pozitifRozetYazilir = false);

    test('pozitif sayı plugin\'e gitmez ama kayda yazılır', () async {
      await AppBadgeService.senkronla(15);

      expect(kanal.yazilanRozetler, isEmpty);
      expect(kanal.saklanan, 15);
    });

    test('sıfır yine gönderilir — rozeti temizlemenin tek yolu', () async {
      await AppBadgeService.senkronla(9);
      await AppBadgeService.senkronla(0);

      expect(kanal.yazilanRozetler, [0]);
      expect(kanal.saklanan, 0);
    });

    test('temizle Android\'de de çalışır', () async {
      kanal.saklanan = 7;

      await AppBadgeService.temizle();

      expect(kanal.yazilanRozetler, [0]);
    });

    test('artir sayacı sürdürür, rozet bildirimi üretmez', () async {
      kanal.saklanan = 4;

      final sonuc = await AppBadgeService.artir();

      // Dönen değer yerel bildirimin `number` alanına gidiyor; rozet oradan
      // beslendiği için plugin çağrısına gerek yok.
      expect(sonuc, 5);
      expect(kanal.saklanan, 5);
      expect(kanal.yazilanRozetler, isEmpty);
    });
  });
}
