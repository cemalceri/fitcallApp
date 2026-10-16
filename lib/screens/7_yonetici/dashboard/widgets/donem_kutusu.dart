// lib/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart';
import 'package:flutter/material.dart';

/// Panonun dönem kutusu: dönem seçimi + seçili günler + yalnız o seçimle
/// değişen kartlar tek çerçevede.
///
/// Önceden seçici başlık bandındaydı ve altındaki kartların bir kısmı
/// (aktif üye, toplam alacak, haftalık grafik, günün özeti) dönemle hiç
/// değişmiyordu; hangisinin etkilendiği görünmüyordu (kullanıcı kararı
/// 2026-10-16, "A: dönem kutusu").
class DonemKutusu extends StatelessWidget {
  final DonemFiltresi seciliDonem;
  final ValueChanged<DonemFiltresi> onDonemChanged;

  /// Dönem değişti, yeni veri bekleniyor: kartların yerinde aynı yükseklikte
  /// iskelet durur, kutu boyu oynamaz.
  final bool yukleniyor;

  /// 2 × 2 dönem kartları (bkz. [StatCardsGrid] / [PanoKartGrubu.donem]).
  final Widget child;

  const DonemKutusu({
    super.key,
    required this.seciliDonem,
    required this.onDonemChanged,
    required this.yukleniyor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final kartBoyu = StatCardsGrid.kartYuksekligi(context);
    return Container(
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodFilterTabs(
            seciliDonem: seciliDonem,
            onDonemChanged: onDonemChanged,
            yuzeyde: true,
          ),
          const SizedBox(height: Bosluk.s),
          Row(
            children: [
              Icon(Icons.date_range_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  seciliDonem.aralikMetni(bugunKulup()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          if (yukleniyor)
            SizedBox(
              height: kartBoyu * 2 + 12,
              child: IskeletGecikmeli(
                child: Parilti(
                  child: Column(
                    children: [
                      for (final ust in [0.0, 12.0]) ...[
                        SizedBox(height: ust),
                        Row(
                          children: [
                            Expanded(child: IskeletKutu(yukseklik: kartBoyu)),
                            const SizedBox(width: 12),
                            Expanded(child: IskeletKutu(yukseklik: kartBoyu)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

/// Panoda kutunun altındaki, dönemden bağımsız bölümlerin etiketi
/// ("Şu an", "Bu haftanın günleri", "Bugün").
class PanoBolumEtiketi extends StatelessWidget {
  final IconData ikon;
  final String etiket;

  const PanoBolumEtiketi({super.key, required this.ikon, required this.etiket});

  @override
  Widget build(BuildContext context) {
    final renk = context.cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: Bosluk.s),
      child: Row(
        children: [
          Icon(ikon, size: 16, color: renk),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              etiket,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.labelLarge?.copyWith(color: renk),
            ),
          ),
        ],
      ),
    );
  }
}
