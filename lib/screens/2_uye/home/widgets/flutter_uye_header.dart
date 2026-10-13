// lib/screens/2_uye/home/widgets/uye_header.dart

import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/tarih_util.dart';

class UyeHeader extends StatelessWidget {
  final String uyeAdi;
  final bool hasMultipleProfiles;

  /// Sol üstteki menü (hamburger) butonuna dokununca çağrılır. null ise buton
  /// gizlenir.
  final VoidCallback? onMenuTap;

  const UyeHeader({
    super.key,
    required this.uyeAdi,
    required this.hasMultipleProfiles,
    this.onMenuTap,
  });

  String _getGreeting() {
    final hour = simdiKulup().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Future<void> _logout(BuildContext context) async {
    if (await cikisOnayla(context) && context.mounted) {
      AuthService.logout(context);
    }
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
              child: BaslikIkonButonu(
                ikon: Icons.menu_rounded,
                ipucu: 'Menü',
                onTap: onMenuTap!,
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
              const NotificationsBell(),

              // Profil değiştir
              if (hasMultipleProfiles) const ProfilDegistirButonu(),

              // Çıkış — renkli başlıkta kırmızı değil; diğer butonlarla aynı.
              BaslikIkonButonu(
                ikon: Icons.logout_rounded,
                ipucu: 'Çıkış yap',
                onTap: () => _logout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
