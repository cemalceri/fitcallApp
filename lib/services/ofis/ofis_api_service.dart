// lib/services/ofis/ofis_api_service.dart
//
// Ofis (ön büro) üye uçları.
// Backend: api/ofis/metots.py
//
// Ofisin diğer ihtiyaçları yöneticiyle ORTAK servislerden karşılanır:
//   - haftalık program / ders kaydet-iptal-sil → YoneticiEtkinlikService
//   - günlük ders listesi                      → YoneticiApiService.getDersler
// Bu uçlar backend'de rol izni "yonetici" + "ofis" olarak açıldı.
//
// Burada ayrı uç olmasının tek sebebi ALAN KIRPMASI: ofis üye listesinde bakiye,
// üye detayında para hareketleri/aylık özet ve mahrem profil alanları yok.
// Kırpma sunucuda; modelde o alanlar hiç tanımlı değil.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class OfisApiService {
  /// Üye listesi. [filtre]: tumu | aktif | pasif — [siralama]: ad | uye_no | son_ders.
  ///
  /// Backend bilinmeyen filtre/sıralama değerlerini varsayılana düşürür;
  /// "borclu" filtresi ve "bakiye" sıralaması ofise kapalıdır.
  static Future<ApiResult<OfisUyelerData>> uyeler({
    String arama = '',
    String filtre = 'tumu',
    String siralama = 'ad',
    bool hepsi = true,
  }) {
    return ApiClient.postParsed<OfisUyelerData>(
      ofisUyelerUrl,
      {
        'arama': arama,
        'filtre': filtre,
        'siralama': siralama,
        'hepsi': hepsi,
      },
      (json) => OfisUyelerData.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }

  /// Tek üye detayı — profil (kırpılmış) + paketler + yaklaşan/geçmiş dersler.
  static Future<ApiResult<OfisUyeDetayData>> uyeDetay({required int uyeId}) {
    return ApiClient.postParsed<OfisUyeDetayData>(
      ofisUyeDetayUrl,
      {'uye_id': uyeId},
      (json) =>
          OfisUyeDetayData.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }
}
