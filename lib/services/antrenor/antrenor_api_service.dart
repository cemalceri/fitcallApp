// lib/services/antrenor/antrenor_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/3_antrenor/ders_devir_talebi_model.dart';
import 'package:fitcall/models/3_antrenor/home_card_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/notification/notification_action_service.dart';

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

class DersDevirService {
  /// Devir için aday antrenör listesini getirir.
  static Future<ApiResult<DevirAdayAntrenorListesiDto>> getAdayAntrenorListesi({
    required int dersId,
  }) {
    return ApiClient.postParsed<DevirAdayAntrenorListesiDto>(
      getDersIcinAntrenorListesiUrl,
      {'ders_id': dersId},
      (json) => DevirAdayAntrenorListesiDto.fromMap(
        (json as Map).cast<String, dynamic>(),
      ),
      auth: true,
    );
  }

  /// Yeni devir talebi oluşturur.
  static Future<ApiResult<int>> talepOlustur({
    required int dersId,
    required int hedefAntrenorId,
    String? talepNotu,
  }) {
    final body = <String, dynamic>{
      'ders_id': dersId,
      'hedef_antrenor_id': hedefAntrenorId,
      if (talepNotu != null && talepNotu.trim().isNotEmpty)
        'talep_notu': talepNotu.trim(),
    };

    return ApiClient.postParsed<int>(
      dersDevirTalebiOlusturUrl,
      body,
      (json) {
        final m = (json as Map).cast<String, dynamic>();
        final v = m['talep_id'];
        return v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
      },
      auth: true,
    );
  }

  /// [Auth gerektiren] Talebi kabul eder veya reddeder.
  static Future<ApiResult<void>> talepCevapla({
    required int talepId,
    required String islem,
    String? cevapNotu,
  }) {
    final body = <String, dynamic>{
      'talep_id': talepId,
      'islem': islem,
      if (cevapNotu != null && cevapNotu.trim().isNotEmpty)
        'cevap_notu': cevapNotu.trim(),
    };

    return ApiClient.postParsed<void>(
      dersDevirTalebiCevaplaUrl,
      body,
      (_) {},
      auth: true,
    );
  }

  /// [Auth gerektiren] Talep eden, BEKLIYOR durumdaki kendi talebini geri çeker.
  static Future<ApiResult<void>> talepGeriCek({
    required int talepId,
  }) {
    return ApiClient.postParsed<void>(
      dersDevirTalebiGeriCekUrl,
      {'talep_id': talepId},
      (_) {},
      auth: true,
    );
  }

  /// [Auth gerektiren] Talep detayı.
  static Future<ApiResult<DevirTalebiDetayDto>> getTalepDetay({
    required int talepId,
  }) {
    return ApiClient.postParsed<DevirTalebiDetayDto>(
      getDersDevirTalebiDetayUrl,
      {'talep_id': talepId},
      (json) => DevirTalebiDetayDto.fromMap(
        (json as Map).cast<String, dynamic>(),
      ),
      auth: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ACTION TOKEN BAZLI METOTLAR (auth: false)
  //  Bildirim üzerinden gelen action token ile işlem yapar.
  //  Login gerektirmez.
  // ═══════════════════════════════════════════════════════════════════════

  /// Action token ile devir talebi detayını getirir.
  static Future<DevirTalebiDetayDto> getTalepDetayByToken(String token) async {
    final res = await NotificationActionService.executeAction(
      token,
      'devir_detay',
    );
    return DevirTalebiDetayDto.fromMap(res);
  }

  /// Action token ile devir talebini kabul eder.
  static Future<void> talepKabulEtByToken(String token,
      {String? cevapNotu}) async {
    await NotificationActionService.executeAction(
      token,
      'devir_kabul',
      aciklama: cevapNotu ?? '',
    );
  }

  /// Action token ile devir talebini reddeder.
  static Future<void> talepRedEtByToken(String token,
      {String? cevapNotu}) async {
    await NotificationActionService.executeAction(
      token,
      'devir_red',
      aciklama: cevapNotu ?? '',
    );
  }
}
