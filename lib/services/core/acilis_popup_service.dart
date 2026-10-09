// lib/services/core/acilis_popup_service.dart
//
// Açılış popup'larının (doğum günü kutlaması + popup duyurusu) kuralları ve
// "gösterildi" kayıtları. Ekran tarafı: lib/screens/1_common/acilis_popup/.
//
// Kurallar (ekip + kullanıcı kararı, 2026-10-09):
//   - Açılış başına en fazla bir popup; doğum günü önce gelir, duyuru bir
//     sonraki açılışa kalır.
//   - Doğum günü yalnız aktif üye profiline, profil + yıl başına bir kez.
//     Kayıt cihazda tutulur (aynı hesabı iki telefonda kullanan ikisinde de
//     birer kez görür — bilinçli tercih).
//   - 1 Ocak doğum tarihleri kutlanmaz: yer tutucu/sahte tarihler (ör. misafir
//     havuzu 2000-01-01) yüzünden toplu kutlama riski var.
//   - Duyuru hesap başına bir kez; asıl kayıt sunucuda (DuyuruOkuma), cihazdaki
//     kayıt yalnız "okundu" isteği ağ hatasıyla düşerse tekrar çıkmasın diye.

import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/services/core/storage_service.dart';

/// [dogum] bugün kutlanacak bir doğum günü mü? [bugun] kulüp saatiyle verilir.
///
/// 29 Şubat doğumlular artık yıl olmayan yıllarda 28 Şubat'ta kutlanır.
bool dogumGunuMu(DateTime dogum, DateTime bugun) {
  if (dogum.month == 1 && dogum.day == 1) return false;
  if (dogum.month == 2 && dogum.day == 29 && !_artikYil(bugun.year)) {
    return bugun.month == 2 && bugun.day == 28;
  }
  return dogum.month == bugun.month && dogum.day == bugun.day;
}

bool _artikYil(int yil) =>
    (yil % 4 == 0 && yil % 100 != 0) || yil % 400 == 0;

/// Sunucu süzse de istemci yayın aralığını bir kez daha doğrular: bitişi
/// olmayan ya da süresi geçmiş duyuru asla popup olmaz.
bool popupYayindaMi(DuyuruModel duyuru, DateTime simdi) {
  final bitis = duyuru.yayinBitis;
  if (bitis == null) return false;
  return !duyuru.yayinBaslangic.isAfter(simdi) && !bitis.isBefore(simdi);
}

/// Popup'ta gösterilecek kısa metin: alt başlık doluysa o, değilse içerik
/// (satır sonları tek boşluğa indirgenir; kesme `maxLines` ile ekranda yapılır).
String duyuruPopupOzeti(DuyuruModel duyuru) {
  final alt = duyuru.altBaslik.trim();
  if (alt.isNotEmpty) return alt;
  return duyuru.icerik.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// "Detaylı bilgi" butonu ancak gösterilecek fazlası varsa çıkar.
bool duyuruDetayiVarMi(DuyuruModel duyuru) =>
    duyuru.icerik.trim().isNotEmpty || duyuru.tumResimUrlleri.length > 1;

/// Popup'ların cihazdaki "gösterildi" kayıtları. Oturumdan bağımsızdır:
/// çıkış yapınca silinmez (bkz. [StorageService.clearAll]), yoksa aynı gün
/// tekrar giriş yapan kullanıcı kutlamayı yeniden görürdü.
class AcilisPopupKayitlari {
  AcilisPopupKayitlari._();

  static const String dogumGunuAnahtari = 'acilis_popup_dogum_gunu';
  static const String duyuruAnahtari = 'acilis_popup_duyurular';
  static const List<String> tumu = [dogumGunuAnahtari, duyuruAnahtari];

  /// Cihazda tutulan duyuru kaydı sınırı; eskiler düşer.
  static const int _duyuruKayitSiniri = 50;

  /// {uyeId: kutlandığı yıl}
  static Future<Map<String, dynamic>> _dogumGunleri() async =>
      await SecureStorageService.getValue<Map<String, dynamic>>(
          dogumGunuAnahtari) ??
      <String, dynamic>{};

  static Future<bool> dogumGunuKutlandiMi(int uyeId, int yil) async =>
      (await _dogumGunleri())['$uyeId'] == yil;

  static Future<void> dogumGunuKutlandi(int uyeId, int yil) async {
    final kayit = await _dogumGunleri();
    kayit['$uyeId'] = yil;
    await SecureStorageService.setValue(dogumGunuAnahtari, kayit);
  }

  /// ["userId:duyuruId", ...] — aynı cihazda başka hesap açılırsa onun
  /// popup'ını engellemesin diye kullanıcıya bağlı.
  static Future<List<String>> _duyurular() async {
    final liste =
        await SecureStorageService.getValue<List<dynamic>>(duyuruAnahtari);
    return liste?.map((e) => e.toString()).toList() ?? <String>[];
  }

  static Future<bool> duyuruGosterildiMi(int userId, int duyuruId) async =>
      (await _duyurular()).contains('$userId:$duyuruId');

  static Future<void> duyuruGosterildi(int userId, int duyuruId) async {
    final liste = await _duyurular();
    final anahtar = '$userId:$duyuruId';
    if (liste.contains(anahtar)) return;
    liste.add(anahtar);
    final kirpilmis = liste.length > _duyuruKayitSiniri
        ? liste.sublist(liste.length - _duyuruKayitSiniri)
        : liste;
    await SecureStorageService.setValue(duyuruAnahtari, kirpilmis);
  }
}
