// lib/screens/1_common/hakedis/widgets/hakedis_antrenor_listesi.dart
//
// Yönetici antrenör seçim ekranının GÖRSEL gövdesi.
//
// Üstte 4×3 ay ızgarası, altında SEÇİLİ AYA ait antrenör listesi. Her satırda
// o antrenörün o aydaki hakediş/bekleyen saatleri var — 12 ay toplamı değil.
// Ay değiştirmek yeni istek atmaz; 12 ayın tamamı tek yanıtta geliyor.
//
// Sayfa (HakedisAntrenorSecimPage) veri çekmeyi üstlenir; yerleşim burada
// olduğu için taşma testine girebiliyor.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

import 'hakedis_ay_izgarasi.dart';
import 'hakedis_stil.dart';

class HakedisAntrenorListesiGorunumu extends StatelessWidget {
  final List<HakedisListeAyi> aylar;
  final int seciliIndex;
  final ValueChanged<int> onAySec;

  final List<HakedisAntrenorOzeti> antrenorler;
  final void Function(HakedisAntrenorOzeti antrenor) onAntrenorTap;
  final Future<void> Function()? onYenile;

  /// Arama/filtre sonucu liste boşaldığında gösterilecek metin.
  final String bosMesaj;

  const HakedisAntrenorListesiGorunumu({
    super.key,
    required this.aylar,
    required this.seciliIndex,
    required this.onAySec,
    required this.antrenorler,
    required this.onAntrenorTap,
    this.onYenile,
    this.bosMesaj = 'Antrenör bulunamadı',
  });

  HakedisListeAyi? get _seciliAy =>
      (seciliIndex >= 0 && seciliIndex < aylar.length)
          ? aylar[seciliIndex]
          : null;

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final ay = _seciliAy;

    // Dersi olan antrenörler üstte; eşitlikte isim sırası korunur.
    final sirali = [...antrenorler]..sort((a, b) {
        final ax = a.ay(seciliIndex).dakika;
        final bx = b.ay(seciliIndex).dakika;
        if (ax != bx) return bx.compareTo(ax);
        return 0;
      });

    final liste = ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        if (aylar.isNotEmpty) ...[
          HakedisAyIzgarasi(
            aylar: aylar.map((a) => a.hucre).toList(),
            seciliIndex: seciliIndex,
            onAySec: onAySec,
          ),
          const SizedBox(height: 20),
        ],
        if (ay != null) _AyBasligi(ay: ay),
        const SizedBox(height: 12),
        if (sirali.isEmpty)
          _BosListe(mesaj: bosMesaj)
        else
          ...sirali.map(
            (antrenor) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AntrenorSatiri(
                antrenor: antrenor,
                donem: antrenor.ay(seciliIndex),
                onTap: () => onAntrenorTap(antrenor),
              ),
            ),
          ),
        if (sirali.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Antrenöre dokununca o ayın dökümü açılır; içeride diğer aylara da '
            'geçebilirsiniz.',
            style: TextStyle(fontSize: 11.5, color: renk.onSurfaceVariant),
          ),
        ],
      ],
    );

    return onYenile == null
        ? liste
        : RefreshIndicator(onRefresh: onYenile!, child: liste);
  }
}

/* -------------------------------------------------------------------------- */

class _AyBasligi extends StatelessWidget {
  final HakedisListeAyi ay;

  const _AyBasligi({required this.ay});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final hakedis = hakedisRengi(context, HakedisDurumu.hakedis);
    final bekleyen = hakedisRengi(context, HakedisDurumu.bekliyor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ay.etiket,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: renk.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            HakedisRozet(
              metin: 'Hakediş ${saatMetni(ay.donem.hakedisDakika)}',
              ikon: hakedisIkonu(HakedisDurumu.hakedis),
              taban: hakedis.ana,
            ),
            if (ay.donem.bekleyenVar)
              HakedisRozet(
                metin: '${ay.donem.bekleyenDersSayisi} ders karar bekliyor',
                ikon: hakedisIkonu(HakedisDurumu.bekliyor),
                taban: bekleyen.ana,
              ),
          ],
        ),
      ],
    );
  }
}

class _AntrenorSatiri extends StatelessWidget {
  final HakedisAntrenorOzeti antrenor;
  final HakedisDonem donem;
  final VoidCallback onTap;

  const _AntrenorSatiri({
    required this.antrenor,
    required this.donem,
    required this.onTap,
  });

  /// "Ayşe Yılmaz" → "AY"
  String get _basHarfler {
    final parcalar = antrenor.adSoyad
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parcalar.isEmpty) return '?';
    if (parcalar.length == 1) return parcalar.first.substring(0, 1).toUpperCase();
    return (parcalar.first.substring(0, 1) + parcalar.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final hakedis = hakedisRengi(context, HakedisDurumu.hakedis);
    final bekleyen = hakedisRengi(context, HakedisDurumu.bekliyor);
    final bosAy = donem.bos;

    return HakedisKart(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          // Baş harfler
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bosAy
                  ? renk.surfaceContainerHighest.withValues(alpha: 0.6)
                  : hakedis.dolgu,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _basHarfler,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: bosAy ? renk.onSurfaceVariant : hakedis.metin,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        antrenor.adSoyad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: renk.onSurface,
                        ),
                      ),
                    ),
                    if (!antrenor.aktifMi) ...[
                      const SizedBox(width: 6),
                      Text(
                        'pasif',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: renk.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (bosAy)
                  Text(
                    'Bu ayda ders yok',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: renk.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      HakedisRozet(
                        metin: '${donem.hakedisDersSayisi} ders',
                        ikon: hakedisIkonu(HakedisDurumu.hakedis),
                        taban: hakedis.ana,
                      ),
                      if (donem.bekleyenVar)
                        HakedisRozet(
                          metin: '${donem.bekleyenDersSayisi} bekliyor',
                          ikon: hakedisIkonu(HakedisDurumu.bekliyor),
                          taban: bekleyen.ana,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bosAy ? '—' : saatMetni(donem.hakedisDakika),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: bosAy ? renk.onSurfaceVariant : hakedis.metin,
                ),
              ),
              if (!bosAy)
                Text(
                  'hakediş',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    color: renk.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: renk.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _BosListe extends StatelessWidget {
  final String mesaj;

  const _BosListe({required this.mesaj});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: renk.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded,
              size: 32, color: renk.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            mesaj,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: renk.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
