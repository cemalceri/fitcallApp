// lib/screens/1_common/hakedis/widgets/hakedis_ay_panosu.dart
//
// Ay panosunun GÖRSEL gövdesi — durumsuz ve veriyle beslenen tek parça.
//
// Sayfa (HakedisAyPanosuPage) yalnız veri çekmeyi üstlenir; yerleşim burada.
// Ayrılmasının sebebi CLAUDE.md'deki kural: sayfa initState'te API çağırdığı
// için widget testinde render edilemiyor, bu yüzden taşma testine giremiyordu.
//
// Yerleşim: ay şeridi → seçili ayın iki özet kutusu → rol kartları.
// Rol kartındaki her satır bir gruptur (hakediş alacak / bekliyor / hakediş
// dışı) ve dokunulunca o grubun ders listesi açılır.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

import 'hakedis_ay_seridi.dart';
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
    final ay = ozet.aylar[seciliIndex];

    final liste = ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _OzetKutulari(ay: ay),
        const SizedBox(height: 14),
        if (ay.bos)
          _BosAy(etiket: ay.etiket)
        else
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
    );

    return Column(
      children: [
        HakedisAySeridi(
          aylar: ozet.aylar,
          seciliIndex: seciliIndex,
          onAySec: onAySec,
        ),
        const Divider(height: 1),
        Expanded(
          child: onYenile == null
              ? liste
              : RefreshIndicator(onRefresh: onYenile!, child: liste),
        ),
      ],
    );
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
    final vurgu = hakedisRengi(context, durum);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vurgu.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(hakedisIkonu(durum), size: 15, color: vurgu),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  HakedisDurumu.etiket(durum),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: vurgu,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              saatMetni(dakika),
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: vurgu,
              ),
            ),
          ),
          Text(
            '$dersSayisi ders',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: vurgu),
          ),
        ],
      ),
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

    return Container(
      decoration: BoxDecoration(
        color: renk.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: renk.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: renk.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(hakedisRolIkonu(rol.rol),
                    size: 17, color: renk.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    HakedisRolu.etiket(rol.rol),
                    maxLines: 1,
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
                  saatMetni(rol.dakika),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    color: renk.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < gruplar.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 14, endIndent: 14),
            _GrupSatiri(
              grup: gruplar[i],
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
  final VoidCallback onTap;

  const _GrupSatiri({required this.grup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final vurgu = hakedisRengi(context, grup.durum);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: vurgu, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                HakedisDurumu.etiket(grup.durum),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: renk.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${grup.dersSayisi} · ${saatMetni(grup.dakika)}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: renk.onSurface,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 19, color: renk.onSurfaceVariant),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: renk.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 34, color: renk.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            '$etiket ayında ders yok',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: renk.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
