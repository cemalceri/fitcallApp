import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/mesgul_slot_dto.dart';
import 'package:fitcall/models/dtos/takvim_dtos/uygun_slot_dto.dart';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class TakvimService {
  /// Haftalık takvim verileri: dersler + uygun/meşgul slotlar
  static Future<ApiResult<WeekTakvimDataDto>> loadWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    // 1) Dersler
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getUyeDersProgrami,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    // 2) Uygun / meşgul slotlar
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

  /// Belirli tarih aralığında belirtilen ya da tüm antrenörlerin uygun saatleri döner
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

  /// Üyenin gelecekteki dersi iptal etmesi
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

  /// Geçmiş ders için tamamlama bilgisi
  static Future<ApiResult<Map<String, dynamic>>> getDersYapildiBilgisiApi({
    required int dersId,
    required int userId,
  }) {
    final body = {'ders_id': dersId, 'user_id': userId};
    return ApiClient.postParsed<Map<String, dynamic>>(
      getDersYapildiBilgisi,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// (POST) Kaydet: ders_id + user_id + rol + tamamlandi + aciklama [+ onay_red_iptal_nedeni]
  static Future<ApiResult<Map<String, dynamic>>> setDersYapildiBilgisiApi({
    required int dersId,
    required int userId,
    required String rol, // "UYE" | "ANTRENOR" | "YONETICI"
    required bool tamamlandi,
    required String aciklama,
    String?
        onayRedIptalNedeni, // enum code: "YPL_PLAN", "YMD_OGRENCI", "IPT_PROG", ...
  }) {
    final body = {
      'ders_id': dersId,
      'user_id': userId,
      'rol': rol,
      'tamamlandi': tamamlandi,
      'aciklama': aciklama,
      if (onayRedIptalNedeni != null)
        'onay_red_iptal_nedeni': onayRedIptalNedeni,
    };
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersYapildiBilgisi,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

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
    // 1) Dersler
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getAntrenorGunlukEtkinlikler,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    // 2) Uygun / meşgul slotlar
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

  /// Geçmiş ders için tamamlama bilgisi
  static Future<ApiResult<Map<String, dynamic>>> antrenorDersYapildiBilgisi({
    required int dersId,
    required bool tamamlandi,
    required String aciklama,
  }) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersYapildiBilgisi,
      {'ders_id': dersId, 'aciklama': aciklama, 'tamamlandi': tamamlandi},
      (json) => (json as Map).cast<String, dynamic>(),
    );
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
}
