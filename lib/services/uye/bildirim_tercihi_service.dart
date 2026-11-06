// lib/services/uye/bildirim_tercihi_service.dart
//
// Üye bildirim tercihleri (yalnız üye ana hesabı). Backend:
// api/uye/bildirim_tercihi.py. Kapatılan grubun bildirimleri telefona push
// olarak gitmez; Bildirimlerim listesinde durur. Filtre sunucuda, gönderimde.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/bildirim_tercihi_models.dart';
import 'package:fitcall/services/api_client.dart';

BildirimTercihleri _veri(dynamic json) => BildirimTercihleri.fromJson(
    (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{});

class BildirimTercihiService {
  BildirimTercihiService._();

  static Future<BildirimTercihleri> getir() async {
    final sonuc = await ApiClient.postParsed<BildirimTercihleri>(
      uyeBildirimTercihleriUrl,
      const {},
      _veri,
      auth: true,
    );
    return sonuc.data ?? const BildirimTercihleri();
  }

  /// Grubu açar/kapatır; sunucudaki güncel tercihler ve mesaj döner.
  static Future<(BildirimTercihleri, String)> kaydet(
      String grup, bool acik) async {
    final sonuc = await ApiClient.postParsed<BildirimTercihleri>(
      uyeBildirimTercihiKaydetUrl,
      {'grup': grup, 'acik': acik},
      _veri,
      auth: true,
    );
    return (sonuc.data ?? const BildirimTercihleri(), sonuc.mesaj);
  }
}
