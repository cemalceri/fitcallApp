// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_exception.dart';
import 'api_result.dart';

class ApiClient {
  static const _defaultTimeout = Duration(seconds: 20);

  /// Tüm istekler için tek paylaşılan client.
  ///
  /// `http.get`/`http.post` gibi üst düzey fonksiyonlar her çağrıda yeni bir
  /// [http.Client] açıp kapatır; bu da her istekte yeniden TCP + TLS el sıkışması
  /// demektir. Ana sayfa açılışta 6 istek attığı için bu maliyet katlanıyordu.
  /// Tek client ile keep-alive devreye girer, bağlantı yeniden kullanılır.
  /// Uygulama ömrü boyunca yaşadığı için kapatılmaz.
  static final http.Client _client = http.Client();

  /// Token'lı bir istek oturum hatası aldığında çağrılır (main.dart bağlar);
  /// parametre o istekte gönderilen token (yoksa null).
  ///
  /// Sunucu token'ı süre dolmadan da reddedebiliyor: parola değişince, hesap
  /// kapanınca ya da imza anahtarı yenilenince. Eskiden kullanıcı süre
  /// dolana kadar her ekranda hata görüyordu; artık girişe yönlendirilir.
  static void Function(String? reddedilenToken)? oturumDustu;

  /// Yalnız bu kodlar oturumu düşürür: QR doğrulama gibi uçlar geçersiz kod
  /// için de 401 dönüyor, onlar kullanıcıyı oturumdan atmamalı.
  static const _oturumHataKodlari = {'AUTH_ERROR', 'AUTH_REQUIRED'};

  static void _yetkiHatasiniBildir(
      int status, String text, bool auth, String? gonderilenToken) {
    if (!auth || status != 401) return;
    final (code, _) = hataGovdesiniCoz(status, text);
    if (_oturumHataKodlari.contains(code)) oturumDustu?.call(gonderilenToken);
  }

