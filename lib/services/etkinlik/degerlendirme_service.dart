// lib/services/etkinlik/degerlendirme_service.dart
//
// Bir antrenörün ders değerlendirmeleri — yalnız yönetici (uç diğer rolleri
// 403 ile reddeder). Backend: api/etkinlik/degerlendirmeler.py

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class DegerlendirmeService {
  /// 20'şerlik sayfa ([sayfa] 1'den başlar).
  /// [filtre]: tumu | yorumlu | dusuk (3 ve altı).
  static Future<ApiResult<DegerlendirmeSayfasi>> liste({
    int sayfa = 1,
    String filtre = 'tumu',
    int? antrenorId,
  }) {
    return ApiClient.postParsed<DegerlendirmeSayfasi>(
      degerlendirmeListesiUrl,
      {
        'sayfa': sayfa,
        'filtre': filtre,
        if (antrenorId != null) 'antrenor_id': antrenorId,
      },
      (json) =>
          DegerlendirmeSayfasi.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }
}
