import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/models/1_common/event/gecis_model.dart';
import 'package:fitcall/models/1_common/qr_kod_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class QrCodeApiService {
  // ---------- Ortak yardımcı ----------

  static List<GecisModel> _parseGecisList(dynamic json) {
    if (json is List) {
      return json
          .map((e) => GecisModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (json is Map<String, dynamic>) {
      final dynamic raw =
          json['results'] ?? json['items'] ?? json['data'] ?? [];
      if (raw is List) {
        return raw
            .map((e) => GecisModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return <GecisModel>[];
  }

  // ---------- EVENT ----------

  /// Aktif event’i getirir. (userId opsiyoneldir; backend vermeseniz de çalışır)
  static Future<ApiResult<EventModel?>> getirEventAktifApi({int? userId}) {
    final body = userId == null ? <String, dynamic>{} : {'user_id': userId};
    return ApiClient.postParsed<EventModel?>(
      getirEventAktif,
      body,
      (json) => json == null
          ? null
          : EventModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<GecisModel?>> getirEventSelfPassApi({
    required int userId,
  }) {
    return ApiClient.postParsed<GecisModel?>(
      getirEventSelfPass,
      {'user_id': userId},
      (json) => json == null
          ? null
          : GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<List<GecisModel>>> listeleEventMisafirPassApi({
    required int userId,
  }) {
    return ApiClient.postParsed<List<GecisModel>>(
      listeleEventMisafirPass,
      {'user_id': userId},
      _parseGecisList,
    );
  }

  static Future<ApiResult<GecisModel>> olusturEventMisafirPassApi({
    required int userId,
    required String label,
    String? telefon,
  }) {
    return ApiClient.postParsed<GecisModel>(
      olusturEventMisafirPass,
      {
        'user_id': userId,
        'label': label,
        if (telefon != null && telefon.isNotEmpty) 'telefon': telefon,
      },
      (json) => GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  static Future<ApiResult<bool>> silEventMisafirPassApi({
    required String code,
  }) {
    return ApiClient.postParsed<bool>(
      silEventMisafirPass,
      {'code': code},
      (json) => (json is bool) ? json : false,
    );
  }

  // ---------- TESİS (Günlük giriş) ----------

  /// Kullanıcının TESİS self-pass’ını getirir/uzatır (minutes kadar).
  static Future<ApiResult<GecisModel>> kullaniciIcinQROlustursApi({
    required int userId,
  }) {
    return ApiClient.postParsed<GecisModel>(
      getirTesisSelfPass,
      {'user_id': userId},
      (json) => GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  /// Aktif TESİS misafir pass listesini döner (sadece expires_at >= now).
  static Future<ApiResult<List<GecisModel>>> listeleTesisMisafirPassApi({
    required int userId,
  }) {
    return ApiClient.postParsed<List<GecisModel>>(
      listeleTesisMisafirPass,
      {'user_id': userId},
      _parseGecisList,
    );
  }

  /// TESİS misafir pass oluşturur (label set edilir; minutes kadar geçerli).
  static Future<ApiResult<GecisModel>> olusturTesisMisafirPassApi({
    required int userId,
    required String label,
    required int minutes,
  }) {
    return ApiClient.postParsed<GecisModel>(
      olusturTesisMisafirPass,
      {'user_id': userId, 'label': label, 'minutes': minutes},
      (json) => GecisModel.fromJson(Map<String, dynamic>.from(json)),
    );
  }

  /// TESİS misafir pass siler (iptal eder).
  static Future<ApiResult<bool>> silTesisMisafirPassApi({
    required int userId,
    required String code,
  }) {
    return ApiClient.postParsed<bool>(
      silTesisMisafirPass,
      {'user_id': userId, 'code': code},
      (json) => (json is bool) ? json : false,
    );
  }

  // ---------- QR Kod doğrulama (scanner/gate) ----------

  static Future<ApiResult<QrKodVerifyResponse>> qrKodDogrulaApi({
    required String kod,
  }) {
    return ApiClient.postParsed<QrKodVerifyResponse>(
      qrKodDogrula,
      {'kod': kod},
      (json) => QrKodVerifyResponse.fromAny(json, defaultSuccess: true),
    );
  }
}
