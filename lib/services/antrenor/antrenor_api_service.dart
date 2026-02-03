// lib/services/antrenor/antrenor_ogrenciler_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
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

  static Future<ApiResult<AntrenorTakvimDataDto>> antrenorLoadDay({
    required DateTime start,
    int? antrenorId,
  }) async {
    final body = {
      'start': start.toIso8601String(),
      if (antrenorId != null) 'antrenor_id': antrenorId,
    };

    return await ApiClient.postParsed<AntrenorTakvimDataDto>(
      getAntrenorGunlukEtkinlikler,
      body,
      (json) {
        // Backend'den gelen response yapısını kontrol et
        // Eğer {data: [...], message: "..."} formatındaysa
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          final derslerList =
              (json['data'] as List).cast<Map<String, dynamic>>();
          return AntrenorTakvimDataDto.fromBackendList(derslerList);
        }

        // Direkt liste geliyorsa
        if (json is List) {
          final derslerList = json.cast<Map<String, dynamic>>();
          return AntrenorTakvimDataDto.fromBackendList(derslerList);
        }

        // Boş durumda
        return AntrenorTakvimDataDto(dersler: []);
      },
      auth: true,
    );
  }

// ==================== HOME CARDS ====================

  /// Antrenör ana sayfa bilgi kartlarını getirir
  static Future<ApiResult<List<HomeCardModel>>> getAntrenorHomeCards() async {
    return ApiClient.getParsed<List<HomeCardModel>>(
      getAntrenorHomeCardsUrl,
      (json) {
        if (json is List) {
          return json
              .map((e) => HomeCardModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <HomeCardModel>[];
      },
      auth: true,
    );
  }

  /// Bilgi kartını kapatır (dismiss)
  static Future<ApiResult<void>> dismissAntrenorHomeCard(int cardId) async {
    return ApiClient.postParsed<void>(
      dismissAntrenorHomeCardUrl,
      {'card_id': cardId},
      (_) {},
      auth: true,
    );
  }

  /// Antrenörün sonraki dersini getirir (30 gün içindeki ilk ders)
  static Future<ApiResult<EtkinlikModel?>> getAntrenorSonrakiDers() async {
    return ApiClient.getParsed<EtkinlikModel?>(
      getAntrenorSonrakiDersUrl,
      (json) {
        if (json == null) return null;
        return EtkinlikModel.fromMap(json as Map<String, dynamic>);
      },
      auth: true,
    );
  }
}
