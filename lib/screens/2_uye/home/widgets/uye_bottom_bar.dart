import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Üye ana sayfasının alt hızlı erişim barı.
///
/// 5 buton: Takvim · Geçmiş Ders · [merkez] QR Giriş · Bilgilerim · Hesabım.
/// Yalnızca ana sayfada gösterilir; butonlar ilgili sayfaları named route ile
/// açar (kalıcı sekme kabuğu değildir).
class UyeBottomBar extends StatelessWidget {
  const UyeBottomBar({super.key});

  void _git(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BarItem(
                icon: Icons.calendar_month_rounded,
                label: 'Takvim',
                color: const Color(0xFFF59E0B),
                onTap: () => _git(context, routeEnums[SayfaAdi.dersler]!),
              ),
              _BarItem(
                icon: Icons.history_rounded,
                label: 'Geçmiş',
                color: const Color(0xFF14B8A6),
                onTap: () =>
                    _git(context, routeEnums[SayfaAdi.uyeGecmisDersler]!),
              ),
              // Merkez: QR (vurgulu)
              _CenterQrButton(
                onTap: () => _git(context, routeEnums[SayfaAdi.qrKodKayit]!),
              ),
              _BarItem(
                icon: Icons.card_membership_rounded,
                label: 'Bilgilerim',
                color: const Color(0xFF6366F1),
                onTap: () => _git(context, routeEnums[SayfaAdi.uyelikPaket]!),
              ),
              _BarItem(
                icon: Icons.person_rounded,
                label: 'Hesabım',
                color: const Color(0xFF10B981),
                onTap: () => _git(context, routeEnums[SayfaAdi.profil]!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterQrButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterQrButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colorScheme.primary,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: colorScheme.primary.withValues(alpha: 0.5),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.qr_code_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'QR Giriş',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
