// lib/screens/7_yonetici/dersler/widgets/ders_liste_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';

class DersListeItemWidget extends StatelessWidget {
  final DersListeItem ders;
  final VoidCallback? onTap;

  const DersListeItemWidget({
    super.key,
    required this.ders,
    this.onTap,
  });

  String _katilimciMetni() {
    final sayi = '${ders.katilimciSayisi} katılımcı';
    if (ders.katilimcilar.isEmpty) return sayi;
    final isimler = ders.katilimcilar.map((k) => k.adSoyad).take(2).join(', ');
    return '$sayi • $isimler';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Saat ve durum
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ders.durumRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      ders.saat,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ders.durumRenk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ders.durumRenk,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ders.kortAdi ?? 'Kort belirtilmedi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge dar alanda taşmasın diye küçülebilir
                        Flexible(
                          child: _DurumBadge(
                              durum: ders.durum, durumText: ders.durumText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sports_tennis,
                            size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ders.antrenorAdi ?? 'Antrenör belirtilmedi',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        // Sayı + isimler tek esnek metinde: yazı büyüse de Row
                        // taşmaz, fazlası ellipsis'e düşer.
                        Expanded(
                          child: Text(
                            _katilimciMetni(),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurumBadge extends StatelessWidget {
  final String durum;
  final String durumText;

  const _DurumBadge({required this.durum, required this.durumText});

  Color get _renk {
    switch (durum) {
      case 'tamamlandi':
        return Colors.green;
      case 'devam_ediyor':
        return Colors.blue;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        durumText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _renk,
        ),
      ),
    );
  }
}
