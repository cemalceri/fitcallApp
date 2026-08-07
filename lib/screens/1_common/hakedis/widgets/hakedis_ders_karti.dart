// lib/screens/1_common/hakedis/widgets/hakedis_ders_karti.dart
//
// Ders listesindeki tek ders kartı.
//
// Gösterdikleri: tarih/saat + süre, ürün · kort, katılımcılar (katıldı /
// katılmadı / yoklama alınmamış, plan dışı eklenenler ayrı işaretli) ve
// yöneticinin onay açıklaması — özellikle "ders yapılmadı ama hakediş verildi"
// durumunun gerekçesi görünsün diye.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hakedis_stil.dart';

class HakedisDersKarti extends StatelessWidget {
  final HakedisDers ders;

  const HakedisDersKarti({super.key, required this.ders});

  String get _zamanMetni {
    final bas = ders.baslangic;
    if (bas == null) return '';
    return '${DateFormat('d MMM EEE', 'tr_TR').format(bas)} · '
        '${DateFormat('HH:mm').format(bas)}';
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final altBaslik = ders.altBaslik;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: renk.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: renk.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _zamanMetni,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: renk.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                saatMetni(ders.dakika),
                maxLines: 1,
                style: TextStyle(fontSize: 13, color: renk.onSurfaceVariant),
              ),
            ],
          ),
          if (altBaslik.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              altBaslik,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: renk.onSurfaceVariant),
            ),
          ],
          if (ders.iptalMi) ...[
            const SizedBox(height: 6),
            _Etiket(
              metin: 'İptal edildi',
              renk: renk.error,
              ikon: Icons.event_busy_rounded,
            ),
          ],
          if (ders.katilimcilar.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ders.katilimcilar
                  .map((k) => _KatilimciRozeti(katilimci: k))
                  .toList(),
            ),
          ],
          if (ders.yapilmadiNotuVar || _aciklamaVar) ...[
            const SizedBox(height: 9),
            _OnayNotu(ders: ders),
          ],
        ],
      ),
    );
  }

  bool get _aciklamaVar => ders.onayAciklamasi?.isNotEmpty == true;
}

/* -------------------------------------------------------------------------- */

class _KatilimciRozeti extends StatelessWidget {
  final HakedisKatilimci katilimci;

  const _KatilimciRozeti({required this.katilimci});

  @override
  Widget build(BuildContext context) {
    final vurgu = katilimRengi(context, katilimci);
    final ad = katilimci.planDisiMi
        ? '${katilimci.adSoyad} · plan dışı'
        : katilimci.adSoyad;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: vurgu.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(katilimIkonu(katilimci), size: 13, color: vurgu),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: vurgu,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnayNotu extends StatelessWidget {
  final HakedisDers ders;

  const _OnayNotu({required this.ders});

  /// "Yapılmadı · yağmur — Hakediş verildi." biçiminde tek satır.
  String _metin() {
    final parcalar = <String>[];
    if (ders.yoneticiTamamlandi == false) parcalar.add('Yapılmadı');
    if (ders.onayNedeni?.isNotEmpty == true) parcalar.add(ders.onayNedeni!);
    if (ders.onayAciklamasi?.isNotEmpty == true) {
      parcalar.add(ders.onayAciklamasi!);
    }
    if (ders.yoneticiTamamlandi == false && ders.durum == HakedisDurumu.hakedis) {
      parcalar.add('Hakediş verildi');
    }
    return parcalar.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final vurgu = ders.yoneticiTamamlandi == false
        ? hakedisRengi(context, HakedisDurumu.bekliyor)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: vurgu.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: vurgu),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _metin(),
              style: TextStyle(fontSize: 12, height: 1.35, color: vurgu),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  final String metin;
  final Color renk;
  final IconData ikon;

  const _Etiket({required this.metin, required this.renk, required this.ikon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renk),
          const SizedBox(width: 4),
          Text(
            metin,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}
