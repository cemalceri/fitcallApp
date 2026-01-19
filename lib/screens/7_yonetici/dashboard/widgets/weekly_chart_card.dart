// lib/screens/7_yonetici/dashboard/widgets/weekly_chart_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:intl/intl.dart';

enum GrafikTipi { ciro, tahsilat }

class WeeklyChartCard extends StatefulWidget {
  final List<HaftalikCiroItem> ciroData;
  final List<HaftalikTahsilatItem> tahsilatData;
  final VoidCallback? onDetayTap;

  const WeeklyChartCard({
    super.key,
    required this.ciroData,
    required this.tahsilatData,
    this.onDetayTap,
  });

  @override
  State<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<WeeklyChartCard> {
  GrafikTipi _seciliTip = GrafikTipi.ciro;

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Seçili tipe göre veri ve renk
    final isCiro = _seciliTip == GrafikTipi.ciro;
    final data = isCiro ? widget.ciroData : widget.tahsilatData;
    final barColor = isCiro ? Colors.green : Colors.blue;
    final title = isCiro ? 'Haftalık Ciro' : 'Haftalık Tahsilat';

    // Değerleri al
    final values = isCiro
        ? widget.ciroData.map((e) => e.ciro).toList()
        : widget.tahsilatData.map((e) => e.tahsilat).toList();

    final maxValue =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    // Toplam hesapla
    final toplam = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b);
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toplam: ${currencyFormat.format(toplam)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // Ciro/Tahsilat Toggle
              _buildToggle(colorScheme),
            ],
          ),
          const SizedBox(height: 20),

          // Grafik
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final value = isCiro
                    ? widget.ciroData[index].ciro
                    : widget.tahsilatData[index].tahsilat;
                final gun = isCiro
                    ? widget.ciroData[index].gun
                    : widget.tahsilatData[index].gun;

                final heightRatio = maxValue > 0 ? value / maxValue : 0.0;
                final barHeight = 90 * heightRatio;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Değer etiketi
                        if (value > 0)
                          Text(
                            _formatCurrency(value),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: barHeight.clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Gün etiketi
                        Text(
                          gun,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Detay butonu
          if (widget.onDetayTap != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onDetayTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detaylı Rapor',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            label: 'Ciro',
            isSelected: _seciliTip == GrafikTipi.ciro,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _seciliTip = GrafikTipi.ciro);
            },
            colorScheme: colorScheme,
            color: Colors.green,
          ),
          _buildToggleItem(
            label: 'Tahsilat',
            isSelected: _seciliTip == GrafikTipi.tahsilat,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _seciliTip = GrafikTipi.tahsilat);
            },
            colorScheme: colorScheme,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
