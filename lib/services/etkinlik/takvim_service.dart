import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/ders_katilim_data.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/katilim_model.dart';
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

  // ==================== İPTAL TALEBİ ====================

  static Future<ApiResult<Map<String, dynamic>>> createIptalTalebi({
    required int dersId,
    required int userId,
    required String rol,
    required String sebep,
    int? uyeId,
    String? aciklama,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'rol': rol,
      'sebep': sebep,
      if (uyeId != null) 'uye_id': uyeId,
      if (aciklama != null && aciklama.isNotEmpty) 'aciklama': aciklama,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      createIptalTalebiUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  static Future<ApiResult<List<Map<String, dynamic>>>>
      getKullaniciIptalTalepleri({
    required int userId,
  }) async {
    final r = await ApiClient.postParsed<List<dynamic>>(
      getKullaniciIptalTalepleriUrl,
      {'user_id': userId},
      (json) => (json as List),
    );
    final list =
        (r.data ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    return ApiResult<List<Map<String, dynamic>>>(mesaj: r.mesaj, data: list);
  }

  // ==================== YENİ: DERS İÇİN İPTAL TALEBİ SORGULA ====================

  /// Belirli bir ders için kullanıcının bekleyen iptal talebini sorgular
  static Future<ApiResult<Map<String, dynamic>>> getDersIptalTalebi({
    required int dersId,
    required int userId,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersIptalTalebiUrl,
      {'ders_id': dersId, 'user_id': userId},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  // ==================== YENİ: İPTAL TALEBİ GERİ ÇEK ====================

  /// Bekleyen iptal talebini geri çeker (siler)
  static Future<ApiResult<Map<String, dynamic>>> iptalTalebiGeriCek({
    required int talepId,
    required int userId,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      iptalTalebiGeriCekUrl,
      {'talep_id': talepId, 'user_id': userId},
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

  static Future<ApiResult<Map<String, dynamic>>> antrenorDersYapildiBilgisi({
    required int dersId,
    required bool tamamlandi,
    required String aciklama,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersOnayBilgisiUrl,
      {'ders_id': dersId, 'aciklama': aciklama, 'tamamlandi': tamamlandi},
      (json) => (json as Map).cast<String, dynamic>(),
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
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersKatilimiUrl,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
