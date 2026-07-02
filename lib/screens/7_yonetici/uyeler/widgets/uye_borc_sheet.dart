// lib/screens/7_yonetici/uyeler/widgets/uye_borc_sheet.dart

import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/uye_detay_models.dart';
import 'package:intl/intl.dart';

const _aylar = [
  '',
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara'
];

enum _BorcSekme { hareketler, aylik }

/// Üyenin borç dökümünü (para hareketleri + aylık özet) gösteren bottom sheet.
class UyeBorcSheet extends StatefulWidget {
  final String adSoyad;
  final double bakiye;
  final List<ParaHareketItem> paraHareketleri;
  final List<AylikOzetItem> aylikOzet;

  const UyeBorcSheet({
    super.key,
    required this.adSoyad,
    required this.bakiye,
    required this.paraHareketleri,
    required this.aylikOzet,
  });

  @override
  State<UyeBorcSheet> createState() => _UyeBorcSheetState();
}

class _UyeBorcSheetState extends State<UyeBorcSheet> {
  _BorcSekme _sekme = _BorcSekme.hareketler;

  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borclu = widget.bakiye < 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Tutamaç
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Borç Dökümü',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            widget.adSoyad,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currency.format(widget.bakiye.abs()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: borclu ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          borclu ? 'Borçlu' : 'Bakiye',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _sekmeToggle(colorScheme),
              const SizedBox(height: 8),
              Expanded(
                child: _sekme == _BorcSekme.hareketler
                    ? _hareketlerListesi(scrollController, colorScheme)
                    : _aylikOzetListesi(scrollController, colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sekmeToggle(ColorScheme colorScheme) {
    Widget item(String label, _BorcSekme deger) {
      final secili = _sekme == deger;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _sekme = deger),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: secili ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: secili ? FontWeight.w600 : FontWeight.w500,
                color:
                    secili ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          item('Hareketler', _BorcSekme.hareketler),
          item('Aylık Özet', _BorcSekme.aylik),
        ],
      ),
    );
  }

  Widget _hareketlerListesi(
      ScrollController controller, ColorScheme colorScheme) {
    if (widget.paraHareketleri.isEmpty) {
      return Center(
        child: Text('Para hareketi bulunamadı',
            style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: widget.paraHareketleri.length,
      separatorBuilder: (_, __) => Divider(
        height: 16,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final h = widget.paraHareketleri[index];
        final renk = h.borcMu ? Colors.red : Colors.green;
        final tarih =
            h.tarih != null ? DateFormat('dd.MM.yyyy').format(h.tarih!) : '-';
        final altBilgi = [h.urunAdi, h.aciklama]
            .where((e) => e != null && e.isNotEmpty)
            .join(' • ');

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.hareketTuruLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    altBilgi.isEmpty ? tarih : '$tarih • $altBilgi',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${h.borcMu ? '+' : '-'}${_currency.format(h.tutar)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: renk,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _aylikOzetListesi(
      ScrollController controller, ColorScheme colorScheme) {
    if (widget.aylikOzet.isEmpty) {
      return Center(
        child: Text('Aylık özet bulunamadı',
            style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: widget.aylikOzet.length,
      separatorBuilder: (_, __) => Divider(
        height: 16,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final o = widget.aylikOzet[index];
        final ayAdi = (o.ay >= 1 && o.ay <= 12) ? _aylar[o.ay] : '${o.ay}';
        final kapanisBorclu = o.kapanisBakiyesi < 0;

        return Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                '$ayAdi ${o.yil}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _miniEtiket('Borç', _currency.format(o.borc), Colors.red,
                          colorScheme),
                      const SizedBox(width: 10),
                      _miniEtiket('Ödeme', _currency.format(o.odeme),
                          Colors.green, colorScheme),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bakiye: ${_currency.format(o.kapanisBakiyesi.abs())} ${kapanisBorclu ? '(B)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kapanisBorclu ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _miniEtiket(
      String etiket, String deger, Color renk, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(etiket,
            style: TextStyle(
                fontSize: 10, color: colorScheme.onSurfaceVariant)),
        Text(deger,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: renk)),
      ],
    );
  }
}
