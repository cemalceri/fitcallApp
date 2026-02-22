import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/models/6_muhasebe/payment_hesaplama_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class MuhasebeService {
  static Future<ApiResult<List<MuhasebeOzetModel>>> fetch() {
    return ApiClient.postParsed<List<MuhasebeOzetModel>>(
      getMuhasebeOzet,
      const {}, // parametre yok
      (json) => MuhasebeOzetModel.listFromJson(json),
    );
  }

  static Future<ApiResult<PaymentHesaplamaModel>> hesapla(
      List<Map<String, int>> ayListesi) {
    return ApiClient.postParsed<PaymentHesaplamaModel>(
      odemeHesaplaUrl,
      {'ay_listesi': ayListesi},
      (json) => PaymentHesaplamaModel.fromJson(json),
    );
  }

  /// Ödeme siparişi oluşturur, payment_url döner
  static Future<ApiResult<Map<String, dynamic>>> baslat(
      List<Map<String, int>> ayListesi) {
    return ApiClient.postParsed<Map<String, dynamic>>(
      odemeBaslatUrl,
      {'ay_listesi': ayListesi},
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Sipariş durumunu sorgular
  static Future<ApiResult<Map<String, dynamic>>> durum(String siparisId) {
    return ApiClient.getParsed<Map<String, dynamic>>(
      '$odemeDurumUrl$siparisId/',
      (json) => json as Map<String, dynamic>,
    );
  }
}
