// lib/screens/1_common/ayarlar/widgets/renk_temasi_secici.dart
//
// Ayarlar > Görünüm: renk teması karoları.
//
// Her karo o temanın küçük bir önizlemesini çizer (sayfa yıkaması, kimlik
// yüzeyi ve şeridi, ana renk) — kullanıcı seçmeden önce nasıl görüneceğini
// görür. Seçim anında uygulanır, geri almak tek dokunuş. Önizleme o anki moda
// (açık/koyu) göre çizilir.
//
// Veri dışarıdan verilir; taşma testi bu widget'ı doğrudan render eder.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RenkTemasiSecici extends StatelessWidget {
  final TakimTemasi secili;
  final ValueChanged<TakimTemasi> onSec;

  const RenkTemasiSecici({
    super.key,
    required this.secili,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final parlaklik = Theme.of(context).brightness;
    return LayoutBuilder(
      builder: (context, kisit) {
        // Üç sütun ancak her karo alt etiketi ("Pantone 801C")
        // kesmeden taşıyacak kadar genişse; yazı büyütülünce eşik de büyür.
        // Çoğu telefonda iki sütun.
        const aralik = Bosluk.s;
        final olcek = MediaQuery.textScalerOf(context).scale(1);
        final ucSutunGenisligi = (kisit.maxWidth - aralik * 2) / 3;
        final sutun = ucSutunGenisligi >= 124 * olcek ? 3 : 2;
        final genislik = (kisit.maxWidth - aralik * (sutun - 1)) / sutun;
        return Wrap(
          spacing: aralik,
          runSpacing: aralik,
          children: [
            for (final t in TakimTemasi.values)
              SizedBox(
                width: genislik,
                child: _TemaKarosu(
                  tema: t,
                  palet: takimPaleti(t, parlaklik),
                  secili: t == secili,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSec(t);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TemaKarosu extends StatelessWidget {
  final TakimTemasi tema;
  final TakimPaleti palet;
  final bool secili;
  final VoidCallback onTap;

  const _TemaKarosu({
    required this.tema,
    required this.palet,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final p = palet.sema;
    final g = palet.gecisler;

    return Semantics(
      button: true,
      selected: secili,
      label: '${tema.etiket}, ${tema.altEtiket}',
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Yaricap.m),
          side: BorderSide(
            color: secili ? cs.primary : cs.outlineVariant,
            width: secili ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Bosluk.xs + 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Önizleme: o temanın başlık çubuğu, sayfa zemini, kimlik
                // yüzeyi, ana rengi ve alt menüsü.
                ClipRRect(
                  borderRadius: BorderRadius.circular(Yaricap.s),
                  child: SizedBox(
                    height: 46,
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: ColoredBox(color: g.sayfaRengi)),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: 9,
                          child: ColoredBox(color: g.baslik),
                        ),
                        Positioned(
                          left: 5,
                          right: 5,
                          top: 13,
                          height: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(gradient: g.kimlik),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: 2,
                                  width: double.infinity,
                                  child: DecoratedBox(
                                    decoration:
                                        BoxDecoration(gradient: g.serit),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          bottom: 10,
                          width: 22,
                          height: 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 6,
                          child: ColoredBox(color: g.altBar),
                        ),
                        if (secili)
                          Positioned(
                            right: 4,
                            bottom: 9,
                            child: Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded,
                                  size: 13, color: cs.onPrimary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Bosluk.xs),
                Text(
                  tema.etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.labelLarge?.copyWith(fontSize: 12),
                ),
                Text(
                  tema.altEtiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
