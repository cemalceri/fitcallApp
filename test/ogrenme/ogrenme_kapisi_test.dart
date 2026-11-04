// Rehber açıkken yazma isteği ağa çıkmaz; okuma ve altyapı geçer.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ogrenme/ogrenme_kapisi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _engel =
    throwsA(isA<ApiException>().having((e) => e.code, 'code', 'OGRENME_MODU'));

void main() {
  tearDown(() {
    OgrenmeKapisi.acik = false;
    OgrenmeKapisi.engellenenler.clear();
  });

  test('kapı kapalıyken her istek geçer', () {
    expect(() => OgrenmeKapisi.denetle(setDersTeyit), returnsNormally);
  });

  test('açıkken okuma ve altyapı geçer, yazma ve bilinmeyen uç durur', () {
    OgrenmeKapisi.acik = true;
    expect(() => OgrenmeKapisi.denetle(getTeyitDetay), returnsNormally);
    expect(() => OgrenmeKapisi.denetle('$baseUrl/mobilLogKaydet'),
        returnsNormally);
    expect(() => OgrenmeKapisi.denetle(setDersTeyit), _engel);
    expect(() => OgrenmeKapisi.denetle('$baseUrl/yepyeniUc'), _engel);
    expect(OgrenmeKapisi.engellenenler, ['setDersTeyit', 'yepyeniUc']);
  });

  test('dosya yüklemesi uç adına bakılmadan durur', () {
    OgrenmeKapisi.acik = true;
    expect(() => OgrenmeKapisi.denetle(getTeyitDetay, dosya: true), _engel);
  });

  test('ApiClient yazma isteğini ağa çıkarmaz, okumayı çıkarır', () async {
    final gidenler = <String>[];
    final istemci = MockClient((istek) async {
      gidenler.add(istek.url.path);
      return http.Response('{"data": null}', 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    OgrenmeKapisi.acik = true;
    await http.runWithClient(() async {
      await expectLater(
        ApiClient.postParsed<Object?>(setDersTeyit, {'x': 1}, (j) => j),
        _engel,
      );
      await expectLater(ApiClient.postJson(setDersTeyit, {'x': 1}), _engel);
      await ApiClient.postParsed<Object?>(getTeyitDetay, {}, (j) => j,
          auth: false);
    }, () => istemci);
    expect(gidenler, hasLength(1));
    expect(gidenler.single, contains('getTeyitDetay'));
  });
}
