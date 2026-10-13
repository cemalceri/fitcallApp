// lib/screens/1_common/widgets/profil_degistir_butonu.dart

import 'dart:convert';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Header'lardaki profil değiştirme butonu.
///
/// Üye, antrenör ve yönetici header'ları üç ayrı kopya taşıyordu; tek yerden
/// gelsin diye buraya alındı. Görünüm yöneticide yapılan düzenlemeden geliyor
/// (7d86055): bildirim ziliyle aynı 42×42 kutu, tooltip ve renkli zemin —
/// üye/antrenördeki eski düz IconButton değil. Birden fazla profili olan
/// kullanıcıya gösterilir, profil seçim ekranına götürür.
class ProfilDegistirButonu extends StatelessWidget {
  /// Buton rengi; verilmezse temanın ana rengi.
  final Color? renk;

  const ProfilDegistirButonu({super.key, this.renk});

  /// Hesapta birden fazla profil varsa true — buton yalnız o zaman gösterilir.
  static Future<bool> gosterilmeliMi() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null) return false;
    return (jsonDecode(jsonStr) as List).length > 1;
  }

  Future<void> _profilDegistir(BuildContext context) async {
    HapticFeedback.lightImpact();
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null) return;

    final profiller = (jsonDecode(jsonStr) as List)
        .map((e) => KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaslikIkonButonu(
      ikon: Icons.swap_horiz_rounded,
      ipucu: 'Profil değiştir',
      renk: renk,
      onTap: () => _profilDegistir(context),
    );
  }
}
