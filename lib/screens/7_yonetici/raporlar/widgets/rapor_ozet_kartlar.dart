// lib/screens/7_yonetici/raporlar/widgets/rapor_ozet_kartlar.dart

import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';

class RaporOzetKartlar extends StatelessWidget {
  final List<RaporOzetKarti> data;

  const RaporOzetKartlar({super.key, required this.data});

  IconData _getIcon(String iconName) {
    switch (iconName) {
      // Sunucu "Toplam Ciro" için trending_up gönderiyor; eşlenmediği için
      // kartta bilgi (i) simgesi çıkıyordu.
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'event':
        return Icons.event;
      case 'people':
        return Icons.people;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Yükseklik yazı ölçeğiyle büyür: sabit 100 px, 1.3 ölçekte ve uzun
    // tutarda (satır kırılınca) kartı alttan taşırıyordu.
    final olcek = MediaQuery.textScalerOf(context).scale(1);

    return SizedBox(
      height: 60 + 40 * olcek,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.renkColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIcon(item.ikon),
                        size: 16,
                        color: item.renkColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tutar tek satır; sığmazsa küçülür (₺12.345.678).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.deger,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      item.baslik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
