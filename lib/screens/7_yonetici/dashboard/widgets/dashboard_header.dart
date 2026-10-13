// lib/screens/7_yonetici/dashboard/widgets/dashboard_header.dart

import 'dart:convert';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/common/tarih_util.dart';

class DashboardHeader extends StatefulWidget {
  /// Sol üstteki menü (hamburger) butonuna dokununca çağrılır. null ise buton
  /// gizlenir.
  final VoidCallback? onMenuTap;

  const DashboardHeader({super.key, this.onMenuTap});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _hasMultipleProfiles = false;
  String _yoneticiAdi = '';

  @override
  void initState() {
    super.initState();
    _checkProfiles();
    _adYukle();
  }

  Future<void> _checkProfiles() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr != null) {
      final profiles = (jsonDecode(jsonStr) as List)
          .map((e) =>
              KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (profiles.length > 1 && mounted) {
        setState(() => _hasMultipleProfiles = true);
      }
    }
  }

  Future<void> _adYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _yoneticiAdi = hesapGorunenAdi(profil.user));
  }

  String _getGreeting() {
    final hour = simdiKulup().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  /// Takım renginde başlık bandının içinde durur (bkz.
  /// YoneticiDashboardPage); yazı ve ikon renkleri banttan gelir.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sol üst: Menü (hamburger)
        if (widget.onMenuTap != null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.s),
            child: BaslikIkonButonu(
              ikon: Icons.menu_rounded,
              ipucu: 'Menü',
              onTap: widget.onMenuTap!,
            ),
          ),

        // Karşılama + kullanıcı adı
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
                      _yoneticiAdi.isNotEmpty ? _yoneticiAdi : 'Hoş geldiniz',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎾', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),

        // Sağ: Aksiyonlar (QR alt bara taşındı)
        Row(
          children: [
            const NotificationsBell(),
            if (_hasMultipleProfiles) const ProfilDegistirButonu(),
            // Çıkış — renkli başlıkta kırmızı değil; diğer butonlarla aynı.
            BaslikIkonButonu(
              ikon: Icons.logout_rounded,
              ipucu: 'Çıkış yap',
              onTap: () async {
                if (await cikisOnayla(context) && context.mounted) {
                  AuthService.logout(context);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
