// lib/screens/2_uye/home/widgets/uye_header.dart

import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fitcall/common/tarih_util.dart';

class UyeHeader extends StatelessWidget {
  final String uyeAdi;
  final bool hasMultipleProfiles;

  /// Ana hesap mı: alt profilde bakiye, paket ve bildirim sayfaları açılmaz;
  /// bunları anlatan rehberler listeden çıkar.
  final bool anaHesap;

  /// Sol üstteki menü (hamburger) butonuna dokununca çağrılır. null ise buton
  /// gizlenir.
  final VoidCallback? onMenuTap;

  const UyeHeader({
    super.key,
    required this.uyeAdi,
    required this.hasMultipleProfiles,
    this.anaHesap = true,
    this.onMenuTap,
  });

  String _getGreeting() {
    final hour = simdiKulup().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }


  /// Takım renginde başlık bandının içinde durur (bkz. UyeHomePage); yazı ve
  /// ikon renkleri banttan gelir.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      child: Row(
        children: [
          // Sol üst: Menü (hamburger)
          if (onMenuTap != null)
            Padding(
              padding: const EdgeInsets.only(right: Bosluk.s),
              child: OgrenmeHedefi(
                id: Hedef.genelKabukMenu,
                child: BaslikIkonButonu(
                  ikon: Icons.menu_rounded,
                  ipucu: 'Menü',
                  onTap: onMenuTap!,
                ),
              ),
            ),
          if (onMenuTap == null) const SizedBox(width: 8),

          // Sol: Karşılama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        uyeAdi.isNotEmpty ? uyeAdi : 'Hoş geldin',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🎾', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),

          // Sağ: Aksiyonlar
          Row(
            children: [
              // Bildirim zili
              const OgrenmeHedefi(
                id: Hedef.uyeBildirimZili,
                child: NotificationsBell(),
              ),

              // Profil değiştir
              if (hasMultipleProfiles) const ProfilDegistirButonu(),

              // "?" hep en sağda. Çıkış Ayarlar'da.
              OgrenmeButonu(
                sayfa: OgrenmeSayfasi.uyeAnaSayfa,
                sssRotasi: routeEnums[SayfaAdi.yardim]!,
                haric: {
                  if (!hasMultipleProfiles) 'uye.cocukDersleri',
                  if (!anaHesap) ...const {
                    'uye.borcum',
                    'uye.kalanHak',
                    'uye.bildirimZili',
                  },
                },
                kutulu: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
