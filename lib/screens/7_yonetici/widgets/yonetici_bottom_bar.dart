// lib/screens/7_yonetici/widgets/yonetici_bottom_bar.dart

import 'package:fitcall/screens/7_yonetici/widgets/yonetici_qr_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici ana kabuğunun alt barı — üye alt barıyla aynı düzen.
///
/// 5 slot: Dashboard · Raporlar · [merkez] QR · Üyeler · Antrenörler.
/// Kenardaki 4 slot sekme değiştirir (seçili olan vurgulanır), merkez buton
/// QR işlemleri sayfasını açar. Eski `NavigationBar` 6 sekmede etiketleri
/// sıkıştırıp "Antrenörler"i alt satıra taşırdı; burada etiketler tek satır.
class YoneticiBottomBar extends StatelessWidget {
  /// Aktif sekme indeksi (YoneticiMainPage ile aynı sıralama).
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const YoneticiBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

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
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                color: const Color(0xFF6366F1),
                selected: selectedIndex == 0,
                onTap: () => _sekme(0),
              ),
              _BarItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                label: 'Raporlar',
                color: const Color(0xFF0EA5E9),
                selected: selectedIndex == 1,
                onTap: () => _sekme(1),
              ),
              // Merkez: QR (vurgulu)
              _CenterQrButton(onTap: () => showYoneticiQrSheet(context)),
              _BarItem(
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: 'Üyeler',
                color: const Color(0xFF10B981),
                selected: selectedIndex == 2,
                onTap: () => _sekme(2),
              ),
              _BarItem(
                icon: Icons.sports_tennis_outlined,
                selectedIcon: Icons.sports_tennis_rounded,
                label: 'Antrenörler',
                color: const Color(0xFFF59E0B),
                selected: selectedIndex == 3,
                onTap: () => _sekme(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sekme(int index) {
    HapticFeedback.lightImpact();
    onTabSelected(index);
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
    required this.selected,
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
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: selected ? color : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? color : colorScheme.onSurfaceVariant,
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
                child:
                    Icon(Icons.qr_code_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'QR İşlem',
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
