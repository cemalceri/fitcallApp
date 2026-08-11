// lib/services/core/ekran_parlaklik_service.dart
//
// QR kodun kapıdaki okuyucu tarafından okunabilmesi için ekranı geçici olarak
// en parlak seviyeye alır, sayfadan çıkılınca eski haline döndürür.
//
// Native taraf (MainActivity.kt / AppDelegate.swift) bilerek izin gerektirmeyen
// API'leri kullanır:
//   Android — yalnızca uygulama penceresinin parlaklığı (WRITE_SETTINGS gerekmez)
//   iOS     — UIScreen.main.brightness (ayrı bir izin yok)
// Yine de her çağrı hataya karşı korumalıdır: platform desteklemiyorsa veya
// çağrı başarısız olursa istisna fırlatılmaz, sayfa mevcut parlaklıkla çalışmaya
// devam eder.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EkranParlaklikService {
  static const MethodChannel _kanal = MethodChannel('fitcall/ekran_parlaklik');

  /// Ekranı maksimum parlaklığa alır. Başarılıysa true döner.
  static Future<bool> maksimumaAl() async {
    try {
      return await _kanal.invokeMethod<bool>('maksimumaAl') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Parlaklığı kullanıcının önceki ayarına döndürür.
  static Future<bool> eskiHalineDondur() async {
    try {
      return await _kanal.invokeMethod<bool>('eskiHalineDondur') ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Bir sayfanın yaşam döngüsüne bağlı parlaklık kontrolü.
///
/// Kullanım (State içinde):
///   final _parlaklik = EkranParlaklikKontrolu();
///   initState  → _parlaklik.baslat();
///   dispose    → _parlaklik.birak();
///
/// Uygulama arka plana alınırsa parlaklık geri verilir (özellikle iOS'ta sistem
/// parlaklığı değiştiği için önemli), öne gelince tekrar uygulanır.
///
/// [maksimumda], parlaklığın gerçekten artırılıp artırılamadığını bildirir;
/// arayüz buna göre farklı bir ipucu gösterebilir.
class EkranParlaklikKontrolu with WidgetsBindingObserver {
  final ValueNotifier<bool> maksimumda = ValueNotifier<bool>(false);

  bool _aktif = false;
  bool _atildi = false;

  Future<void> baslat() async {
    if (_aktif || _atildi) return;
    _aktif = true;
    WidgetsBinding.instance.addObserver(this);
    await _uygula();
  }

  /// Sayfadan çıkarken çağrılır: parlaklığı geri alır ve dinleyiciyi bırakır.
  Future<void> birak() async {
    if (_atildi) return;
    _atildi = true;
    _aktif = false;
    WidgetsBinding.instance.removeObserver(this);
    await EkranParlaklikService.eskiHalineDondur();
    maksimumda.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_aktif) return;
    if (state == AppLifecycleState.resumed) {
      _uygula();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // inactive bilinçli olarak kapsam dışı: paylaşım sayfası/bildirim
      // merkezi gibi anlık durumlarda parlaklığın yanıp sönmesini önler.
      _geriAl();
    }
  }

  Future<void> _uygula() async {
    final sonuc = await EkranParlaklikService.maksimumaAl();
    if (_atildi || !_aktif) {
      // Çağrı sürerken sayfadan çıkıldıysa parlaklığı tekrar geri ver.
      await EkranParlaklikService.eskiHalineDondur();
      return;
    }
    maksimumda.value = sonuc;
  }

  Future<void> _geriAl() async {
    await EkranParlaklikService.eskiHalineDondur();
    if (_atildi) return;
    maksimumda.value = false;
  }
}
