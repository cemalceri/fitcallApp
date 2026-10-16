// lib/screens/1_common/acilis_popup/acilis_popuplari.dart

import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/dogum_gunu_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/duyuru_popup.dart';
import 'package:fitcall/screens/1_common/acilis_popup/widgets/surum_notu_popup.dart';
import 'package:fitcall/screens/1_common/neler_yeni_page.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_detay_sheet.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/acilis_popup_service.dart';
import 'package:fitcall/services/core/duyuru_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/core/surum_notu_service.dart';
import 'package:fitcall/services/notification/notification_fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Ana sayfa açılışındaki popup sırası: doğum günü → duyuru → sürüm notu.
///
/// Tetik profil seçimi değil kabuk (ana sayfa) açılışı: token geçerliyken
/// profil seçimi atlanıyor, oraya bağlansaydı popup çoğu açılışta hiç
/// çıkmazdı. Profil seçiminden sonra da kabuk açıldığı için o yol da kapsanır.
/// Kurallar: lib/services/core/acilis_popup_service.dart.
class AcilisPopuplari {
  AcilisPopuplari._();

  /// Bu süreçte sırası çalışmış profiller. Kabuk yeniden kurulsa da (ör.
  /// bildirimden dönüş) aynı açılışta ikinci kez popup çıkmaz; profil
  /// değiştirmek yeni bir giriş sayılır.
  static final Set<String> _calisanProfiller = {};

  /// Ana sayfa önce görünsün, popup ardından gelsin.
  static const Duration _gecikme = Duration(milliseconds: 700);

