// lib/screens/9_yonetici/dashboard/widgets/daily_summary_card.dart
//
// Yönetici panosunun kimlik yüzeyi. Para ve artı/eksi trend taşımayan tek kart
// olduğu için bu seçildi: renkli yüzeyin üstünde yeşil/kırmızı trend
// kullanmak anlamı bozardı. Değerler beyaz, durum rengi yok.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:flutter/material.dart';

class DailySummaryCard extends StatelessWidget {
  final GununOzeti data;

  const DailySummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    final ayrac = Container(
      width: 1,
      height: 40,
      color: yazi.withValues(alpha: 0.22),
    );

    return KimlikYuzeyi(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TemaGecisleri.kapsulZemini,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.summarize_outlined, size: 20, color: yazi),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bugünün Özeti',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: yazi,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  value: data.yeniKayit.toString(),
                  label: 'Yeni Kayıt',
                ),
              ),
              ayrac,
              Expanded(
                // Bugün yapılan telafi dersi değil: kullanılmamış, süresi
                // geçmemiş telafi hakkı sayısı (backend `telafi_bekleyen`).
                child: _SummaryItem(
                  value: data.telafiDers.toString(),
                  label: 'Bekleyen Telafi',
                ),
              ),
              ayrac,
              Expanded(
                child: _SummaryItem(
                  value: '%${data.dolulukYuzdesi.toStringAsFixed(0)}',
                  label: 'Doluluk',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: yazi,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: yazi,
          ),
        ),
      ],
    );
  }
}
