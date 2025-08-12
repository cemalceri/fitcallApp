// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'api_result.dart';

class ApiClient {
  static const _defaultTimeout = Duration(seconds: 15);

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
      final res = await http
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
      final res = await http
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

    final decoded = jsonDecode(text);
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
    try {
      if (text.isNotEmpty) {
        final j = jsonDecode(text);
        final code = (j is Map && j['code'] is String)
            ? j['code'] as String
            : 'HTTP_ERROR';

        // Öncelikle backend'den gelen 'message' veya 'detail'
        final msg = (j is Map &&
                j['message'] is String &&
                j['message']!.trim().isNotEmpty)
            ? j['message'] as String
            : (j is Map &&
                    j['detail'] is String &&
                    j['detail']!.trim().isNotEmpty)
                ? j['detail'] as String
                : 'İşlem başarısız.';

        throw ApiException(code, msg, statusCode: status);
      } else {
        throw ApiException('HTTP_ERROR', 'İşlem başarısız.',
            statusCode: status);
      }
    } catch (_) {
      // JSON parse patlarsa bile backend text varsa onu göster
      final fallbackMsg = text.isNotEmpty ? text : 'İşlem başarısız.';
      throw ApiException('HTTP_ERROR', fallbackMsg, statusCode: status);
    }
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
      final res = await http
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
      final res = await http
          .get(Uri.parse(url), headers: effHeaders)
          .timeout(timeout ?? _defaultTimeout);
      final status = res.statusCode;
      final text = utf8.decode(res.bodyBytes);
      if (status >= 200 && status < 300) {
        return _okResult<T>(text, parser);
      }
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
