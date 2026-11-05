import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Dart'ın varsayılanı boşta bağlantıyı 15 sn'de kapatır; formu doldururken
/// ya da ekranda biraz durunca sonraki istek yeniden TCP + TLS öder
/// (Türkiye → sunucu ~285 ms). Heroku router boşta bağlantıyı daha geç
/// kapattığı için 50 sn güvenli.
const bostaKalmaSuresi = Duration(seconds: 50);

/// `http.Client()` önce denenir: testlerin `http.runWithClient` ile verdiği
/// sahte istemci korunur; yalnız varsayılan istemci ayarlı olanla değişir.
http.Client paylasilanIstemciOlustur() {
  final varsayilan = http.Client();
  if (varsayilan is! IOClient) return varsayilan;
  varsayilan.close();
  return IOClient(HttpClient()..idleTimeout = bostaKalmaSuresi);
}
