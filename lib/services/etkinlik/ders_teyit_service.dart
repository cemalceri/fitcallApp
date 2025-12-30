// lib/services/etkinlik/ders_teyit_service.dart

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

/// Ders teyit detay modeli
class TeyitDetayModel {
  final EtkinlikDetay etkinlik;
  final UyeDetay uye;
  final TeyitDurum? teyit;

  TeyitDetayModel({
    required this.etkinlik,
    required this.uye,
    this.teyit,
  });

  factory TeyitDetayModel.fromJson(Map<String, dynamic> json) {
    return TeyitDetayModel(
      etkinlik: EtkinlikDetay.fromJson(json['etkinlik'] ?? {}),
      uye: UyeDetay.fromJson(json['uye'] ?? {}),
      teyit: json['teyit'] != null ? TeyitDurum.fromJson(json['teyit']) : null,
    );
  }

  /// Teyit verilmiş mi?
  bool get teyitVerilmis => teyit?.katilacakMi != null;
}

class EtkinlikDetay {
  final int id;
  final String tarih;
  final String saat;
  final String bitisSaat;
  final String kort;
  final String antrenor;
  final bool gecmisMi;

  EtkinlikDetay({
    required this.id,
    required this.tarih,
    required this.saat,
    required this.bitisSaat,
    required this.kort,
    required this.antrenor,
    required this.gecmisMi,
  });

  factory EtkinlikDetay.fromJson(Map<String, dynamic> json) {
    return EtkinlikDetay(
      id: json['id'] ?? 0,
      tarih: json['tarih'] ?? '',
      saat: json['saat'] ?? '',
      bitisSaat: json['bitis_saat'] ?? '',
      kort: json['kort'] ?? '',
      antrenor: json['antrenor'] ?? '',
      gecmisMi: json['gecmis_mi'] ?? false,
    );
  }
}

class UyeDetay {
  final int id;
  final String adSoyad;

  UyeDetay({
    required this.id,
    required this.adSoyad,
  });

  factory UyeDetay.fromJson(Map<String, dynamic> json) {
    return UyeDetay(
      id: json['id'] ?? 0,
      adSoyad: json['ad_soyad'] ?? '',
    );
  }
}

class TeyitDurum {
  final int id;
  final bool? katilacakMi;
  final String? aciklama;
  final String? teyitTarihi;
  final bool okundu;

  TeyitDurum({
    required this.id,
    this.katilacakMi,
    this.aciklama,
    this.teyitTarihi,
    required this.okundu,
  });

  factory TeyitDurum.fromJson(Map<String, dynamic> json) {
    return TeyitDurum(
      id: json['id'] ?? 0,
      katilacakMi: json['katilacak_mi'],
      aciklama: json['aciklama'],
      teyitTarihi: json['teyit_tarihi'],
      okundu: json['okundu'] ?? false,
    );
  }
}

class DersTeyitService {
  /// Bildirim detayını getirir
  static Future<ApiResult<NotificationModel>> getBildirim(String bildirimId) {
    return ApiClient.postParsed<NotificationModel>(
      getBildirimById,
      {'notification_id': bildirimId},
      (json) => ApiParsing.parseObject<NotificationModel>(
        json,
        (m) => NotificationModel.fromJson(m),
      ),
    );
  }

  /// Teyit detayını getirir (etkinlik + üye + teyit durumu)
  static Future<ApiResult<TeyitDetayModel>> getTeyitDetayBilgisi({
    required String etkinlikId,
    required String uyeId,
  }) {
    return ApiClient.postParsed<TeyitDetayModel>(
      getTeyitDetay, // api_urls.dart'tan gelen URL
      {'etkinlik_id': etkinlikId, 'uye_id': uyeId},
      (json) => TeyitDetayModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Teyit gönderir
  static Future<ApiResult<Map<String, dynamic>>> setDersTeyitBilgisi({
    required String uyeId,
    required String etkinlikId,
    required bool durum,
    String? aciklama,
  }) {
    final body = <String, dynamic>{
      'uye_id': uyeId,
      'etkinlik_id': etkinlikId,
      'durum': durum,
    };

    if (aciklama != null && aciklama.isNotEmpty) {
      body['aciklama'] = aciklama;
    }

    return ApiClient.postParsed<Map<String, dynamic>>(
      setDersTeyit,
      body,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Teyit bildirimini okundu olarak işaretler
  static Future<ApiResult<void>> setTeyitOkunduApi({
    required String etkinlikId,
    required String uyeId,
  }) {
    return ApiClient.postParsed<void>(
      setTeyitOkundu,
      {'etkinlik_id': etkinlikId, 'uye_id': uyeId},
      (_) {},
    );
  }
}
