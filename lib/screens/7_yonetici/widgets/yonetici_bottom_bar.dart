// lib/screens/7_yonetici/widgets/yonetici_bottom_bar.dart

import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yönetici kabuğunun alt barı — üye/antrenör/ofis kabuklarıyla aynı bileşen.
///
/// 4 sekme + merkezde QR. Dersler bara alınmadı (kullanıcı kararı); sol menünün
/// en üstündeki "Ders yönetimi" bölümünde. O sekmedeyken barda hiçbir sekme
/// seçili görünmez — konum sol menüde işaretlidir.
///
/// Merkez buton doğrudan QR Oluştur'u açar: doğrulama bir ön büro işlemi ve
/// ofis kabuğuna taşındı; yöneticide kalan tek QR işi kendi tesis geçişi ve
/// misafir daveti.
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
      onMerkez: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, routeEnums[SayfaAdi.qrKodKayit]!);
      },
      merkezEtiket: 'QR Oluştur',
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
