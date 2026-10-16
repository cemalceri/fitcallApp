// lib/screens/1_common/program/talep_notu_kutusu.dart

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

/// Ders kayıt talebinin notu: talep listesinde ve talepten açılan formda
/// aynı görünür. Tutar ya da özel üye verisi içermez.
class TalepNotuKutusu extends StatelessWidget {
  final DersKayitTalebi talep;

  const TalepNotuKutusu({super.key, required this.talep});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: renk.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${talep.talepEdenAdi} · ders kayıt talebi notu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: renk.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            talep.aciklama,
            style: TextStyle(fontSize: 13.5, color: renk.onSurface),
          ),
        ],
      ),
    );
  }
}
