import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/dtos/paket_veri_response_dto.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DersTalepApiService {
  /// Üyenin mevcut paketleri + mobil alıma uygun ürünleri getirir.
  /// Django: GetUrunListesiVeUyePaketleri (POST) – `request.uye` kullanıyor, `uye_id` gereksiz.
  static Future<ApiResult<PaketVeriResponse>> getirtUrunListesiVeUyePaketleri({
    int? antrenorId,
  }) {
    final payload = <String, dynamic>{
      if (antrenorId != null) 'antrenor_id': antrenorId,
    };

    return ApiClient.postParsed<PaketVeriResponse>(
      getUrunListesiVeUyePaketleri, // api_urls.dart sabiti
      payload,
      (json) => PaketVeriResponse.fromJson(
        (json as Map).cast<String, dynamic>(),
      ),
    );
  }

  /// Tek slot rezervasyon talebi gönderir
  /// Opsiyonel: urun_id, satinal, uye_id
  static Future<ApiResult<Map<String, dynamic>>> gonderDersTalep({
    required int kortId,
    required int antrenorId,
    required DateTime baslangic,
    required DateTime bitis,
    String? aciklama,
    int? urunId,
    bool? satinal,
    int? uyeId,
  }) {
    final payload = <String, dynamic>{
      'kort_id': kortId,
      'antrenor_id': antrenorId,
      'baslangic_tarih_saat': baslangic.toUtc().toIso8601String(),
      'bitis_tarih_saat': bitis.toUtc().toIso8601String(),
      'aciklama': aciklama ?? '',
      if (urunId != null) 'urun_id': urunId,
      if (satinal != null) 'satinal': satinal,
      if (uyeId != null) 'uye_id': uyeId,
    };

    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersTalep,
      payload,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Genel ders talebi gönderir (çoklu saat)
  /// Opsiyonel: urun_id, satinal, uye_id, kort_id, antrenor_id
  static Future<ApiResult<Map<String, dynamic>>> gonderGenelDersTalep({
    required Map<String, List<String>> saatler,
    String? aciklama,
    int? kortId,
    int? antrenorId,
    int? urunId,
    bool? satinal,
    int? uyeId,
  }) {
    final payload = <String, dynamic>{
      'saatler': saatler,
      'aciklama': aciklama ?? '',
      if (kortId != null) 'kort_id': kortId,
      if (antrenorId != null) 'antrenor_id': antrenorId,
      if (urunId != null) 'urun_id': urunId,
      if (satinal != null) 'satinal': satinal,
      if (uyeId != null) 'uye_id': uyeId,
    };

    return ApiClient.postParsed<Map<String, dynamic>>(
      setGenelDersTalep,
      payload,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }
}
