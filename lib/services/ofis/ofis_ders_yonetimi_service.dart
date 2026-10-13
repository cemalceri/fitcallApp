// lib/services/ofis/ofis_ders_yonetimi_service.dart
//
// Ofis Ana Sayfa (bekleyen işler), Dersler ve plan dışı kararlar. Her işlem
// sunucunun mesajını döndürür (snackbar'da gösterilir); kurallar sunucuda.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/services/api_client.dart';

/// Yönetici kararı: yapıldı / yapılmadı / kararı kaldır.
enum DersKarari { yapildi, yapilmadi, temizle }

class OfisDersYonetimiService {
  static Map<String, dynamic> _harita(dynamic json) =>
      (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

  static Future<String> _islem(String url, Map<String, dynamic> govde) async {
    final sonuc = await ApiClient.postParsed<Map<String, dynamic>>(
        url, govde, _harita);
    return sonuc.mesaj;
  }

  static Future<OfisBekleyenIsler?> bekleyenIsler() async {
    final sonuc = await ApiClient.postParsed<OfisBekleyenIsler>(
      ofisBekleyenIslerUrl,
      const {},
      (json) => OfisBekleyenIsler.fromJson(_harita(json)),
    );
    return sonuc.data;
  }

  static Future<DersYonetimiGun?> gun(DateTime tarih) async {
    final sonuc = await ApiClient.postParsed<DersYonetimiGun>(
      ofisDersYonetimiGunUrl,
      {'tarih': formatApiGun(tarih)},
      (json) => DersYonetimiGun.fromJson(_harita(json)),
    );
    return sonuc.data;
  }

  static Future<String> onayVer(int etkinlikId, DersKarari karar,
      {String? neden}) {
    return _islem(ofisDersOnayUrl, {
      'etkinlik_id': etkinlikId,
      'karar': switch (karar) {
        DersKarari.yapildi => 'yapildi',
        DersKarari.yapilmadi => 'yapilmadi',
        DersKarari.temizle => 'temizle',
      },
      if (neden != null && neden.trim().isNotEmpty) 'neden': neden.trim(),
    });
  }

  /// Günün, antrenörün "yapıldı" dediği derslerini toplu onaylar.
  static Future<String> gunuOnayla(DateTime tarih) =>
      _islem(ofisGunuOnaylaUrl, {'tarih': formatApiGun(tarih)});

  /// [yardimci] true ise yardımcı antrenörün hakedişi. [deger] null: karar yok.
  static Future<String> hakedis(int etkinlikId, bool? deger,
          {bool yardimci = false}) =>
      _islem(ofisDersHakedisUrl, {
        'etkinlik_id': etkinlikId,
        'rol': yardimci ? 'yardimci' : 'antrenor',
        'deger': deger,
      });

  /// [dus] true: paketten düş, false: düşümü geri al (istenen durum;
  /// sunucu zaten o durumdaysa değiştirmez).
  static Future<String> paketDusum(int etkinlikId, int uyeId,
          {required bool dus}) =>
      _islem(ofisPaketDusumUrl,
          {'etkinlik_id': etkinlikId, 'uye_id': uyeId, 'sayima_dahil': dus});

  static Future<String> manuelTeyit(int etkinlikId, int uyeId) =>
      _islem(ofisManuelTeyitUrl, {'etkinlik_id': etkinlikId, 'uye_id': uyeId});

  static Future<String> teyitHatirlat(int etkinlikId, int uyeId) => _islem(
      ofisTeyitHatirlatUrl, {'etkinlik_id': etkinlikId, 'uye_id': uyeId});

  static Future<List<PlanDisiDers>> planDisiBekleyenler() async {
    final sonuc = await ApiClient.postParsed<List<PlanDisiDers>>(
      ofisPlanDisiBekleyenlerUrl,
      const {},
      (json) => (_harita(json)['dersler'] as List? ?? [])
          .map((e) => PlanDisiDers.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
    return sonuc.data ?? const [];
  }

  static Future<PlanDisiSecenekler?> planDisiSecenekler(PlanDisiKisi kisi) async {
    final sonuc = await ApiClient.postParsed<PlanDisiSecenekler>(
      ofisPlanDisiSeceneklerUrl,
      {'tur': kisi.tur, 'id': kisi.id},
      (json) => PlanDisiSecenekler.fromJson(_harita(json)),
    );
    return sonuc.data;
  }

  /// [karar]: BORC | PAKET | UCRETSIZ (backend PlanDisiKararEnum).
  static Future<String> planDisiKarar({
    required List<PlanDisiKisi> kisiler,
    required String karar,
    required String aciklama,
    int? hedefUyeId,
    int? uyeUrunId,
    String? tutar,
  }) {
    return _islem(ofisPlanDisiKararUrl, {
      'kayitlar': [for (final k in kisiler) k.anahtar],
      'karar': karar,
      'aciklama': aciklama,
      if (hedefUyeId != null) 'hedef_uye_id': hedefUyeId,
      if (uyeUrunId != null) 'uye_urun_id': uyeUrunId,
      if (tutar != null && tutar.isNotEmpty) 'tutar': tutar,
    });
  }
}
