// lib/screens/1_common/hakedis/widgets/hakedis_stil.dart
//
// Hakediş ekranlarının ortak görsel dili: durum renkleri, ikonları ve
// yükleme/hata/boş gövdeleri. Üç sayfa da aynı sözlüğü kullansın diye tek
// yerde toplandı.
//
// RENK KULLANIMI — her durum rengi tek bir `HakedisRenk` seti üretir:
// dolgu / kenar / metin üçlüsü birlikte gelir. Doğrudan `ana.withValues(...)`
// yazmayın: ilk sürümde her şey %10 alfa yıkamasıydı ve ekran soluk çıkıyordu.
// Metin rengi dolgunun üstünde okunacak koyulukta ayrıca hesaplanır, koyu
// temada ise açılır.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';

/* -------------------------------------------------------------------------- */
/*                              RENK PALETİ                                   */
/* -------------------------------------------------------------------------- */

/// Hakediş alacak — emerald
const Color hakedisYesil = Color(0xFF10B981);

/// Karar bekleyen — amber
const Color hakedisTuruncu = Color(0xFFF59E0B);

/// Hakediş dışı / nötr — slate
Color hakedisGri = const Color(0xFF8C8C8C);

/// Plan dışı katılımcı — mavi
const Color hakedisMavi = Color(0xFF3B82F6);

/// Katılmadı / iptal — kırmızı
const Color hakedisKirmizi = Color(0xFFEF4444);

/// Bir durumun dolgu + kenar + metin üçlüsü.
class HakedisRenk {
  /// Tam güçlü vurgu — ikon, nokta, ilerleme çubuğu.
  final Color ana;

  /// Rengin üstüne oturduğu yumuşak dolgu.
  final Color dolgu;

  /// Dolgunun kenarı — kutuyu zeminden ayırır.
  final Color kenar;

  /// Dolgu üstünde okunan yazı rengi.
  final Color metin;

  const HakedisRenk({
    required this.ana,
    required this.dolgu,
    required this.kenar,
    required this.metin,
  });
}

/// [taban] renginden temaya uygun dolgu/kenar/metin üretir.
HakedisRenk hakedisRenkSeti(BuildContext context, Color taban) {
  final karanlik = Theme.of(context).brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(taban);

  if (karanlik) {
    return HakedisRenk(
      ana: hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
      dolgu: taban.withValues(alpha: 0.20),
      kenar: taban.withValues(alpha: 0.42),
      metin: hsl.withLightness(0.80).withSaturation(0.55).toColor(),
    );
  }

  return HakedisRenk(
    ana: taban,
    dolgu: taban.withValues(alpha: 0.11),
    kenar: taban.withValues(alpha: 0.30),
    // Doygun renkler beyaz üstünde okunmuyor; metin için koyulaştırılıyor.
    metin: hsl.withLightness(0.30).toColor(),
  );
}

/// Durum kodunun taban rengi.
Color hakedisTabanRengi(String durum) {
  switch (durum) {
    case HakedisDurumu.hakedis:
      return hakedisYesil;
    case HakedisDurumu.bekliyor:
      return hakedisTuruncu;
    default:
      return hakedisGri;
  }
}

/// Durum kodunun tam renk seti.
HakedisRenk hakedisRengi(BuildContext context, String durum) =>
    hakedisRenkSeti(context, hakedisTabanRengi(durum));

IconData hakedisIkonu(String durum) {
  switch (durum) {
    case HakedisDurumu.hakedis:
      return Icons.check_circle_rounded;
    case HakedisDurumu.bekliyor:
      return Icons.schedule_rounded;
    default:
      return Icons.remove_circle_outline_rounded;
  }
}

IconData hakedisRolIkonu(String rol) => rol == HakedisRolu.yardimci
    ? Icons.groups_rounded
    : Icons.sports_tennis_rounded;

/// Katılım durumunun taban rengi.
Color katilimTabanRengi(HakedisKatilimci katilimci) {
  if (katilimci.planDisiMi) return hakedisMavi;
  if (katilimci.katildi) return hakedisYesil;
  if (katilimci.katilmadi) return hakedisKirmizi;
  return hakedisGri;
}

IconData katilimIkonu(HakedisKatilimci katilimci) {
  if (katilimci.planDisiMi) return Icons.person_add_alt_1_rounded;
  if (katilimci.katildi) return Icons.check_rounded;
  if (katilimci.katilmadi) return Icons.close_rounded;
  return Icons.remove_rounded;
}

/* -------------------------------------------------------------------------- */
/*                            ORTAK KART KABUĞU                               */
/* -------------------------------------------------------------------------- */

/// Ekranlardaki beyaz kartların ortak kabuğu — aynı köşe/kenar/gölge.
class HakedisKart extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const HakedisKart({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final karanlik = Theme.of(context).brightness == Brightness.dark;

    final govde = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: karanlik ? renk.surfaceContainerLow : renk.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: karanlik
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return govde;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: govde,
      ),
    );
  }
}

/// Küçük renkli rozet — "İptal edildi", "plan dışı" gibi kısa etiketler.
class HakedisRozet extends StatelessWidget {
  final String metin;
  final IconData? ikon;
  final Color taban;

  const HakedisRozet({
    super.key,
    required this.metin,
    required this.taban,
    this.ikon,
  });

  @override
  Widget build(BuildContext context) {
    final r = hakedisRenkSeti(context, taban);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: r.dolgu,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.kenar),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 13, color: r.metin),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              metin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: r.metin,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                        YÜKLEME / HATA / BOŞ GÖVDE                          */
/* -------------------------------------------------------------------------- */

/// Yükleme / hata / boş durumların ortak gövdesi.
///
/// Sayfalar bunu `Expanded` içinde kullanır; hata halinde [onTekrarDene] ile
/// yeniden yükleme sunar.
class HakedisDurumGovdesi extends StatelessWidget {
  final bool yukleniyor;
  final String? hata;
  final bool bosMu;
  final String bosMesaj;
  final IconData bosIkon;
  final VoidCallback? onTekrarDene;
  final WidgetBuilder icerik;

  const HakedisDurumGovdesi({
    super.key,
    required this.yukleniyor,
    required this.hata,
    required this.bosMu,
    required this.icerik,
    this.bosMesaj = 'Kayıt bulunamadı',
    this.bosIkon = Icons.inbox_rounded,
    this.onTekrarDene,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    if (yukleniyor) {
      return const IskeletListe();
    }

    if (hata != null) {
      final r = hakedisRenkSeti(context, hakedisKirmizi);
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: r.dolgu,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.error_outline_rounded, size: 30, color: r.metin),
              ),
              const SizedBox(height: 16),
              Text(
                hata!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: renk.onSurfaceVariant),
              ),
              if (onTekrarDene != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onTekrarDene,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (bosMu) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: renk.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(bosIkon, size: 30, color: renk.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Text(
                bosMesaj,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: renk.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return icerik(context);
  }
}
