// lib/services/ofis/ofis_uye_talep_service.dart
//
// Ofisin talep ekranı: Bende / Beklemede / Kapanan ve üye talebi işlemleri
// (hocaya sor, telefonla onay, kayıt oluştur, değişiklik öner, öneriyi geri
// çek). Ret ortak uçtan: DersKayitTalebiService.reddet.
// Backend: api/uye_talep/metots.py, kurallar uye_talep_service.py.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/services/api_client.dart';

Map<String, dynamic> _harita(dynamic json) =>
    (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

class OfisUyeTalepService {
  OfisUyeTalepService._();

  static Future<OfisTalepListesi> liste(String sekme, {String? arama}) async {
    final sonuc = await ApiClient.postParsed<OfisTalepListesi>(
      ofisTaleplerUrl,
      {'sekme': sekme, if (arama != null && arama.isNotEmpty) 'arama': arama},
      (json) => OfisTalepListesi.fromJson(_harita(json)),
    );
    return sonuc.data ?? const OfisTalepListesi();
  }

  /// Talep + seçilen saatte boş hoca/kort. Saat verilmezse talebin saati.
  static Future<OfisTalepDetay> detay(int talepId,
      {DateTime? baslangic, int? sureDk}) async {
    final sonuc = await ApiClient.postParsed<OfisTalepDetay>(
      ofisUyeTalepDetayUrl,
      {
        'talep_id': talepId,
        if (baslangic != null)
          'baslangic_tarih_saat': formatApiTarih(baslangic),
        if (sureDk != null) 'sure_dk': sureDk,
      },
      (json) => OfisTalepDetay.fromJson(_harita(json)),
    );
    return sonuc.data!;
  }

  static Future<String> _islem(String url, Map<String, dynamic> govde) async {
    final sonuc = await ApiClient.postParsed<void>(url, govde, (_) {});
    return sonuc.mesaj;
  }

  static Future<String> hocayaSor(int talepId, {int? antrenorId}) => _islem(
      ofisUyeTalepHocayaSorUrl,
      {'talep_id': talepId, 'antrenor_id': antrenorId});

  static Future<String> telefonOnay(int talepId, {int? antrenorId}) => _islem(
      ofisUyeTalepTelefonOnayUrl,
      {'talep_id': talepId, 'antrenor_id': antrenorId});

  /// Olduğu gibi kaydet. Yalnız "Fark etmez" hoca/kort ve (esneme varsa)
  /// saat verilebilir; sunucu başkasını reddeder.
  static Future<String> kaydet(
    int talepId, {
    int? antrenorId,
    int? kortId,
    DateTime? baslangic,
    int? urunId,
  }) =>
      _islem(ofisUyeTalepKaydetUrl, {
        'talep_id': talepId,
        'antrenor_id': antrenorId,
        'kort_id': kortId,
        if (baslangic != null)
          'baslangic_tarih_saat': formatApiTarih(baslangic),
        'urun_id': urunId,
      });

  static Future<String> oneri(
    int talepId, {
    required DateTime baslangic,
    required int sureDk,
    int? antrenorId,
    required int kortId,
    int? kisiSayisi,
    int? urunId,
    String? ekstraUcret,
    required String notu,
    bool hocaOnayladi = false,
    bool uyeTelefondaOnayladi = false,
  }) =>
      _islem(ofisUyeTalepOneriUrl, {
        'talep_id': talepId,
        'baslangic_tarih_saat': formatApiTarih(baslangic),
        'sure_dk': sureDk,
        'antrenor_id': antrenorId,
        'kort_id': kortId,
        'kisi_sayisi': kisiSayisi,
        'urun_id': urunId,
        'ekstra_ucret': ekstraUcret,
        'notu': notu,
        'hoca_onayladi': hocaOnayladi,
        'uye_telefonda_onayladi': uyeTelefondaOnayladi,
      });

  static Future<String> oneriGeriCek(int talepId) =>
      _islem(ofisUyeTalepOneriGeriCekUrl, {'talep_id': talepId});
}
