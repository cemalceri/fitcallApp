// App Check token'ı: istekleri yavaşlatmadan her API çağrısına eklenir.
// Önbellek token ömrü (exp - iat) boyunca tutulur, eşzamanlı istekler tek
// alma işlemini bekler, hata sonrası 1 dk denenmez, token hiç alınamazsa
// istek başlıksız gider (sunucu "log" modunda geçirir).

import 'dart:async';
import 'dart:convert';

import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/core/app_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt({required int iat, required int exp}) {
  String parca(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${parca({'alg': 'RS256'})}.${parca({'iat': iat, 'exp': exp})}.imza';
}

void main() {
  late DateTime an;
  late int cagri;

  setUp(() {
    AppCheckServisi.sifirla();
    an = DateTime(2026, 10, 28, 12);
    cagri = 0;
    AppCheckServisi.simdi = () => an;
    AppCheckServisi.beklemeSuresi = const Duration(milliseconds: 50);
  });

  tearDown(() {
    ApiClient.istemciBasliklari = const {};
    ApiClient.appCheckTokeni = null;
  });

  group('AppCheckServisi.token', () {
    test('token ömrü boyunca önbellekten, bitmesine 5 dk kala yeniden', () async {
      final t = _jwt(iat: 1000, exp: 1000 + 3600);
      AppCheckServisi.tokenAl = () async {
        cagri++;
        return t;
      };

      expect(await AppCheckServisi.token(), t);
      an = an.add(const Duration(minutes: 54));
      expect(await AppCheckServisi.token(), t);
      expect(cagri, 1);

      an = an.add(const Duration(minutes: 2));
      await AppCheckServisi.token();
      expect(cagri, 2);
    });

    test('eşzamanlı istekler tek alma işlemini bekler', () async {
      final tamam = Completer<String?>();
      AppCheckServisi.tokenAl = () {
        cagri++;
        return tamam.future;
      };
      final bekleyenler = [for (var i = 0; i < 6; i++) AppCheckServisi.token()];
      tamam.complete(_jwt(iat: 0, exp: 3600));

      expect((await Future.wait(bekleyenler)).toSet().length, 1);
      expect(cagri, 1);
    });

    test('hata sonrası 1 dk denenmez, istek başlıksız gider', () async {
      AppCheckServisi.tokenAl = () async {
        cagri++;
        throw Exception('Play Integrity yok');
      };

      expect(await AppCheckServisi.token(), isNull);
      expect(await AppCheckServisi.token(), isNull);
      expect(cagri, 1);

      an = an.add(const Duration(minutes: 1, seconds: 1));
      await AppCheckServisi.token();
      expect(cagri, 2);
    });

    test('yavaş alma isteği bekletmez, token gelince önbelleğe girer', () async {
      final tamam = Completer<String?>();
      AppCheckServisi.tokenAl = () => tamam.future;

      expect(await AppCheckServisi.token(), isNull);

      final t = _jwt(iat: 0, exp: 3600);
      tamam.complete(t);
      await pumpEventQueue();
      expect(await AppCheckServisi.token(), t);
    });
  });

  test('ömür sunucu saatinden (exp - iat); okunamazsa 15 dk', () {
    expect(AppCheckServisi.omur(_jwt(iat: 500, exp: 500 + 1800)),
        const Duration(minutes: 30));
    expect(AppCheckServisi.omur('bozuk'), const Duration(minutes: 15));
  });

  group('ApiClient.ortakBasliklar', () {
    test('istemci başlıkları ve App Check token', () async {
      ApiClient.istemciBasliklari = {
        'X-Platform': 'android',
        'X-Uygulama-Surumu': '3.14.0',
      };
      ApiClient.appCheckTokeni = () async => 'tkn';

      expect(await ApiClient.ortakBasliklar(), {
        'X-Platform': 'android',
        'X-Uygulama-Surumu': '3.14.0',
        'X-Firebase-AppCheck': 'tkn',
      });
    });

    test('token yoksa ya da hata verirse başlık konmaz', () async {
      ApiClient.appCheckTokeni = () async => null;
      expect(await ApiClient.ortakBasliklar(), isEmpty);

      ApiClient.appCheckTokeni = () async => throw Exception('kanal');
      expect(await ApiClient.ortakBasliklar(), isEmpty);

      ApiClient.appCheckTokeni = null;
      expect(await ApiClient.ortakBasliklar(), isEmpty);
    });
  });
}
