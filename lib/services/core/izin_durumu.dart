// lib/services/core/izin_durumu.dart
//
// Cihaz izinlerinin backend'e gönderilen metin karşılıkları (auths.IzinDurumu)
// ve "bu izni daha önce sorduk mu" damgası.
//
// permission_handler iOS'ta "henüz sorulmadı" ile "reddedildi"yi AYIRT ETMİYOR,
// ikisine de `denied` diyor; Android'de de ilk sorudan önceki durum `denied`.
// Bu yüzden panelde hiç sorulmamış kamera/takvim izinleri "Reddedildi" olarak
// görünüyordu (2026-09-04: iOS'ta 189 cihazın 189'u böyleydi). Çözüm: izni
// tetikleyen ekran [IzinSorgusu.isaretle] ile damga bırakır, damga yoksa
// `denied` 'sorulmadi' diye raporlanır.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitcall/services/core/storage_service.dart';

/// Backend'in `IzinDurumu.CHOICES` değerleri. Tanınmayan değer sunucuda
/// 'bilinmiyor'a çekilir, o yüzden buradaki metinler birebir eşleşmeli.
class IzinDurumu {
  IzinDurumu._();

  static const izinli = 'izinli';
  static const reddedildi = 'reddedildi';
  static const kaliciRed = 'kalici_red';
  static const sorulmadi = 'sorulmadi';
  static const gecici = 'gecici';
  static const kisitli = 'kisitli';
  static const uygulanamaz = 'uygulanamaz';
  static const bilinmiyor = 'bilinmiyor';
}

/// Damga anahtarları. Oturum verisi değiller — çıkışta silinmemeleri için
/// [StorageService.clearAll] bunları koruyor.
class IzinAnahtari {
  IzinAnahtari._();

  static const bildirim = 'izin_soruldu_bildirim';
  static const kamera = 'izin_soruldu_kamera';
  static const takvim = 'izin_soruldu_takvim';

  static const tumu = [bildirim, kamera, takvim];
}

/// İzin sorma damgası. İzni tetikleyen ekran (QR okuyucu, takvime ekleme,
/// bildirim izni isteme) sistem penceresini açmadan hemen önce çağırır.
class IzinSorgusu {
  IzinSorgusu._();

  static Future<void> isaretle(String anahtar) async {
    try {
      await SecureStorageService.setValue<String>(anahtar, '1');
    } catch (_) {
      // Damga yazılamazsa izin yine de sorulur; en kötü ihtimalle panelde
      // 'sorulmadi' görünür. Akışı kesmeye değmez.
    }
  }

  static Future<bool> soruldumu(String anahtar) async {
    try {
      return await SecureStorageService.getValue<String>(anahtar) == '1';
    } catch (_) {
      return false;
    }
  }
}

/// iOS bildirim izni: "hiç sorulmadı" ile "reddedildi"yi yalnız Firebase ayırt
/// ediyor, bu yüzden orada damgaya gerek yok.
String bildirimIzniMetni(AuthorizationStatus durum) {
  switch (durum) {
    case AuthorizationStatus.authorized:
      return IzinDurumu.izinli;
    case AuthorizationStatus.denied:
      return IzinDurumu.reddedildi;
    case AuthorizationStatus.notDetermined:
      return IzinDurumu.sorulmadi;
    case AuthorizationStatus.provisional:
      return IzinDurumu.gecici;
  }
}

/// permission_handler durumunu backend değerine eşler. [soruldu] false ise
/// `denied` "reddedildi" değil "sorulmadi" demektir (bkz. dosya başlığı).
String izinMetni(PermissionStatus durum, {required bool soruldu}) {
  switch (durum) {
    case PermissionStatus.granted:
      return IzinDurumu.izinli;
    case PermissionStatus.denied:
      return soruldu ? IzinDurumu.reddedildi : IzinDurumu.sorulmadi;
    case PermissionStatus.permanentlyDenied:
      return IzinDurumu.kaliciRed;
    case PermissionStatus.restricted:
    case PermissionStatus.limited:
      return IzinDurumu.kisitli;
    case PermissionStatus.provisional:
      return IzinDurumu.gecici;
  }
}
