// lib/screens/1_common/ders_listesi/widgets/ders_istatistik_kartlar.dart
//
// Günün ders sayıları (üye Takvim sekmesi ve yönetici Dersler sayfası).
// Renkler `ListeTonu` üzerinden: önceden `Colors.blue/green/orange/purple/red`
// sabitleriyle çiziliyordu ve `surface` zeminde kontrast eşiğin altına
// düşüyordu (turuncu 2,16 · yeşil 2,81 · mavi 3,12; koyu modda mor 2,99).

import 'package:flutter/material.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';

class DersIstatistikKartlar extends StatelessWidget {
  final DersIstatistik data;

  const DersIstatistikKartlar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final kartlar = <(String, String, ListeTonu)>[
      ('Toplam', data.bugunDers.toString(), ListeTonu.bilgi),
      ('Tamamlandı', data.tamamlanan.toString(), ListeTonu.basari),
      ('Devam', data.devamEden.toString(), ListeTonu.uyari),
      ('Bekliyor', data.bekleyen.toString(), ListeTonu.vurgu),
      ('İptal', data.iptal.toString(), ListeTonu.hata),
    ];

    return Row(
      children: [
        for (final (etiket, deger, ton) in kartlar) ...[
          if (etiket != kartlar.first.$1) const SizedBox(width: 6),
          Expanded(
            child: _MiniStatCard(label: etiket, value: deger, ton: ton),
          ),
        ],
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final ListeTonu ton;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.ton,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.cs;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ton.on(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
