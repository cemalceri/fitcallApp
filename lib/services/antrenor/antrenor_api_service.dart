// lib/services/antrenor/antrenor_ogrenciler_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/uygun_slot_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class AntrenorApiService {
  static Future<ApiResult<List<UyeModel>>> getirOgrencilerim() {
    return ApiClient.postParsed<List<UyeModel>>(
      getAntrenorOgrenciler,
      const {},
      (json) => ApiParsing.parseList<UyeModel>(
        json,
        (m) => UyeModel.fromJson(m),
      ),
    );
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
}
