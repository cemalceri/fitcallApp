import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:flutter/material.dart';

/// Plan dışı katılımcı bildiriminin (OFIS_PLAN_DISI_KATILIM) detay özeti.
///
/// Bildirim gövdesi tek cümlelik akıcı bir metin — ofisin kimin eklendiğini
/// tek bakışta görmesi için aynı bilgi burada ders künyesi + kişi listesi
/// olarak ayrıştırılıyor. Veri backend'in `display_data` alanından geliyor:
/// `eklenenler` / `cikarilanlar` virgülle ayrılmış "Ad Soyad (üye)" dizgileri.
class PlanDisiBildirimOzeti extends StatelessWidget {
  final Map<String, dynamic> displayData;

  const PlanDisiBildirimOzeti({super.key, required this.displayData});

  @override
  Widget build(BuildContext context) {
    final eklenenler = _kisiler('eklenenler');
    final cikarilanlar = _kisiler('cikarilanlar');

    // Ders künyesi de yoksa gösterecek bir şey kalmıyor: gövde metni zaten var.
    if (eklenenler.isEmpty && cikarilanlar.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BildirimKompaktBaslikWidget(displayData: displayData),
        const SizedBox(height: 16),
        if (eklenenler.isNotEmpty)
          _KisiBolumu(
            baslik: 'Derse eklendi',
            icon: Icons.person_add_alt_1_rounded,
            renk: BildirimRenkleri.uyariTuruncu,
            kisiler: eklenenler,
          ),
        if (eklenenler.isNotEmpty && cikarilanlar.isNotEmpty)
          const SizedBox(height: 10),
        if (cikarilanlar.isNotEmpty)
          _KisiBolumu(
            baslik: 'Dersten çıkarıldı',
            icon: Icons.person_remove_alt_1_rounded,
            renk: BildirimRenkleri.hataKirmizi,
            kisiler: cikarilanlar,
          ),
      ],
    );
  }

  List<String> _kisiler(String anahtar) {
    final ham = displayData[anahtar]?.toString() ?? '';
    if (ham.trim().isEmpty) return const [];
    return ham
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _KisiBolumu extends StatelessWidget {
  final String baslik;
  final IconData icon;
  final Color renk;
  final List<String> kisiler;

  const _KisiBolumu({
    required this.baslik,
    required this.icon,
    required this.renk,
    required this.kisiler,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: renk),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: renk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...kisiler.map(
            (k) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                k,
                style: const TextStyle(
                  fontSize: 14,
                  color: BildirimRenkleri.yaziAna,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
