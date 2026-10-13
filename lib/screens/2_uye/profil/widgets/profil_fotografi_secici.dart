// lib/screens/2_uye/profil/widgets/profil_fotografi_secici.dart
//
// Üyenin kendi profil fotoğrafını eklemesi / değiştirmesi / kaldırması.
//
// Fotoğraf telefonda yalnız küçültülür (en uzun kenar 1200 px, JPEG %85);
// kareye kırpma sunucuda yapılır (ortadan), böylece her istemci aynı sonucu
// verir. 1200 px, sunucunun ürettiği 512 px kareye yeterli pay bırakıyor ve
// mobil veriden tasarruf ettiriyor. Kırpma ekranı bilerek yok: avatar her
// yerde daire ve küçük, yüz çoğunlukla ortada — ayrı bir yerel kırpma paketi
// ve platform kurulumu bu kazanca değmedi.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum ProfilFotoSecimi { kamera, galeri, kaldir }

/// Seçenek sayfası: fotoğraf çek / galeriden seç / (varsa) kaldır.
Future<ProfilFotoSecimi?> profilFotoSecimiSor(
  BuildContext context, {
  required bool fotoVar,
}) {
  return showModalBottomSheet<ProfilFotoSecimi>(
    context: context,
    builder: (c) => SafeArea(
      child: ProfilFotoSecenekleri(
        fotoVar: fotoVar,
        onSec: (s) => Navigator.pop(c, s),
      ),
    ),
  );
}

/// Seçenek sayfasının gövdesi (taşma testinde doğrudan çizilebilsin diye
/// ayrı).
class ProfilFotoSecenekleri extends StatelessWidget {
  final bool fotoVar;
  final ValueChanged<ProfilFotoSecimi> onSec;

  const ProfilFotoSecenekleri({
    super.key,
    required this.fotoVar,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final hata = context.renkler.hata;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.xs),
          child: Text('Profil fotoğrafı', style: context.metin.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.s),
          child: Text(
            'Antrenörünüz ve kulüp ekranlarında görünür.',
            style: context.metin.bodySmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Fotoğraf çek'),
          onTap: () => onSec(ProfilFotoSecimi.kamera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Galeriden seç'),
          onTap: () => onSec(ProfilFotoSecimi.galeri),
        ),
        if (fotoVar)
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: hata),
            title: Text('Fotoğrafı kaldır', style: TextStyle(color: hata)),
            onTap: () => onSec(ProfilFotoSecimi.kaldir),
          ),
        const SizedBox(height: Bosluk.s),
      ],
    );
  }
}

/// Sonuç: yeni adres (kaldırıldıysa null). Kullanıcı vazgeçtiyse
/// [ProfilFotoSonucu.degismedi].
class ProfilFotoSonucu {
  final bool degisti;
  final String? url;

  const ProfilFotoSonucu._(this.degisti, this.url);
  static const degismedi = ProfilFotoSonucu._(false, null);
  const ProfilFotoSonucu.yeni(String? url) : this._(true, url);
}

/// Seçilen işlemi yürütür: fotoğrafı alır, yükler, cihazdaki profili
/// günceller. [yukleniyor] fotoğraf seçildikten sonra, ağ isteği sürerken
/// true olur (avatar üstünde halka).
Future<ProfilFotoSonucu> profilFotografiIslemi(
  BuildContext context,
  ProfilFotoSecimi secim, {
  required ValueChanged<bool> yukleniyor,
  ImagePicker? secici,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void mesaj(String m) => messenger.showSnackBar(SnackBar(content: Text(m)));

  try {
    if (secim == ProfilFotoSecimi.kaldir) {
      if (!await _kaldirmaOnayi(context)) return ProfilFotoSonucu.degismedi;
      yukleniyor(true);
      await UyeApiService.profilFotografiKaldir();
      await _cihazdakiniGuncelle(null);
      mesaj('Profil fotoğrafı kaldırıldı.');
      return const ProfilFotoSonucu.yeni(null);
    }

    final dosya = await (secici ?? ImagePicker()).pickImage(
      source: secim == ProfilFotoSecimi.kamera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (dosya == null) return ProfilFotoSonucu.degismedi;

    yukleniyor(true);
    final baytlar = await dosya.readAsBytes();
    final url = await UyeApiService.profilFotografiYukle(
      baytlar: baytlar,
      dosyaAdi: dosya.name,
    );
    if (url == null || url.isEmpty) {
      // Sunucu başarı dönüp adresi vermezse (beklenmeyen yanıt) cihazdaki
      // fotoğrafı SİLMEYELİM: yoksa "güncellendi" denip avatar baş harflere
      // düşüyordu. Eski hâl korunur, kullanıcı yeniden dener.
      mesaj('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.');
      return ProfilFotoSonucu.degismedi;
    }
    await _cihazdakiniGuncelle(url);
    mesaj('Profil fotoğrafı güncellendi.');
    return ProfilFotoSonucu.yeni(url);
  } on ApiException catch (e) {
    mesaj(e.message);
    return ProfilFotoSonucu.degismedi;
  } on PlatformException catch (e) {
    // Kamera/galeri izni reddedildi ya da erişilemedi.
    mesaj(e.code.contains('access_denied') || e.code.contains('denied')
        ? 'Kamera veya fotoğraf izni verilmedi. Telefonun Ayarlar '
            'bölümünden izin verebilirsiniz.'
        : 'Fotoğraf alınamadı.');
    return ProfilFotoSonucu.degismedi;
  } catch (_) {
    // Dosya okunamadı vb.: halka takılı kalmasın, kullanıcı bilgilensin.
    mesaj('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.');
    return ProfilFotoSonucu.degismedi;
  } finally {
    yukleniyor(false);
  }
}

/// Sunucuda değişiklik yapıldıktan sonra cihazdaki profil kopyası. Burada
/// hata olursa işlem yine başarılı sayılır: kopya bir sonraki profil
/// seçiminde sunucudan tazelenir.
Future<void> _cihazdakiniGuncelle(String? url) async {
  try {
    await StorageService.profilFotografiniGuncelle(url);
  } catch (_) {}
}

Future<bool> _kaldirmaOnayi(BuildContext context) async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Fotoğraf kaldırılsın mı?'),
      content: const Text('Profilinizde yeniden baş harfleriniz görünür.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Vazgeç'),
        ),
        YikiciButon(
          etiket: 'Kaldır',
          onPressed: () => Navigator.pop(c, true),
        ),
      ],
    ),
  );
  return onay == true;
}
