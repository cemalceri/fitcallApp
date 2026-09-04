// lib/screens/8_ofis/widgets/ofis_bottom_bar.dart

import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/1_common/widgets/qr_islem_sheet.dart';
import 'package:flutter/material.dart';

/// Ofis kabuğunun alt barı — üye/antrenör/yönetici kabuklarıyla aynı bileşen.
///
/// 4 sekme + merkezde QR. Ofisin günlük işi bu dört ekranda bitiyor:
/// programda ders açıp iptal eder, gün listesinden takip eder, üyeyi arar,
/// bildirimlerden kendisine düşen kararları görür. Merkezdeki QR hem doğrulama
/// (kapıdaki iş) hem oluşturma (kendi geçişi/misafiri) için ortak sayfayı açar.
class OfisBottomBar extends StatelessWidget {
  /// Aktif sekme indeksi (OfisMainPage ile aynı sıralama).
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const OfisBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return KabukAltBar(
      aktifIndeks: selectedIndex,
      onSekme: onTabSelected,
      onMerkez: () => showQrIslemSheet(context),
      merkezEtiket: 'QR İşlem',
      sekmeler: const [
        KabukSekmesi(
          ikon: Icons.grid_view_outlined,
          seciliIkon: Icons.grid_view_rounded,
          etiket: 'Program',
        ),
        KabukSekmesi(
          ikon: Icons.event_outlined,
          seciliIkon: Icons.event_rounded,
          etiket: 'Dersler',
        ),
        KabukSekmesi(
          ikon: Icons.people_outline_rounded,
          seciliIkon: Icons.people_rounded,
          etiket: 'Üyeler',
        ),
        KabukSekmesi(
          ikon: Icons.notifications_outlined,
          seciliIkon: Icons.notifications_rounded,
          etiket: 'Bildirim',
        ),
      ],
    );
  }
}
