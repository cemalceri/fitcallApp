// lib/screens/1_common/widgets/profil_degistir_butonu.dart

import 'dart:convert';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
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
  /// Buton rengi; varsayılan header aksiyonlarındaki mor.
  final Color renk;

  const ProfilDegistirButonu({super.key, this.renk = const Color(0xFF8B5CF6)});

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
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: 'Profil değiştir',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _profilDegistir(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.swap_horiz_rounded, size: 22, color: renk),
            ),
          ),
        ),
      ),
    );
  }
}
