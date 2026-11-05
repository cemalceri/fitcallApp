import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/ders_katilim_data.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/katilim_model.dart';
import 'package:fitcall/models/5_etkinlik/misafir_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class TakvimService {
  // ==================== HAFTALIK TAKVİM ====================
  static Future<ApiResult<WeekTakvimDataDto>> getUyeDersProramiApi({
    required DateTime start,
    required DateTime end,
  }) async {
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getUyeDersProgramiUrl,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    final dto = WeekTakvimDataDto(
      dersler: dersRes.data ?? [],
    );

    final mesaj = dersRes.mesaj.isNotEmpty ? dersRes.mesaj : '';
    return ApiResult<WeekTakvimDataDto>(mesaj: mesaj, data: dto);
  }

  // ==================== DERS ONAY ====================

  /// Ders onay bilgisini getirir
  ///
  /// Yeni kullanım (önerilen):
  /// - Üye için: `rol: 'uye'`, `uyeId: üyeninId`
  /// - Antrenör için: `rol: 'antrenor'`, `antrenorId: antrenörünId`
  ///
  /// Eski kullanım (deprecated): sadece `userId`
  static Future<ApiResult<Map<String, dynamic>>> getDersOnayBilgisi({
    required int dersId,
    required int userId,
    int? uyeId,
    int? antrenorId,
    String? rol,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersOnayBilgisiUrl,
      {
        'ders_id': dersId,
        'user_id': userId,
        if (uyeId != null) 'uye_id': uyeId,
        if (antrenorId != null) 'antrenor_id': antrenorId,
        if (rol != null) 'rol': rol,
      },
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Ders onay bilgisini kaydeder
  ///
  /// [uyeId] - Üye rolünde onay için zorunlu, aynı üyenin tüm kullanıcıları
  /// için tek onay kaydı tutulmasını sağlar.
  static Future<ApiResult<Map<String, dynamic>>> setDersOnayBilgisi({
    required int dersId,
    required int userId,
    required String rol,
    required bool tamamlandi,
    int? uyeId,
    String? aciklama,
    String? onayRedIptalNedeni,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'rol': rol,
      'tamamlandi': tamamlandi,
      if (uyeId != null) 'uye_id': uyeId,
      if (aciklama != null && aciklama.isNotEmpty) 'aciklama': aciklama,
      if (onayRedIptalNedeni != null)
        'onay_red_iptal_nedeni': onayRedIptalNedeni,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersOnayBilgisiUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
  // ==================== DEĞERLENDİRME ====================

  static Future<ApiResult<Map<String, dynamic>>> getDersDegerlendirme({
    required int dersId,
    required int userId,
    String? rol,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      if (rol != null) 'rol': rol,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersDegerlendirmeUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  static Future<ApiResult<Map<String, dynamic>>> setDersDegerlendirme({
    required int dersId,
    required int userId,
    required String rol,
    required int puan,
    String? yorum,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'rol': rol,
      'puan': puan,
      if (yorum != null && yorum.isNotEmpty) 'yorum': yorum,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersDegerlendirmeUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  static Future<ApiResult<Map<String, dynamic>>> getDersTumDegerlendirmeler({
    required int dersId,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersTumDegerlendirmelerUrl,
      {'ders_id': dersId},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  // ==================== ANTRENÖR ====================

  static Future<ApiResult<List<EtkinlikModel>>>
      getirAntrenorHaftalikDersBilgileri() {
    return ApiClient.postParsed<List<EtkinlikModel>>(
      getAntrenorHaftalikEtkinlikler,
      const {},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );
  }

  // ==================== KATILIM ====================

  /// Bir dersin katılım durumunu getirir
  static Future<ApiResult<DersKatilimDto>> getDersKatilimlari({
    required int dersId,
  }) {
    return ApiClient.postParsed<DersKatilimDto>(
      getDersKatilimlariUrl,
      {'ders_id': dersId},
      (json) => DersKatilimDto.fromMap((json as Map).cast<String, dynamic>()),
    );
  }

  /// Antrenör onayı + tüm katılım kayıtlarını atomic kaydeder
  static Future<ApiResult<Map<String, dynamic>>> setDersKatilimi({
    required int dersId,
    required int userId,
    required bool tamamlandi,
    required List<KatilimModel> katilimlar,
    List<MisafirModel> misafirler = const [],
    String? aciklama,
    String? onayRedIptalNedeni,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'tamamlandi': tamamlandi,
      if (aciklama != null && aciklama.isNotEmpty) 'aciklama': aciklama,
      if (onayRedIptalNedeni != null)
        'onay_red_iptal_nedeni': onayRedIptalNedeni,
      'katilimlar': katilimlar.map((k) => k.toRequestMap()).toList(),
      'misafirler': misafirler.map((m) => m.toRequestMap()).toList(),
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersKatilimiUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
