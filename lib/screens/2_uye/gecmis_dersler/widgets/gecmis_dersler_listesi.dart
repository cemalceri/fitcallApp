import 'package:fitcall/models/2_uye/gecmis_ders_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Geçmiş dersleri aya göre gruplayıp modern kartlarla listeler.
///
/// API çağrısı içermez; veri ve footer dışarıdan verilir. Böylece taşma
/// testinde doğrudan pump edilebilir (bkz. CLAUDE.md).
class GecmisDerslerListesi extends StatelessWidget {
  final List<GecmisDersModel> dersler;
  final void Function(GecmisDersModel) onDegerlendir;

  /// Liste sonuna eklenecek "daha eski" butonu / bilgi satırı (opsiyonel).
  final Widget? footer;

  const GecmisDerslerListesi({
    super.key,
    required this.dersler,
    required this.onDegerlendir,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // Aylara göre grupla (liste zaten yeniden eskiye sıralı gelir).
    final ayFmt = DateFormat('MMMM yyyy', 'tr');
    final gruplar = <String, List<GecmisDersModel>>{};
    for (final d in dersler) {
      final k = ayFmt.format(d.baslangicTarihSaat);
      gruplar.putIfAbsent(k, () => []).add(d);
    }

    final widgets = <Widget>[];
    gruplar.forEach((ay, list) {
      widgets.add(_AyBasligi(ay: ay, adet: list.length));
      for (final d in list) {
        widgets.add(_DersKarti(ders: d, onDegerlendir: () => onDegerlendir(d)));
      }
    });
    if (footer != null) widgets.add(footer!);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: widgets,
    );
  }
}

class _AyBasligi extends StatelessWidget {
  final String ay;
  final int adet;
  const _AyBasligi({required this.ay, required this.adet});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              ay[0].toUpperCase() + ay.substring(1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$adet ders',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _DersDurum {
  final String metin;
  final Color renk;
  const _DersDurum(this.metin, this.renk);
}

class _DersKarti extends StatelessWidget {
  final GecmisDersModel ders;
  final VoidCallback onDegerlendir;

  const _DersKarti({required this.ders, required this.onDegerlendir});

  _DersDurum get _durum {
    // İptal → kırmızı
    if (ders.iptalMi) return const _DersDurum('İptal', Color(0xFFEF4444));
    if (ders.katilim != null) {
      if (ders.katilim!.katildi) {
        // Katıldı / yapıldı → yeşil
        return _DersDurum(
          ders.katilim!.planDisiMi ? 'Katıldı (Plan dışı)' : 'Katıldı',
          const Color(0xFF10B981),
        );
      }
      // Üye katılmadı → gül (iptalin kırmızısından ayrışsın)
      return const _DersDurum('Katılmadı', Color(0xFFF43F5E));
    }
    if (ders.dersYapildi == true) {
      return const _DersDurum('Ders yapıldı', Color(0xFF10B981));
    }
    if (ders.dersYapildi == false) {
      // Yöneticinin "yapılmadı" işareti → nötr gri
      return const _DersDurum('Ders yapılmadı', Color(0xFF64748B));
    }
    // Henüz sonuç girilmemiş → üye için "Kulüp onayında", sarı
    return const _DersDurum('Kulüp onayında', Color(0xFFF59E0B));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final saatFmt = DateFormat('HH:mm');
    final gunFmt = DateFormat('EEE', 'tr');
    final durum = _durum;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: durum.renk.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih rozeti (durum rengiyle)
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: durum.renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${ders.baslangicTarihSaat.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: durum.renk,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    gunFmt.format(ders.baslangicTarihSaat),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: durum.renk.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${saatFmt.format(ders.baslangicTarihSaat)}'
                        ' - ${saatFmt.format(ders.bitisTarihSaat)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DurumRozet(durum: durum),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (ders.kortAdi.isNotEmpty) ders.kortAdi,
                    if (ders.antrenorAdi.isNotEmpty) ders.antrenorAdi,
                    if (ders.urunAdi.isNotEmpty) ders.urunAdi,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (ders.katilim?.notMetni != null &&
                    ders.katilim!.notMetni!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 15, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ders.katilim!.notMetni!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!ders.iptalMi) ...[
                  const SizedBox(height: 8),
                  _degerlendirmeSatiri(colorScheme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _degerlendirmeSatiri(ColorScheme colorScheme) {
    if (ders.puanim != null) {
      return Row(
        children: [
          ...List.generate(5, (i) {
            return Icon(
              i < ders.puanim!.puan
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 18,
              color: const Color(0xFFF59E0B),
            );
          }),
          if (ders.puanim!.yorum != null && ders.puanim!.yorum!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ders.puanim!.yorum!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onDegerlendir,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Değerlendir', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _DurumRozet extends StatelessWidget {
  final _DersDurum durum;
  const _DurumRozet({required this.durum});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: durum.renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        durum.metin,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: durum.renk,
        ),
      ),
    );
  }
}
