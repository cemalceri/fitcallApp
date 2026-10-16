// lib/screens/7_yonetici/dashboard/widgets/stat_card.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String baslik;
  final String deger;
  final String? altBaslik;
  final IconData ikon;
  final Color ikonRenk;
  final Color? ikonArkaPlanRenk;
  final double? degisimYuzdesi;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.baslik,
    required this.deger,
    this.altBaslik,
    required this.ikon,
    required this.ikonRenk,
    this.ikonArkaPlanRenk,
    this.degisimYuzdesi,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ikonArkaPlanRenk ?? ikonRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, size: 20, color: ikonRenk),
              ),
              // Dar kartta (iki sütun, 320 dp) rozet ikonla yan yana sığmazsa
              // taşmaz, küçülür.
              if (degisimYuzdesi != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildDegisimBadge(context),
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(fit: BoxFit.scaleDown, child: trailing!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Uzun tutar satıra sığmazsa kırılmaz, küçülür.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              deger,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            baslik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (altBaslik != null) ...[
            const SizedBox(height: 2),
            Text(
              altBaslik!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Artış/azalış rozeti: her temada aynı yeşil/kırmızı. Kap renkleriyle
  /// küçük yazı da 4.5:1'i geçer.
  Widget _buildDegisimBadge(BuildContext context) {
    final cs = context.cs;
    final isPositive = degisimYuzdesi! >= 0;
    final color = isPositive ? cs.onTertiaryContainer : cs.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive ? cs.tertiaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${degisimYuzdesi!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Çift içerikli stat card (ör: 24/28 Günlük Ders)
class StatCardDouble extends StatelessWidget {
  final String baslik;
  final String deger1;
  final String deger2;
  final String? altBaslik;
  final IconData ikon;
  final Color ikonRenk;
  final double? yuzde;

  const StatCardDouble({
    super.key,
    required this.baslik,
    required this.deger1,
    required this.deger2,
    this.altBaslik,
    required this.ikon,
    required this.ikonRenk,
    this.yuzde,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ikonRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, size: 20, color: ikonRenk),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: deger1,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: '/$deger2',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            baslik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (altBaslik != null) ...[
            const SizedBox(height: 2),
            Text(
              altBaslik!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
