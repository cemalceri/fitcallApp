// lib/screens/1_common/widgets/profil_degistir_butonu.dart

import 'dart:convert';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Header'lardaki profil değiştirme butonu.
///
/// Üye, antrenör ve yönetici header'ları üç ayrı kopya taşıyordu (farklı ikon,
/// farklı renk); tek yerden gelsin diye buraya alındı. Birden fazla profili
/// olan kullanıcıya gösterilir, profil seçim ekranına götürür.
class ProfilDegistirButonu extends StatelessWidget {
  const ProfilDegistirButonu({super.key});

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
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () => _profilDegistir(context),
      tooltip: 'Profil değiştir',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.onSecondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.switch_account,
          size: 22,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
