// Sahte API: sayfaların gerçek servis çağrıları buraya düşer.
//
// Yanıtlar uç adına (URL'nin son parçası) göre sahneden okunur ve backend'in
// `{data: ...}` zarfıyla döner. Tanımsız uç 404 alır ve konsola yazılır; böylece
// bir sahnenin hangi verilere ihtiyaç duyduğu ilk çalıştırmada görünür.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'sahneler.dart';

class SahteApi {
  SahteApi._();

  static Sahne? senaryo;

  static final http.Client istemci = MockClient((istek) async {
    final parcalar = istek.url.pathSegments.where((p) => p.isNotEmpty).toList();
    final api = parcalar.indexOf('api');
    final uc = api >= 0 && api + 1 < parcalar.length
        ? parcalar[api + 1]
        : (parcalar.isEmpty ? '' : parcalar.last);
    Object? govde;
    if (istek.body.isNotEmpty) {
      try {
        govde = jsonDecode(istek.body);
      } on FormatException {
        govde = istek.body;
      }
    }
    final yanitci = senaryo?.api[uc] ?? ortakApi[uc];
    if (yanitci == null) {
      debugPrint('SAHTE API — tanımsız uç: ${istek.method} ${istek.url}');
      return http.Response(
        jsonEncode({'detail': 'Sahte API: $uc tanımsız'}),
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final veri = yanitci(istek.url, govde);
    return http.Response.bytes(
      utf8.encode(jsonEncode({'data': veri})),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}
