// lib/screens/3_antrenor/home/widgets/gunluk_kokpit_card.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/3_antrenor/gunluk_ozet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Antrenör ana sayfa günlük kokpiti: bugünün ders/öğrenci özeti + eksik yoklama uyarısı
class GunlukKokpitCard extends StatelessWidget {
  final GunlukOzetModel? ozet;
  final bool isLoading;

  const GunlukKokpitCard({super.key, this.ozet, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isLoading && ozet == null) {
      // Veri alınamadıysa kokpit gizlenir (yanlış sayı göstermek yerine)
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading ? _skeleton(colorScheme) : _icerik(context, ozet!),
    );
  }

  Widget _skeleton(ColorScheme colorScheme) {
    Widget blok(double genislik) => Container(
          width: genislik,
          height: 14,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        blok(100),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [blok(60), blok(60), blok(60)],
        ),
      ],
    );
  }

  Widget _icerik(BuildContext context, GunlukOzetModel o) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.today_rounded, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Bugün',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (o.ilkDers != null && o.sonDers != null)
              Text(
                '${o.ilkDers} - ${o.sonDers}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _stat(colorScheme, '${o.dersSayisi}', 'Ders',
                const Color(0xFF6366F1)),
            _ayrac(colorScheme),
            _stat(colorScheme, '${o.ogrenciSayisi}', 'Öğrenci',
                const Color(0xFF10B981)),
            _ayrac(colorScheme),
            _stat(colorScheme, '${o.kalan}', 'Kalan',
                const Color(0xFFF59E0B)),
            if (o.iptal > 0) ...[
              _ayrac(colorScheme),
              _stat(colorScheme, '${o.iptal}', 'İptal',
                  const Color(0xFFEF4444)),
            ],
          ],
        ),
        if (o.dersSayisi == 0) ...[
          const SizedBox(height: 10),
          Text(
            'Bugün planlı dersiniz yok.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (o.eksikYoklama > 0 || o.eksikYoklamaGecmis > 0) ...[
          const SizedBox(height: 12),
          _eksikYoklamaUyarisi(context, o),
        ],
      ],
    );
  }

  Widget _stat(
      ColorScheme colorScheme, String deger, String etiket, Color renk) {
    return Expanded(
      child: Column(
        children: [
          Text(
            deger,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ayrac(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 32,
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _eksikYoklamaUyarisi(BuildContext context, GunlukOzetModel o) {
    const renk = Color(0xFFEF4444);
    final String metin;
    if (o.eksikYoklama > 0 && o.eksikYoklamaGecmis > 0) {
      metin =
          'Bugün ${o.eksikYoklama}, son 7 günde ${o.eksikYoklamaGecmis} dersin yoklaması eksik';
    } else if (o.eksikYoklama > 0) {
      metin = 'Bugün ${o.eksikYoklama} dersin yoklaması eksik';
    } else {
      metin = 'Son 7 günde ${o.eksikYoklamaGecmis} dersin yoklaması eksik';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(
              context, routeEnums[SayfaAdi.antrenorDersler]!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: renk.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: renk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metin,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: renk,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: renk),
            ],
          ),
        ),
      ),
    );
  }
}
