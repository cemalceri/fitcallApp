// lib/screens/2_uye/home/widgets/uye_ozet_serit.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/2_uye/uye_home_ozet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Ana sayfa üst özet şeridi: Bakiye / Kalan Hak / Telafi
class UyeOzetSerit extends StatelessWidget {
  final UyeOzetModel? ozet;
  final bool isLoading;

  const UyeOzetSerit({super.key, this.ozet, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (!isLoading && ozet == null) {
      // Veri alınamadıysa şerit gizlenir (yanlış değer göstermek yerine)
      return const SizedBox.shrink();
    }

    final bakiye = ozet?.bakiye ?? 0.0;
    final bakiyeRenk = bakiye < 0
        ? const Color(0xFFEF4444) // borç: kırmızı
        : bakiye > 0
            ? const Color(0xFF10B981) // alacak: yeşil
            : Theme.of(context).colorScheme.onSurfaceVariant; // sıfır: gri
    final tutarFmt = NumberFormat('#,##0', 'tr_TR');

    return Row(
      children: [
        Expanded(
          child: _OzetKart(
            isLoading: isLoading,
            icon: Icons.account_balance_wallet_outlined,
            color: bakiyeRenk,
            etiket: bakiye < 0 ? 'Borç' : 'Bakiye',
            deger: '${tutarFmt.format(bakiye.abs())} ₺',
            route: routeEnums[SayfaAdi.muhasebe]!,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OzetKart(
            isLoading: isLoading,
            icon: Icons.confirmation_number_outlined,
            color: const Color(0xFF8B5CF6),
            etiket: 'Kalan Haklarım',
            deger: ozet?.kalanPaketHak != null
                ? tutarFmt.format(ozet!.kalanPaketHak)
                : '—',
            route: routeEnums[SayfaAdi.uyelikPaket]!,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OzetKart(
            isLoading: isLoading,
            icon: Icons.event_repeat_rounded,
            color: const Color(0xFF6366F1),
            etiket: 'Telafi Derslerim',
            deger: '${ozet?.aktifTelafi ?? 0}',
            route: routeEnums[SayfaAdi.telafiHaklari]!,
          ),
        ),
      ],
    );
  }
}

class _OzetKart extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  final Color color;
  final String etiket;
  final String deger;
  final String route;

  const _OzetKart({
    required this.isLoading,
    required this.icon,
    required this.color,
    required this.etiket,
    required this.deger,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              isLoading
                  ? Container(
                      width: 44,
                      height: 16,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      deger,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                etiket,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
