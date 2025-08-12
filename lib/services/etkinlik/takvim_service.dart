import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/mesgul_slot_dto.dart';
import 'package:fitcall/models/dtos/uygun_slot_dto.dart';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
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
      getDersProgrami,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
      (json) => ApiParsing.parseList<EtkinlikModel>(
        json,
        (m) => EtkinlikModel.fromMap(m),
      ),
    );

    // 2) Uygun / meşgul slotlar
    final slotRes = await ApiClient.postParsed<Map<String, dynamic>>(
      getUygunSaatler,
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

  /// Belirli tarih aralığında uygun saatleri döner
  static Future<ApiResult<List<UygunSlotDto>>> getUygunSaatlerAralik({
    required DateTime start,
    required DateTime end,
  }) async {
    final r = await ApiClient.postParsed<Map<String, dynamic>>(
      getUygunSaatler,
      {'start': start.toIso8601String(), 'end': end.toIso8601String()},
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
  static Future<ApiResult<Map<String, dynamic>>> dersYapildiBilgisi({
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
}
