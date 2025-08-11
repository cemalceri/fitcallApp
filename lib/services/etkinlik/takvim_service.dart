import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/mesgul_slot_dto.dart';
import 'package:fitcall/models/dtos/uygun_slot_dto.dart';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/auth_service.dart';

class TakvimService {
  /// Haftalık takvim verileri: dersler + uygun/meşgul slotlar
  static Future<ApiResult<WeekTakvimDataDto>> loadWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw ApiException('TOKEN_ERROR', 'Oturum bulunamadı.');
    final headers = {'Authorization': 'Bearer $token'};

    // 1) Dersler
    final dersRes = await ApiClient.postParsed<List<EtkinlikModel>>(
      getDersProgrami,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => (json as List)
          .map((e) => EtkinlikModel.fromMap((e as Map).cast<String, dynamic>()))
          .toList(),
      headers: headers,
    );

    // 2) Uygun / meşgul
    final slotRes = await ApiClient.postParsed<Map<String, dynamic>>(
      getUygunSaatler,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => (json as Map).cast<String, dynamic>(),
      headers: headers,
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

    final mesaj = (dersRes.mesaj.isNotEmpty ? dersRes.mesaj : slotRes.mesaj);
    return ApiResult<WeekTakvimDataDto>(mesaj: mesaj, data: dto);
  }

  static Future<ApiResult<List<UygunSlotDto>>> getUygunSaatlerAralik({
    required DateTime start,
    required DateTime end,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw ApiException('TOKEN_ERROR', 'Oturum bulunamadı.');
    final headers = {'Authorization': 'Bearer $token'};

    final r = await ApiClient.postParsed<Map<String, dynamic>>(
      getUygunSaatler,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => (json as Map).cast<String, dynamic>(),
      headers: headers,
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
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw ApiException('TOKEN_ERROR', 'Oturum bulunamadı.');
    return ApiClient.postParsed<Map<String, dynamic>>(
      setUyeDersIptal,
      {'etkinlik_id': etkinlikId, 'aciklama': aciklama ?? ''},
      (json) => (json as Map).cast<String, dynamic>(),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Geçmiş ders için tamamlama bilgisi
  static Future<ApiResult<Map<String, dynamic>>> dersYapildiBilgisi({
    required int dersId,
    required bool tamamlandi,
    required String aciklama,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw ApiException('TOKEN_ERROR', 'Oturum bulunamadı.');
    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersYapildiBilgisi,
      {'ders_id': dersId, 'aciklama': aciklama, 'tamamlandi': tamamlandi},
      (json) => (json as Map).cast<String, dynamic>(),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
