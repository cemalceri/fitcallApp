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

  /// Panoda 2 × 2 dönem kartları (bkz. [StatCardsGrid]); Raporlar'da özet
  /// kartlar + ciro + tahsilat.
  final Widget child;

  /// Yüklenirken çizilecek iskelet bloklarının yükseklikleri. Verilmezse
  /// panonun 2 × 2 kart iskeleti.
  final List<double>? iskeletYukseklikleri;

  const DonemKutusu({
    super.key,
    required this.seciliDonem,
    required this.onDonemChanged,
    required this.yukleniyor,
    required this.child,
    this.iskeletYukseklikleri,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final kartBoyu = StatCardsGrid.kartYuksekligi(context);
    return DonemCercevesi(
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
          if (yukleniyor && iskeletYukseklikleri != null)
            BlokIskeleti(yukseklikler: iskeletYukseklikleri!)
          else if (yukleniyor)
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

/// Dönem kutusu ve dönem gruplarının ortak çerçevesi: yüzey zemin, ana
/// renkte ince kenar. Etkilenen içeriği seçiciyle görsel olarak birleştirir.
class DonemCercevesi extends StatelessWidget {
  final Widget child;

  const DonemCercevesi({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

/// Seçicisi olmayan ama aynı döneme bağlı ikinci grup (Raporlar: doluluk,
/// kortlar, antrenörler). Başlıkta seçili günler yazar: hangi dönemi
/// gösterdiği seçiciye bakmadan da okunur.
class DonemGrubu extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final DonemFiltresi donem;
  final bool yukleniyor;
  final List<double> iskeletYukseklikleri;
  final Widget child;

  const DonemGrubu({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.donem,
    required this.yukleniyor,
    required this.iskeletYukseklikleri,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return DonemCercevesi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(ikon, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  baslik,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleSmall,
                ),
              ),
              const SizedBox(width: Bosluk.s),
              Icon(Icons.date_range_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  donem.aralikMetni(bugunKulup()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          if (yukleniyor)
            BlokIskeleti(yukseklikler: iskeletYukseklikleri)
          else
            child,
        ],
      ),
    );
  }
}

/// Alt alta bloklardan oluşan iskelet; toplam yüksekliği baştan sabit
/// (gecikme süresinde kutu çökmesin).
class BlokIskeleti extends StatelessWidget {
  final List<double> yukseklikler;

  const BlokIskeleti({super.key, required this.yukseklikler});

  @override
  Widget build(BuildContext context) {
    final toplam = yukseklikler.fold<double>(0, (a, b) => a + b) +
        12.0 * (yukseklikler.length - 1);
    return SizedBox(
      height: toplam,
      child: IskeletGecikmeli(
        child: Parilti(
          child: Column(
            children: [
              for (final (i, h) in yukseklikler.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                IskeletKutu(yukseklik: h, yaricap: Yaricap.l),
              ],
            ],
          ),
        ),
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
