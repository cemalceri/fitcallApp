// lib/screens/1_common/hakedis/widgets/hakedis_ay_panosu.dart
//
// Ay panosunun GÖRSEL gövdesi — durumsuz ve veriyle beslenen tek parça.
//
// Sayfa (HakedisAyPanosuPage) yalnız veri çekmeyi üstlenir; yerleşim burada.
// Ayrılmasının sebebi CLAUDE.md'deki kural: sayfa initState'te API çağırdığı
// için widget testinde render edilemiyor, bu yüzden taşma testine giremiyordu.
//
// Yerleşim: ay ızgarası (4×3) → seçili ayın özet kutuları + oran çubuğu →
// rol kartları. Rol kartındaki her satır bir gruptur (hakediş alacak /
// bekliyor / hakediş dışı) ve dokunulunca o grubun ders listesi açılır.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

import 'hakedis_ay_izgarasi.dart';
import 'hakedis_stil.dart';

class HakedisAyPanosu extends StatelessWidget {
  final HakedisOzet ozet;
  final int seciliIndex;
  final ValueChanged<int> onAySec;

  /// Grup satırına dokunulduğunda ders listesini açar.
  final void Function(HakedisAy ay, String rol, String durum) onGrupTap;

  final Future<void> Function()? onYenile;

  const HakedisAyPanosu({
    super.key,
    required this.ozet,
    required this.seciliIndex,
    required this.onAySec,
    required this.onGrupTap,
    this.onYenile,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final ay = ozet.aylar[seciliIndex];

    final liste = ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        HakedisAyIzgarasi(
          aylar: ozet.aylar.map((a) => a.hucre).toList(),
          seciliIndex: seciliIndex,
          onAySec: onAySec,
        ),
        const SizedBox(height: 20),

        // Seçili ayın başlığı — ızgarada hangi hücrede olduğumuz kaybolmasın.
        // Yan yana Row değil: büyük yazı ölçeğinde toplam metni taşırıyordu.
        Column(
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
            if (!ay.bos)
              Text(
                '${ay.dersSayisi} ders · ${saatMetni(ay.dakika)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: renk.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (ay.bos)
          _BosAy(etiket: ay.etiket)
        else ...[
          _OzetKutulari(ay: ay),
          const SizedBox(height: 12),
          _OranCubugu(ay: ay),
          const SizedBox(height: 18),
          ...ay.doluRoller.map(
            (rol) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RolKarti(
                rol: rol,
                onGrupTap: (durum) => onGrupTap(ay, rol.rol, durum),
              ),
            ),
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
/*                              ÖZET KUTULARI                                 */
/* -------------------------------------------------------------------------- */

class _OzetKutulari extends StatelessWidget {
  final HakedisAy ay;

  const _OzetKutulari({required this.ay});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight: iki kutu eşit yükseklikte dursun. `stretch` tek başına
    // olmaz — ListView içinde yükseklik sınırsız olduğundan sonsuz kısıt üretir.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _OzetKutusu(
              durum: HakedisDurumu.hakedis,
              dakika: ay.hakedisDakika,
              dersSayisi: ay.hakedisDersSayisi,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OzetKutusu(
              durum: HakedisDurumu.bekliyor,
              dakika: ay.bekleyenDakika,
              dersSayisi: ay.bekleyenDersSayisi,
            ),
          ),
        ],
      ),
    );
  }
}

class _OzetKutusu extends StatelessWidget {
  final String durum;
  final int dakika;
  final int dersSayisi;

  const _OzetKutusu({
    required this.durum,
    required this.dakika,
    required this.dersSayisi,
  });

  @override
  Widget build(BuildContext context) {
    final r = hakedisRengi(context, durum);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: r.dolgu,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.kenar),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: r.ana.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(hakedisIkonu(durum), size: 14, color: r.metin),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  HakedisDurumu.etiket(durum),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: r.metin,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              saatMetni(dakika),
              maxLines: 1,
              style: TextStyle(
                fontSize: 26,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: r.metin,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dersSayisi ders',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: r.metin.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              ORAN ÇUBUĞU                                   */
/* -------------------------------------------------------------------------- */

/// Ayın dakikalarının hakediş / bekleyen / dışı dağılımı — tek bakışta oran.
class _OranCubugu extends StatelessWidget {
  final HakedisAy ay;

  const _OranCubugu({required this.ay});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final toplam = ay.hakedisDakika + ay.bekleyenDakika + ay.disiDakika;
    if (toplam <= 0) return const SizedBox.shrink();

    final parcalar = <(String, int)>[
      (HakedisDurumu.hakedis, ay.hakedisDakika),
      (HakedisDurumu.bekliyor, ay.bekleyenDakika),
      (HakedisDurumu.disi, ay.disiDakika),
    ].where((p) => p.$2 > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                for (final (durum, dakika) in parcalar)
                  Expanded(
                    flex: dakika,
                    child: Container(
                      color: hakedisRengi(context, durum).ana,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Gösterge alt alta: Wrap içindeki Row'lar sınırsız genişlik aldığı
        // için büyük yazı ölçeğinde taşıyordu (Flexible orada işe yaramaz).
        for (final (durum, dakika) in parcalar)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hakedisRengi(context, durum).ana,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    HakedisDurumu.etiket(durum),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: renk.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  saatMetni(dakika),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: renk.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                ROL KARTI                                   */
/* -------------------------------------------------------------------------- */

class _RolKarti extends StatelessWidget {
  final HakedisRolOzeti rol;
  final ValueChanged<String> onGrupTap;

  const _RolKarti({required this.rol, required this.onGrupTap});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final gruplar = rol.doluGruplar;
    final vurgu = hakedisRenkSeti(
      context,
      rol.rol == HakedisRolu.yardimci ? hakedisMavi : const Color(0xFF6366F1),
    );

    return HakedisKart(
      child: Column(
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: vurgu.dolgu,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(hakedisRolIkonu(rol.rol),
                      size: 16, color: vurgu.metin),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        HakedisRolu.etiket(rol.rol),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: renk.onSurface,
                        ),
                      ),
                      Text(
                        '${rol.dersSayisi} ders',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: renk.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  saatMetni(rol.dakika),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: renk.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: renk.outlineVariant.withValues(alpha: 0.5),
          ),
          for (var i = 0; i < gruplar.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: renk.outlineVariant.withValues(alpha: 0.35),
              ),
            _GrupSatiri(
              grup: gruplar[i],
              sonMu: i == gruplar.length - 1,
              onTap: () => onGrupTap(gruplar[i].durum),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrupSatiri extends StatelessWidget {
  final HakedisGrubu grup;
  final bool sonMu;
  final VoidCallback onTap;

  const _GrupSatiri({
    required this.grup,
    required this.sonMu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final r = hakedisRengi(context, grup.durum);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: sonMu
            ? const BorderRadius.vertical(bottom: Radius.circular(15))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: r.dolgu,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(hakedisIkonu(grup.durum), size: 13, color: r.metin),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  HakedisDurumu.etiket(grup.durum),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: renk.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    saatMetni(grup.dakika),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: r.metin,
                    ),
                  ),
                  Text(
                    '${grup.dersSayisi} ders',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: renk.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: renk.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _BosAy extends StatelessWidget {
  final String etiket;

  const _BosAy({required this.etiket});

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
          Icon(Icons.event_busy_rounded,
              size: 32, color: renk.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            '$etiket ayında ders yok',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: renk.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