  static Future<void> calistir(BuildContext context) async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null) return;
    if (!_calisanProfiller.add('${profil.rol}:${profil.id}')) return;

    await Future.delayed(_gecikme);
    if (!context.mounted || !_ekranHazirMi(context)) return;

    // Açılış başına tek popup: doğum günü gösterildiyse duyuru sonraki açılışa.
    if (await _dogumGunu(context, profil)) return;
    if (!context.mounted) return;
    if (await _duyuru(context, profil)) return;
    if (!context.mounted) return;
    // Sürüm notu en sonda: son kullanma tarihi yok, kaçırılırsa Ayarlar >
    // "Neler yeni"de duruyor.
    await _surumNotu(context, profil);
  }

  /// Bildirim akışı sürüyorsa ya da kullanıcı başka sayfaya geçtiyse araya
  /// girilmez.
  static bool _ekranHazirMi(BuildContext context) {
    if (NotificationFCMService.instance.hasPendingNotification.value) {
      return false;
    }
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  static Future<bool> _dogumGunu(
      BuildContext context, KullaniciProfilModel profil) async {
    if (profil.rol != Roller.uye.name) return false;
    final uye = profil.uye ?? await StorageService.uyeBilgileriniGetir();
    final dogum = uye?.dogumTarihi;
    if (uye == null || dogum == null) return false;

    final bugun = simdiKulup();
    if (!dogumGunuMu(dogum, bugun)) return false;
    if (await AcilisPopupKayitlari.dogumGunuKutlandiMi(uye.id, bugun.year)) {
      return false;
    }
    // Kayıt gösterimden önce: uygulama popup açıkken kapanırsa tekrar çıkmasın.
    await AcilisPopupKayitlari.dogumGunuKutlandi(uye.id, bugun.year);

    if (!context.mounted) return false;
    await DogumGunuPopup.goster(context,
        ad: uye.adi.trim(), imza: profil.isletmeAdi);
    return true;
  }

  /// Duyuru popup'ı gösterildiyse true (sıra orada durur).
  ///
  /// Rol filtresi (üye + antrenör) KORUNUYOR: ofis ve yöneticinin duyuru
  /// popup'ı görmemesi bilinçli bir karar. Sürüm notu dört rolde de çıkar.
  static Future<bool> _duyuru(
      BuildContext context, KullaniciProfilModel profil) async {
    if (profil.rol != Roller.uye.name && profil.rol != Roller.antrenor.name) {
      return false;
    }

    DuyuruModel? duyuru;
    try {
      duyuru = (await DuyuruService.getPopupDuyuru()).data;
    } catch (_) {
      return false; // popup gösterilmezse bir şey kaybolmaz; carousel'de duruyor
    }
    if (duyuru == null || !popupYayindaMi(duyuru, simdiKulup())) return false;

    final userId = profil.user.id;
    if (await AcilisPopupKayitlari.duyuruGosterildiMi(userId, duyuru.id)) {
      return false;
    }
    if (!context.mounted || !_ekranHazirMi(context)) return false;

    // "Görüldü" gösterimle birlikte yazılır; kapatmak da detaya gitmek de
    // görüldü sayılır. Sunucu kaydı düşerse cihazdaki kayıt tekrar çıkmasını
    // engeller.
    await AcilisPopupKayitlari.duyuruGosterildi(userId, duyuru.id);
    DuyuruService.setDuyuruOkundu(
      duyuruId: duyuru.id,
      kaynak: 'popup',
      detayAcildi: false,
    ).catchError((_) => ApiResult<Map<String, dynamic>>(mesaj: ''));

    if (!context.mounted) return true;
    final detay = await DuyuruPopup.goster(context, duyuru);
    if (detay && context.mounted) {
      await DuyuruDetaySheet.ac(context, duyuru, kaynak: 'popup');
    }
    return true;
  }

  /// "Neler yeni?": kurulu sürümün, bu profile ait notu. Sürüm + rol başına
  /// bir kez. Gösterildiyse true.
  static Future<bool> _surumNotu(
      BuildContext context, KullaniciProfilModel profil) async {
    const roller = [
      Roller.uye,
      Roller.antrenor,
      Roller.ofis,
      Roller.yonetici,
    ];
    if (!roller.any((r) => r.name == profil.rol)) return false;

    final paket = await PackageInfo.fromPlatform();
    final surum = paket.version.trim();
    if (surum.isEmpty) return false;

    final userId = profil.user.id;
    if (await AcilisPopupKayitlari.surumNotuGosterildiMi(
        profil.rol, userId, surum)) {
      return false;
    }

    SurumNotuBlogu? blok;
    try {
      blok = (await SurumNotuService.getYenilikler(
        surum: surum,
        build: paket.buildNumber,
      )).data;
    } catch (_) {
      return false; // not kaçarsa Ayarlar > "Neler yeni"de duruyor
    }
    if (blok == null || blok.bos) return false;
    if (!context.mounted || !_ekranHazirMi(context)) return false;

    // Kayıt gösterimden önce: popup açıkken uygulama kapanırsa tekrar çıkmasın.
    await AcilisPopupKayitlari.surumNotuGosterildi(profil.rol, userId, surum);
    _gorunduBildir(blok.id, const []);

    final acilanlar = <int>{};
    if (!context.mounted) return true;
    final tumunuGor = await SurumNotuPopup.goster(
      context,
      blok,
      onMaddeAcildi: acilanlar.add,
    );
    if (acilanlar.isNotEmpty) {
      _gorunduBildir(blok.id, acilanlar.toList());
    }
    if (tumunuGor && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NelerYeniPage(surum: surum)),
      );
    }
    return true;
  }

  /// Ateşle-ve-bırak: ölçüm isteği düşse de cihazdaki kayıt popup'ı tekrar
  /// göstermez (duyuruda da aynı desen).
  static void _gorunduBildir(int rolBloguId, List<int> acilanMaddeler) {
    SurumNotuService.gorunduIsaretle(
      rolBloguId: rolBloguId,
      kaynak: 'popup',
      acilanMaddeler: acilanMaddeler,
    ).catchError((_) => ApiResult<Map<String, dynamic>>(mesaj: ''));
  }
}
