// lib/screens/7_yonetici/widgets/yonetici_bottom_bar.dart

import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_qr_sheet.dart';
import 'package:flutter/material.dart';

/// Yönetici kabuğunun alt barı — üye/antrenör kabuğuyla aynı bileşen.
///
/// 4 sekme + merkezde QR. Dersler ve Haftalık Program bara alınmadı (kullanıcı
/// kararı); ikisi de sol menünün en üstündeki "Ders yönetimi" bölümünde.
/// O sekmelerdeyken barda hiçbir sekme seçili görünmez — konum sol menüde
/// işaretlidir.
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
    return KabukAltBar(
      aktifIndeks: selectedIndex,
      onSekme: onTabSelected,
      onMerkez: () => showYoneticiQrSheet(context),
      merkezEtiket: 'QR İşlem',
      sekmeler: const [
        KabukSekmesi(
          ikon: Icons.dashboard_outlined,
          seciliIkon: Icons.dashboard_rounded,
          etiket: 'Dashboard',
        ),
        KabukSekmesi(
          ikon: Icons.bar_chart_outlined,
          seciliIkon: Icons.bar_chart_rounded,
          etiket: 'Raporlar',
        ),
        KabukSekmesi(
          ikon: Icons.people_outline_rounded,
          seciliIkon: Icons.people_rounded,
          etiket: 'Üyeler',
        ),
        KabukSekmesi(
          ikon: Icons.sports_tennis_outlined,
          seciliIkon: Icons.sports_tennis_rounded,
          etiket: 'Antrenörler',
        ),
      ],
    );
  }
}
