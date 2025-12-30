import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/mesgul_slot_dto.dart';
import 'package:fitcall/models/dtos/takvim_dtos/uygun_slot_dto.dart';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class TakvimService {
  // ==================== HAFTALIK TAKVİM ====================
  static Future<ApiResult<WeekTakvimDataDto>> loadWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getUyeDersProgrami,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    final slotRes = await ApiClient.postParsed<Map<String, dynamic>>(
      getAntrenorUygunSaatleri,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => (json as Map).cast<String, dynamic>(),
    );

    final busy = ((slotRes.data?['busy'] ?? []) as List)
        .map((e) => MesgulSlotDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final available = ((slotRes.data?['available'] ?? []) as List)
        .map((e) => UygunSlotDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final dto = WeekTakvimDataDto(
      dersler: dersRes.data ?? [],
      mesgul: busy,
      uygun: available,
    );

    final mesaj = dersRes.mesaj.isNotEmpty ? dersRes.mesaj : slotRes.mesaj;
    return ApiResult<WeekTakvimDataDto>(mesaj: mesaj, data: dto);
  }

  static Future<ApiResult<List<UygunSlotDto>>> getAntrenorUygunSaatleriApi({
    required DateTime start,
    required DateTime end,
    int? antrenorId,
  }) async {
    final body = {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      if (antrenorId != null) 'antrenor_id': antrenorId,
    };

    final r = await ApiClient.postParsed<Map<String, dynamic>>(
      getAntrenorUygunSaatleri,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );

    final list = (r.data?['available'] ?? []) as List;
    final parsed = list
        .map((e) => UygunSlotDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return ApiResult<List<UygunSlotDto>>(mesaj: r.mesaj, data: parsed);
  }

  static Future<ApiResult<Map<String, dynamic>>> uyeDersIptal({
    required int etkinlikId,
    String? aciklama,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setUyeDersIptal,
      {'etkinlik_id': etkinlikId, 'aciklama': aciklama ?? ''},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  // ==================== DERS ONAY ====================
  static Future<ApiResult<Map<String, dynamic>>> getDersOnayBilgisi({
    required int dersId,
    required int userId,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersOnayBilgisiUrl,
      {'ders_id': dersId, 'user_id': userId},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  static Future<ApiResult<Map<String, dynamic>>> setDersOnayBilgisi({
    required int dersId,
    required int userId,
    required String rol,
    required bool tamamlandi,
    String? aciklama,
    String? onayRedIptalNedeni,
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'rol': rol,
      'tamamlandi': tamamlandi,
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

  static Future<ApiResult<List<Map<String, dynamic>>>> getIptalTalepleri({
    String? durum,
    int? dersId,
  }) async {
    final body = <String, dynamic>{};
    if (durum != null) body['durum'] = durum;
    if (dersId != null) body['ders_id'] = dersId;

    final r = await ApiClient.postParsed<List<dynamic>>(
      getIptalTalepleriUrl,
      body,
      (json) => (json as List),
    );
    final list =
        (r.data ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    return ApiResult<List<Map<String, dynamic>>>(mesaj: r.mesaj, data: list);
  }

  static Future<ApiResult<Map<String, dynamic>>> setIptalTalebiIslem({
    required int talepId,
    required int userId,
    required String islem,
    String? aciklama,
  }) {
    final body = {
      'talep_id': talepId,
      'user_id': userId,
      'islem': islem,
      if (aciklama != null && aciklama.isNotEmpty) 'aciklama': aciklama,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setIptalTalebiIslemUrl,
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

  // ==================== ANTRENÖR ====================

  static Future<ApiResult<Map<String, dynamic>>> antrenorDersIptal({
    required int dersId,
    required String aciklama,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setAntrenorDersIptal,
      {'ders_id': dersId, 'aciklama': aciklama},
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  static Future<ApiResult<WeekTakvimDataDto>> antrenorLoadDay({
    required DateTime start,
    required DateTime end,
    int? antrenorId,
  }) async {
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getAntrenorGunlukEtkinlikler,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    final slotRes = await ApiClient.postParsed<Map<String, dynamic>>(
      getAntrenorUygunSaatleri,
      {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        if (antrenorId != null) 'antrenor_id': antrenorId
      },
      (json) => (json as Map).cast<String, dynamic>(),
    );

    final busy = ((slotRes.data?['busy'] ?? []) as List)
        .map((e) => MesgulSlotDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final available = ((slotRes.data?['available'] ?? []) as List)
        .map((e) => UygunSlotDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final dto = WeekTakvimDataDto(
      dersler: dersRes.data ?? [],
      mesgul: busy,
      uygun: available,
    );

    final mesaj = dersRes.mesaj.isNotEmpty ? dersRes.mesaj : slotRes.mesaj;
    return ApiResult<WeekTakvimDataDto>(mesaj: mesaj, data: dto);
  }

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

  // ==================== GERİYE UYUMLULUK ====================

  static Future<ApiResult<Map<String, dynamic>>> getDersYapildiBilgisiApi({
    required int dersId,
    required int userId,
  }) {
    return getDersOnayBilgisi(dersId: dersId, userId: userId);
  }

  static Future<ApiResult<Map<String, dynamic>>> setDersYapildiBilgisiApi({
    required int dersId,
    required int userId,
    required String rol,
    required bool tamamlandi,
    required String aciklama,
    String? onayRedIptalNedeni,
  }) {
    return setDersOnayBilgisi(
      dersId: dersId,
      userId: userId,
      rol: rol,
      tamamlandi: tamamlandi,
      aciklama: aciklama,
      onayRedIptalNedeni: onayRedIptalNedeni,
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
}
