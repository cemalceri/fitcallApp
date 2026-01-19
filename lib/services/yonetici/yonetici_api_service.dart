// lib/services/yonetici/yonetici_api_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class YoneticiApiService {
  // ==================== DASHBOARD ====================

  /// Dashboard verilerini getirir
  /// [donem]: 'bugun' | 'bu_hafta' | 'bu_ay'
  static Future<ApiResult<DashboardData>> getDashboard({
    required DonemFiltresi donem,
  }) {
    return ApiClient.postParsed<DashboardData>(
      yoneticiDashboard,
      {'donem': donem.apiValue},
      (json) => DashboardData.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }

  // ==================== RAPORLAR ====================

  /// Raporlar verilerini getirir
  static Future<ApiResult<RaporlarData>> getRaporlar({
    required DonemFiltresi donem,
  }) {
    return ApiClient.postParsed<RaporlarData>(
      yoneticiRaporlar,
      {'donem': donem.apiValue},
      (json) => RaporlarData.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }

  // ==================== ÜYELER ====================

  /// Üye listesini getirir
  static Future<ApiResult<UyelerData>> getUyeler({
    int sayfa = 1,
    String arama = '',
    String filtre = 'tumu', // 'aktif' | 'pasif' | 'tumu'
    String siralama = 'ad', // 'ad' | 'uye_no' | 'son_ders' | 'bakiye'
  }) {
    return ApiClient.postParsed<UyelerData>(
      yoneticiUyeler,
      {
        'sayfa': sayfa,
        'arama': arama,
        'filtre': filtre,
        'siralama': siralama,
      },
      (json) => UyelerData.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }

  // ==================== ANTRENÖRLER ====================

  /// Antrenör listesini getirir
  static Future<ApiResult<AntrenorlerData>> getAntrenorler({
    String filtre = 'aktif', // 'aktif' | 'pasif' | 'tumu'
  }) {
    return ApiClient.postParsed<AntrenorlerData>(
      yoneticiAntrenorler,
      {'filtre': filtre},
      (json) => AntrenorlerData.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }

  // ==================== DERSLER ====================

  /// Ders listesini getirir
  static Future<ApiResult<DerslerData>> getDersler({
    required DateTime tarih,
    int sayfa = 1,
    String filtre = 'tumu', // 'tumu' | 'tamamlandi' | 'bekliyor' | 'iptal'
    int? antrenorId,
  }) {
    return ApiClient.postParsed<DerslerData>(
      yoneticiDersler,
      {
        'tarih': tarih.toIso8601String().split('T')[0],
        'sayfa': sayfa,
        'filtre': filtre,
        if (antrenorId != null) 'antrenor_id': antrenorId,
      },
      (json) => DerslerData.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }

  /// Tek ders detayını getirir
  static Future<ApiResult<DersListeItem>> getDersDetay({
    required int dersId,
  }) {
    return ApiClient.postParsed<DersListeItem>(
      yoneticiDersDetay,
      {'ders_id': dersId},
      (json) => DersListeItem.fromJson(json as Map<String, dynamic>),
      auth: true,
    );
  }
}