  static String? _gonderilenToken(Map<String, String> basliklar) {
    final deger = basliklar['Authorization'];
    return deger != null && deger.startsWith('Bearer ')
        ? deger.substring(7)
        : null;
  }

  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
    bool auth = false,
  }) async {
    final base = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await StorageService.getToken();
      if (token != null) {
        base['Authorization'] = 'Bearer $token';
      }
      if (headers != null) {
        base.addAll(headers);
      }
    }
    return base;
  }

  /* ---------------- Low-level JSON (varsa eski çağrılar için) ---------------- */
  static Future<dynamic> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (headers != null) ...headers,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout ?? _defaultTimeout);

      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status >= 200 && status < 300) {
        if (text.isEmpty) return null;
        return jsonDecode(text);
      }

      // Hata: backend mesajını ÖNCE göster
      try {
        final j = text.isNotEmpty ? jsonDecode(text) : {};
        final code = (j is Map && j['code'] is String)
            ? j['code'] as String
            : 'HTTP_ERROR';
        final msg = (j is Map && j['message'] is String)
            ? j['message'] as String
            : (j is Map && j['detail'] is String)
                ? j['detail'] as String
                : 'İşlem başarısız.';
        throw ApiException(code, msg, statusCode: status);
      } catch (_) {
        throw ApiException('HTTP_ERROR', 'İşlem başarısız.',
            statusCode: status);
      }
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('UNKNOWN', 'Beklenmeyen bir hata: $e');
    }
  }

  static Future<dynamic> getJson(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final res = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(timeout ?? _defaultTimeout);
      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status >= 200 && status < 300) {
        if (text.isEmpty) return null;
        return jsonDecode(text);
      }
      try {
        final j = text.isNotEmpty ? jsonDecode(text) : {};
        final code = (j is Map && j['code'] is String)
            ? j['code'] as String
            : 'HTTP_ERROR';
        final msg = (j is Map && j['message'] is String)
            ? j['message'] as String
            : (j is Map && j['detail'] is String)
                ? j['detail'] as String
                : 'İşlem başarısız.';
        throw ApiException(code, msg, statusCode: status);
      } catch (_) {
        throw ApiException('HTTP_ERROR', 'İşlem başarısız.',
            statusCode: status);
      }
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('UNKNOWN', 'Beklenmeyen bir hata: $e');
    }
  }

  /* ---------------- High-level Generic (ÖNERİLEN) ---------------- */

  static (String, dynamic) _extractMsgAndData(dynamic j) {
    // j: backend JSON’u (map veya başka)
    String mesaj = 'İşlem başarılı';
    dynamic data = j;

    if (j is Map) {
      if (j['message'] is String) {
        mesaj = j['message'] as String;
      } else if (j['detail'] is String) {
        mesaj = j['detail'] as String;
      }
      if (j.containsKey('data')) data = j['data'];
    }
    return (mesaj, data);
  }

  static dynamic _normalizeJson(dynamic dataJson) {
    if (dataJson is Map) {
      return Map<String, dynamic>.from(dataJson);
    }
    if (dataJson is List) {
      return dataJson
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : e)
          .toList();
    }
    return dataJson; // primitive / null
  }

  static ApiResult<T> _okResult<T>(String text, FromJsonAny<T> parser) {
    if (text.isEmpty) {
      return ApiResult<T>(mesaj: 'Boş yanıt döndü', data: null);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      // 200 ama JSON değil (ör. ağın giriş sayfası araya girdi).
      throw ApiException(
          'PARSE_ERROR', 'Sunucudan beklenmeyen bir yanıt geldi.');
    }
    final (mesaj, dataJson) = _extractMsgAndData(decoded);
    final safeData = _normalizeJson(dataJson);

    T? parsed;
    try {
      parsed = (safeData == null) ? null : parser(safeData);
    } catch (e) {
      // Parser tarafında tip uyuşmazlığı olursa buraya düşer
      throw ApiException(
          'PARSE_ERROR', 'Veri çözümleme sırasında hata oluştu: $e');
    }

    return ApiResult<T>(mesaj: mesaj, data: parsed);
  }

  static Never _throwWithBody(int status, String text) {
    final (code, msg) = hataGovdesiniCoz(status, text);
    throw ApiException(code, msg, statusCode: status);
  }

  /// Hata yanıtının gövdesinden (kod, mesaj) çıkarır.
  ///
  /// DİKKAT: throw eskiden ayrıştırmanın try bloğunun İÇİNDEYDİ; backend'in
  /// 'code' alanı daima 'HTTP_ERROR' ile eziliyordu (ör. ders_teyit_page'deki
  /// TEYIT_DEGISTIRME_YASAK kontrolü hiç eşleşemiyordu).
  /// Mesaj sırası: message → detail → kısa düz metin gövde → duruma göre
  /// genel mesaj. HTML ya da uzun gövde (Heroku/nginx hata sayfası, 413
  /// "Request Entity Too Large") kullanıcıya gösterilmez.
  @visibleForTesting
  static (String, String) hataGovdesiniCoz(int status, String text) {
    String code = 'HTTP_ERROR';
    String? msg;
    final duz = text.trim();
    if (duz.isNotEmpty) {
      try {
        final j = jsonDecode(duz);
        if (j is Map) {
          if (j['code'] is String) code = j['code'] as String;
          if (j['message'] is String &&
              (j['message'] as String).trim().isNotEmpty) {
            msg = j['message'] as String;
          } else if (j['detail'] is String &&
              (j['detail'] as String).trim().isNotEmpty) {
            msg = j['detail'] as String;
          }
        }
      } on FormatException {
        if (!duz.startsWith('<') && duz.length <= 200) msg = duz;
      }
    }
    return (code, msg ?? _genelHataMesaji(status));
  }

  static String _genelHataMesaji(int status) {
    if (status == 413) return 'Dosya çok büyük.';
    if (status == 401 || status == 403) {
      return 'Bu işlem için yetkiniz yok ya da oturumun süresi doldu.';
    }
    if (status == 404) return 'İstenen kayıt bulunamadı.';
    if (status >= 500) {
      return 'Sunucuda bir sorun oluştu. Biraz sonra tekrar deneyin.';
    }
    return 'İşlem başarısız.';
  }

  static Future<ApiResult<T>> postParsed<T>(
    String url,
    Map<String, dynamic> body,
    FromJsonAny<T> parser, {
    Map<String, String>? headers,
    Duration? timeout,
    bool auth = true,
  }) async {
    try {
      final effHeaders = await _buildHeaders(headers: headers, auth: auth);
      final res = await _client
          .post(
            Uri.parse(url),
            headers: effHeaders,
            body: jsonEncode(body),
          )
          .timeout(timeout ?? _defaultTimeout);

      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status == 200) {
        return _okResult<T>(text, parser);
      }
      _yetkiHatasiniBildir(status, text, auth, _gonderilenToken(effHeaders));
      _throwWithBody(status, text);
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('UNKNOWN', 'Beklenmeyen bir hata: $e');
    }
  }

  /// Dosya yükleme (multipart/form-data). [dosyaAlani] sunucudaki alan adı;
  /// [alanlar] ek düz metin alanları. Yanıt [postParsed] ile aynı biçimde
  /// çözülür. Fotoğraf yüklemesi yavaş bağlantıda 20 sn'yi aşabildiği için
  /// varsayılan süre daha uzun; süre gönderme + yanıtı okumanın toplamıdır.
  static Future<ApiResult<T>> postDosyaParsed<T>(
    String url, {
    required String dosyaAlani,
    required List<int> baytlar,
    required String dosyaAdi,
    String dosyaTuru = 'application/octet-stream',
    Map<String, String> alanlar = const {},
    required FromJsonAny<T> parser,
    Duration timeout = const Duration(seconds: 60),
    bool auth = true,
  }) async {
    String? gonderilenToken;
    Future<http.Response> gonder() async {
      final istek = http.MultipartRequest('POST', Uri.parse(url));
      // Content-Type'ı MultipartRequest sınır (boundary) ile kendisi koyar;
      // _buildHeaders'ın JSON başlığı burada kullanılmaz.
      if (auth) {
        gonderilenToken = await StorageService.getToken();
        if (gonderilenToken != null) {
          istek.headers['Authorization'] = 'Bearer $gonderilenToken';
        }
      }
      istek.fields.addAll(alanlar);
      istek.files.add(http.MultipartFile.fromBytes(
        dosyaAlani,
        baytlar,
        filename: dosyaAdi,
        contentType: MediaType.parse(dosyaTuru),
      ));

      return http.Response.fromStream(await _client.send(istek));
    }

    try {
      final res = await gonder().timeout(timeout);
      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status == 200) {
        return _okResult<T>(text, parser);
      }
      _yetkiHatasiniBildir(status, text, auth, gonderilenToken);
      _throwWithBody(status, text);
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('UNKNOWN', 'Beklenmeyen bir hata: $e');
    }
  }

  static Future<ApiResult<T>> getParsed<T>(
    String url,
    FromJsonAny<T> parser, {
    Map<String, String>? headers,
    Duration? timeout,
    bool auth = false,
  }) async {
    try {
      final effHeaders = await _buildHeaders(headers: headers, auth: auth);
      final res = await _client
          .get(Uri.parse(url), headers: effHeaders)
          .timeout(timeout ?? _defaultTimeout);
      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status >= 200 && status < 300) {
        return _okResult<T>(text, parser);
      }
      _yetkiHatasiniBildir(status, text, auth, _gonderilenToken(effHeaders));
      _throwWithBody(status, text);
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Sunucuya şu an ulaşılamıyor.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('UNKNOWN', 'Beklenmeyen bir hata: $e');
    }
  }
}
