// lib/services/uye/isletme_basvuru_service.dart
//
// Başka işletmeye üyelik başvurusu. Backend: api/uye/isletme_basvuru.py;
// kurallar calendarapp/services/isletme_basvuru_service.py (burada tekrar
// edilmez). Her yanıt hesabın güncel profillerini de getirir; "Profil
// değiştir" önbelleği burada tazelenir, onaylanan profil hemen görünür.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/2_uye/isletme_basvuru_models.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/core/auth_service.dart';

IsletmeBasvuruVerisi _veri(dynamic json) => IsletmeBasvuruVerisi.fromJson(
    (json as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{});

class IsletmeBasvuruService {
  IsletmeBasvuruService._();

  static Future<IsletmeBasvuruVerisi> getir() async {
    final sonuc = await ApiClient.postParsed<IsletmeBasvuruVerisi>(
      isletmeBasvurulariUrl,
      const {},
      _veri,
    );
    final veri = sonuc.data ?? const IsletmeBasvuruVerisi();
    await _profilleriTazele(veri);
    return veri;
  }

  /// Başvuruyu gönderir; güncel sayfa verisi ve sunucu mesajı döner.
  static Future<(IsletmeBasvuruVerisi, String)> basvur(int isletmeId) async {
    final sonuc = await ApiClient.postParsed<IsletmeBasvuruVerisi>(
      isletmeBasvurUrl,
      {'isletme_id': isletmeId, 'kvkk_onay': true},
      _veri,
    );
    final veri = sonuc.data ?? const IsletmeBasvuruVerisi();
    await _profilleriTazele(veri);
    return (veri, sonuc.mesaj);
  }

  static Future<void> _profilleriTazele(IsletmeBasvuruVerisi veri) async {
    if (veri.profiller.isNotEmpty) {
      await AuthService.profilleriTazele(veri.profiller);
    }
  }
}
