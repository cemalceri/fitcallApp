// lib/screens/1_common/hakedis/widgets/hakedis_ders_karti.dart
//
// Ders listesindeki tek ders kartı.
//
// Gösterdikleri: gün/saat bloğu + süre, ürün · kort, katılımcılar (katıldı /
// katılmadı / yoklama alınmamış, plan dışı eklenenler ayrı işaretli) ve
// duruma göre bir açıklama paneli:
//
//   iptal edilen ders → kim iptal etti, ne zaman, sebep ve açıklama
//   yapılmadı işaretli → neden yapılmadı, hakediş verildiyse o da yazar
//
// İptal edilen dersler "hakediş dışı" grubunda çıkıyor; o satırın karşılığını
// yönetici ancak bu panelden görebiliyor.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hakedis_stil.dart';

class HakedisDersKarti extends StatelessWidget {
  final HakedisDers ders;

  const HakedisDersKarti({super.key, required this.ders});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final altBaslik = ders.altBaslik;

    return HakedisKart(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ZamanBlogu(baslangic: ders.baslangic),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _saatMetni,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: renk.onSurface,
                      ),
                    ),
                    if (altBaslik.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        altBaslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: renk.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (ders.iptalMi) ...[
                      const SizedBox(height: 6),
                      HakedisRozet(
                        metin: 'İptal edildi',
                        ikon: Icons.event_busy_rounded,
                        taban: hakedisKirmizi,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: renk.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  saatMetni(ders.dakika),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: renk.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (ders.katilimcilar.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ders.katilimcilar
                  .map((k) => _KatilimciRozeti(katilimci: k))
                  .toList(),
            ),
          ],
          if (ders.iptalBilgisiVar) ...[
            const SizedBox(height: 11),
            _IptalPaneli(ders: ders),
          ] else if (ders.yapilmadiNotuVar || _aciklamaVar) ...[
            const SizedBox(height: 11),
            _OnayNotu(ders: ders),
          ],
        ],
      ),
    );
  }

  String get _saatMetni {
    final bas = ders.baslangic;
    final bit = ders.bitis;
    if (bas == null) return '';
    final basMetin = DateFormat('HH:mm').format(bas);
    if (bit == null) return basMetin;
    return '$basMetin – ${DateFormat('HH:mm').format(bit)}';
  }

  bool get _aciklamaVar => ders.onayAciklamasi?.isNotEmpty == true;
}

/* -------------------------------------------------------------------------- */

/// Kartın solundaki gün bloğu — "12" üstte, "Tem Paz" altta.
class _ZamanBlogu extends StatelessWidget {
  final DateTime? baslangic;

  const _ZamanBlogu({required this.baslangic});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final bas = baslangic;
    if (bas == null) return const SizedBox.shrink();

    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: renk.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d', 'tr_TR').format(bas),
            maxLines: 1,
            style: TextStyle(
              fontSize: 18,
              height: 1.05,
              fontWeight: FontWeight.w700,
              color: renk.onSurface,
            ),
          ),
          Text(
            DateFormat('MMM', 'tr_TR').format(bas),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              color: renk.onSurfaceVariant,
            ),
          ),
          Text(
            DateFormat('EEE', 'tr_TR').format(bas),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.15,
              color: renk.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _KatilimciRozeti extends StatelessWidget {
  final HakedisKatilimci katilimci;

  const _KatilimciRozeti({required this.katilimci});

  @override
  Widget build(BuildContext context) {
    final r = hakedisRenkSeti(context, katilimTabanRengi(katilimci));
    final ad = katilimci.planDisiMi
        ? '${katilimci.adSoyad} · plan dışı'
        : katilimci.adSoyad;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: r.dolgu,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: r.kenar),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(katilimIkonu(katilimci), size: 13, color: r.metin),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: r.metin,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// İptal edilen dersin künyesi: kim, ne zaman, neden.
class _IptalPaneli extends StatelessWidget {
  final HakedisDers ders;

  const _IptalPaneli({required this.ders});

  @override
  Widget build(BuildContext context) {
    final r = hakedisRenkSeti(context, hakedisKirmizi);

    final satirlar = <(IconData, String)>[
      if (ders.iptalSebebi?.isNotEmpty == true)
        (Icons.label_outline_rounded, ders.iptalSebebi!),
      if (ders.iptalEden?.isNotEmpty == true)
        (Icons.person_outline_rounded, '${ders.iptalEden!} iptal etti'),
      if (ders.iptalTarihi != null)
        (
          Icons.schedule_rounded,
          DateFormat('d MMMM y · HH:mm', 'tr_TR').format(ders.iptalTarihi!),
        ),
      if (ders.iptalAciklamasi?.isNotEmpty == true)
        (Icons.notes_rounded, ders.iptalAciklamasi!),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: r.dolgu,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: r.kenar),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_rounded, size: 15, color: r.metin),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ders iptal edildi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: r.metin,
                  ),
                ),
              ),
            ],
          ),
          for (final (ikon, metin) in satirlar) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ikon, size: 13, color: r.metin.withValues(alpha: 0.75)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    metin,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: r.metin.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OnayNotu extends StatelessWidget {
  final HakedisDers ders;

  const _OnayNotu({required this.ders});

  /// "Yapılmadı · Hava şartları · Hakediş verildi" biçiminde tek satır.
  String _metin() {
    final parcalar = <String>[];
    if (ders.yoneticiTamamlandi == false) parcalar.add('Yapılmadı');
    if (ders.onayNedeni?.isNotEmpty == true) parcalar.add(ders.onayNedeni!);
    if (ders.onayAciklamasi?.isNotEmpty == true) {
      parcalar.add(ders.onayAciklamasi!);
    }
    if (ders.yoneticiTamamlandi == false &&
        ders.durum == HakedisDurumu.hakedis) {
      parcalar.add('Hakediş verildi');
    }
    return parcalar.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final r = hakedisRenkSeti(
      context,
      ders.yoneticiTamamlandi == false ? hakedisTuruncu : hakedisGri,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: r.dolgu,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: r.kenar),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: r.metin),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _metin(),
              style: TextStyle(fontSize: 12, height: 1.35, color: r.metin),
            ),
          ),
        ],
      ),
    );
  }
}
