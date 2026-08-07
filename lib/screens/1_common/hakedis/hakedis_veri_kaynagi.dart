// lib/screens/1_common/hakedis/hakedis_veri_kaynagi.dart
//
// Hakediş ekranlarının veri kaynağı soyutlaması.
//
// Ay panosu ve ders listesi ekranları iki rolde de birebir aynı; farkeden tek
// şey hangi ucun çağrıldığı. Sayfaları rolden habersiz tutup değişkeni buraya
// almak, ekranların çatallanmasını engelliyor:
//
//   yönetici → istediği antrenörü görür, antrenor_id isteğe konur
//   antrenör → yalnız kendini görür, id backend'de token'dan çözülür
//
// Backend iki uç için de aynı gövdeyi döndürür (bkz. hakedis_metots.py
// `_ozet_cikti` / `_dersler_cikti`), o yüzden tek model seti yetiyor.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/services/antrenor/antrenor_hakedis_service.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/yonetici/yonetici_hakedis_service.dart';

abstract class HakedisVeriKaynagi {
  const HakedisVeriKaynagi();

  Future<ApiResult<HakedisOzet>> ozet();

  Future<ApiResult<HakedisDersListesi>> dersler({
    required int yil,
    required int ay,
    required String rol,
    required String durum,
  });
}

/// Yöneticinin seçtiği antrenörün hakedişi.
class YoneticiHakedisKaynagi extends HakedisVeriKaynagi {
  final int antrenorId;

  const YoneticiHakedisKaynagi(this.antrenorId);

  @override
  Future<ApiResult<HakedisOzet>> ozet() =>
      YoneticiHakedisService.ozet(antrenorId: antrenorId);

  @override
  Future<ApiResult<HakedisDersListesi>> dersler({
    required int yil,
    required int ay,
    required String rol,
    required String durum,
  }) =>
      YoneticiHakedisService.dersler(
        antrenorId: antrenorId,
        yil: yil,
        ay: ay,
        rol: rol,
        durum: durum,
      );
}

/// Giriş yapmış antrenörün kendi hakedişi — istekte antrenör id'si taşınmaz.
class AntrenorHakedisKaynagi extends HakedisVeriKaynagi {
  const AntrenorHakedisKaynagi();

  @override
  Future<ApiResult<HakedisOzet>> ozet() => AntrenorHakedisService.ozet();

  @override
  Future<ApiResult<HakedisDersListesi>> dersler({
    required int yil,
    required int ay,
    required String rol,
    required String durum,
  }) =>
      AntrenorHakedisService.dersler(
        yil: yil,
        ay: ay,
        rol: rol,
        durum: durum,
      );
}
