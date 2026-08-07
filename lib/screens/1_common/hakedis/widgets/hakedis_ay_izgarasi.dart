// lib/screens/1_common/hakedis/widgets/hakedis_ay_izgarasi.dart
//
// Son 12 ayın seçici ızgarası — 4 sütun × 3 satır, alt alta.
//
// Yatay kaydırmalı şerit değil: kaydırmadan görünmeyen aylar gözden kaçıyordu.
// Tümü tek bakışta duruyor ve dokunulan ay altındaki içeriği süzüyor.
//
// TAŞMA: hücre yüksekliği sabit DEĞİL — yazı ölçeği büyüdükçe satır uzar.
// Bu yüzden GridView + childAspectRatio yerine IntrinsicHeight'lı Row'lar
// kullanılıyor (sabit oran 1.3 ölçekte taşıyordu).

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

import 'hakedis_stil.dart';

class HakedisAyIzgarasi extends StatelessWidget {
  final List<HakedisAyHucresi> aylar;
  final int seciliIndex;
  final ValueChanged<int> onAySec;

  /// Satır başına hücre sayısı.
  static const int sutunSayisi = 4;

  const HakedisAyIzgarasi({
    super.key,
    required this.aylar,
    required this.seciliIndex,
    required this.onAySec,
  });

  @override
  Widget build(BuildContext context) {
    final satirSayisi = (aylar.length + sutunSayisi - 1) ~/ sutunSayisi;

    return Column(
      children: [
        for (var satir = 0; satir < satirSayisi; satir++)
          Padding(
            padding: EdgeInsets.only(bottom: satir == satirSayisi - 1 ? 0 : 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var sutun = 0; sutun < sutunSayisi; sutun++) ...[
                    if (sutun > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _hucre(satir * sutunSayisi + sutun),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _hucre(int index) {
    // Son satır dolmayabilir; boş yeri görünmez kutuyla doldur ki hücre
    // genişlikleri kaymasın.
    if (index >= aylar.length) return const SizedBox.shrink();
    return _AyHucresi(
      hucre: aylar[index],
      secili: index == seciliIndex,
      onTap: () => onAySec(index),
    );
  }
}

class _AyHucresi extends StatelessWidget {
  final HakedisAyHucresi hucre;
  final bool secili;
  final VoidCallback onTap;

  const _AyHucresi({
    required this.hucre,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme;
    final bekleyen = hakedisRenkSeti(context, hakedisTuruncu);

    final Color arka;
    final Color kenar;
    final Color yazi;
    final Color altYazi;

    if (secili) {
      arka = renk.primary;
      kenar = renk.primary;
      yazi = renk.onPrimary;
      altYazi = renk.onPrimary.withValues(alpha: 0.82);
    } else if (hucre.bos) {
      // Dersi olmayan ay: geri planda dursun ama tıklanabilir kalsın.
      arka = Colors.transparent;
      kenar = renk.outlineVariant.withValues(alpha: 0.45);
      yazi = renk.onSurfaceVariant.withValues(alpha: 0.65);
      altYazi = renk.onSurfaceVariant.withValues(alpha: 0.45);
    } else {
      arka = renk.surfaceContainerHighest.withValues(alpha: 0.45);
      kenar = renk.outlineVariant.withValues(alpha: 0.5);
      yazi = renk.onSurface;
      altYazi = renk.onSurfaceVariant;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: arka,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kenar, width: secili ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      hucre.kisaAd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: yazi,
                      ),
                    ),
                  ),
                  // Karar bekleyen dersi olan ay, seçili olmasa da işaretli.
                  if (hucre.bekleyenVar) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: secili ? renk.onPrimary : bekleyen.ana,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                "'${hucre.yilKisa}",
                maxLines: 1,
                style: TextStyle(fontSize: 10, height: 1.1, color: altYazi),
              ),
              const SizedBox(height: 3),
              Text(
                hucre.bos ? '—' : saatMetni(hucre.dakika),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: secili ? yazi : altYazi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
