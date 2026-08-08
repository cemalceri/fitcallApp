import 'dart:io' show Platform;

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/foundation.dart';

/// Rozeti fiilen yazan ve son değeri saklayan katman.
///
/// Platform kanalı testlerde çağrılamadığı için tek sınıfa toplandı;
/// [AppBadgeService.kanal] üzerinden sahtesiyle değiştirilebilir.
class RozetKanali {
  const RozetKanali();

  static const _kayitAnahtari = 'bildirim_rozet_sayisi';

  /// Simge rozetini günceller. 0 gönderilirse rozet kaldırılır.
  Future<void> rozetiYaz(int sayi) => AppBadgePlus.updateBadge(sayi);

  /// En son yazılan rozet değeri. Uygulama kapalıyken bildirim geldiğinde
  /// sunucuya gidilemediği için sayaç buradan devam ettirilir.
  Future<int> sonSayiyiOku() async =>
      await SecureStorageService.getValue<int>(_kayitAnahtari) ?? 0;

  Future<void> sonSayiyiYaz(int sayi) =>
      SecureStorageService.setValue<int>(_kayitAnahtari, sayi);
}

/// Okunmamış bildirim sayısını uygulama simgesindeki rozete yansıtır.
///
/// Tek giriş noktası `NotificationService.refreshUnreadCount`: sunucudan gelen
/// sayı hem uygulama içi zile hem buraya yazılır. Uygulama kapalıyken gelen
/// bildirimde API'ye gidilemediği için [artir] kullanılır; uygulama açılınca
/// gerçek değer rozeti düzeltir.
///
/// iOS'ta uygulama tamamen kapalıyken rozeti yalnızca APNs payload'ındaki
/// `badge` alanı günceller; backend tarafı `notification_tasks.py` içinde
/// bu alanı dolduruyor.
///
/// ANDROID'DE POZİTİF SAYI PLUGIN'E YAZILMAZ — yalnız sıfırlama gönderilir.
/// `app_badge_plus`, Xiaomi/Redmi/POCO'da (MIUI + HyperOS) rozeti "aktif
/// bildirim sayısı" üzerinden kuruyor: N için **N adet sahte bildirim**
/// gönderiyor (`MiUIBadge` → `NotificationBadgeHelper.updateMiuiBadgeHyperOs`;
/// başlık uygulama adı, gövde 1..N). Okunmamışı 15 olan kullanıcı uygulamayı
/// açtığında bildirim gölgesine "Binay Akademi / 1"… "/ 15" diye 15 satır
/// düşüyordu (2026-08-08, Redmi Note 11). Gerçek sayıyı zaten bildirimin
/// kendisi taşıyor — backend `notification_count`, mobil tarafta
/// `AndroidNotificationDetails.number` — dolayısıyla plugin'e ihtiyaç yok.
/// 0 gönderimi korunuyor: plugin o durumda bildirim üretmiyor, aksine
/// bıraktıklarını siliyor ve rozeti temizlemenin başka yolu yok.
class AppBadgeService {
  AppBadgeService._();

  @visibleForTesting
  static RozetKanali kanal = const RozetKanali();

  /// Pozitif rozet değeri plugin'e yazılabilir mi? Android'de hayır
  /// (bkz. sınıf açıklaması). Test edilebilsin diye alan.
  @visibleForTesting
  static bool pozitifRozetYazilir = !Platform.isAndroid;

  /// Rozeti [sayi] ile günceller ve değeri sonraki açılış için saklar.
  ///
  /// Saklanan değer platformdan bağımsız yazılır: arka plandaki bildirimin
  /// `number` alanını besleyen sayaç ([artir]) buradan devam ediyor.
  static Future<void> senkronla(int sayi) async {
    final deger = sayi < 0 ? 0 : sayi;
    try {
      await kanal.sonSayiyiYaz(deger);
      if (deger == 0 || pozitifRozetYazilir) {
        await kanal.rozetiYaz(deger);
      }
    } catch (_) {
      // Rozeti desteklemeyen launcher/platform: sessizce geçilir, rozet
      // olmaması uygulamanın çalışmasını etkilemez.
    }
  }

  /// Arka planda bildirim geldiğinde çağrılır: saklanan sayacı bir artırır ve
  /// yeni değeri döndürür (yerel bildirimin `number` alanı için).
  static Future<int> artir() async {
    var deger = 1;
    try {
      deger = (await kanal.sonSayiyiOku()) + 1;
    } catch (_) {
      // Kayıt okunamadıysa 1'den devam edilir.
    }
    await senkronla(deger);
    return deger;
  }

  /// Çıkışta rozeti kaldırır.
  static Future<void> temizle() => senkronla(0);
}
