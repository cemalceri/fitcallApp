// lib/services/yonetici/yonetici_etkinlik_service.dart
//
// Yönetici ders (etkinlik) yönetimi uçları.
// Backend: api/yonetici/etkinlik_metots.py
//
// Kaydetme ve iptal, backend'de web ile ORTAK servis katmanından geçer
// (calendarapp/services/etkinlik_kaydet_service.py & etkinlik_iptal_service.py);
// dolayısıyla mobilden yapılan işlem web ile birebir aynı kuralları uygular.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

class YoneticiEtkinlikService {
  /// Verilen tarihin içinde bulunduğu haftanın (Pzt-Paz) programı.
  static Future<ApiResult<HaftalikProgram>> haftalikProgram({
    required DateTime tarih,
  }) {
    return ApiClient.postParsed<HaftalikProgram>(
      yoneticiHaftalikProgramUrl,
      {'tarih': formatApiGun(tarih)},
      (json) => HaftalikProgram.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }

  /// Kayıt/düzenleme formunun seçenek listeleri.
  /// [etkinlikId] verilirse mevcut değerler ve seçili üyeler de döner.
  static Future<ApiResult<EtkinlikFormVerileri>> formVerileri({
    int? etkinlikId,
  }) {
    return ApiClient.postParsed<EtkinlikFormVerileri>(
      yoneticiEtkinlikFormVerileriUrl,
      {if (etkinlikId != null) 'etkinlik_id': etkinlikId},
      (json) =>
          EtkinlikFormVerileri.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }

  /// Ders oluşturur veya günceller. Dönen değer yeni/güncel etkinlik id'sidir.
  static Future<ApiResult<int>> kaydet(EtkinlikKaydetIstegi istek) {
    return ApiClient.postParsed<int>(
      yoneticiEtkinlikKaydetUrl,
      istek.toJson(),
      (json) => ((json as Map)['etkinlik_id'] as num).toInt(),
      auth: true,
    );
  }

  /// Dersi iptal eder.
  /// [mod]: STANDART | TELAFI_VER | HAKKI_IADE_ET | BORC_YAZMA
  static Future<ApiResult<int>> iptalEt({
    required int etkinlikId,
    required String sebep,
    String aciklama = '',
    String mod = 'STANDART',
  }) {
    return ApiClient.postParsed<int>(
      yoneticiEtkinlikIptalUrl,
      {
        'etkinlik_id': etkinlikId,
        'sebep': sebep,
        'aciklama': aciklama,
        'mod': mod,
      },
      (json) => ((json as Map)['etkinlik_id'] as num).toInt(),
      auth: true,
    );
  }

  /// İptal edilmiş dersi yeniden aktif eder.
  static Future<ApiResult<int>> iptalGeriAl({required int etkinlikId}) {
    return ApiClient.postParsed<int>(
      yoneticiEtkinlikIptalGeriAlUrl,
      {'etkinlik_id': etkinlikId},
      (json) => ((json as Map)['etkinlik_id'] as num).toInt(),
      auth: true,
    );
  }

  /// Kalıcı silmenin yok edeceği bağlı kayıtların sayımı (uyarı penceresi için).
  static Future<ApiResult<SilmeEtkisi>> silmeOnizleme({
    required int etkinlikId,
  }) {
    return ApiClient.postParsed<SilmeEtkisi>(
      yoneticiEtkinlikSilOnizlemeUrl,
      {'etkinlik_id': etkinlikId},
      (json) => SilmeEtkisi.fromJson((json as Map).cast<String, dynamic>()),
      auth: true,
    );
  }

  /// Dersi kalıcı olarak siler. Geri alınamaz; önce [silmeOnizleme] gösterilmeli.
  static Future<ApiResult<int>> sil({required int etkinlikId}) {
    return ApiClient.postParsed<int>(
      yoneticiEtkinlikSilUrl,
      {'etkinlik_id': etkinlikId, 'onaylandi': true},
      (json) => ((json as Map)['etkinlik_id'] as num).toInt(),
      auth: true,
    );
  }
}
