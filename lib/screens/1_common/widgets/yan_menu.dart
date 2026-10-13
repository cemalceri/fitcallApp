// lib/screens/1_common/widgets/yan_menu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sol menü (drawer) başlığı — rol adı ve kullanıcı adı.
class YanMenuBasligi extends StatelessWidget {
  final String ad;
  final String altBaslik;

  const YanMenuBasligi({
    super.key,
    required this.ad,
    required this.altBaslik,
  });

  /// Takım renginde başlık bandı (sayfaların başlık çubuğuyla aynı);
  /// durum çubuğunun arkasına uzanır, çekmecenin SafeArea'sı `top: false`.
  @override
  Widget build(BuildContext context) {
    final g = context.gecis;
    return BaslikBandi(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.l),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Bosluk.s),
            decoration: BoxDecoration(
              color: g.onBaslik.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Yaricap.m),
            ),
            child: Icon(Icons.sports_tennis_rounded,
                color: g.onBaslik, size: 24),
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baslikYazi(context, context.metin.titleMedium),
                ),
                Text(
                  altBaslik,
                  style: baslikYazi(context, context.metin.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sol menüdeki bölüm ayracı.
class YanMenuBolumu extends StatelessWidget {
  final String baslik;
  const YanMenuBolumu(this.baslik, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xs),
      child: Text(
        baslik.toUpperCase(),
        style: context.metin.labelSmall?.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

/// Sol menü satırı.
///
/// İkonlar tek renk: aktif satır dışında hepsi `onSurfaceVariant`. Eski
/// menüde her satır ayrı bir renk taşıyordu — anlam üretmeyen bir gökkuşağı.
class YanMenuOgesi extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final VoidCallback onTap;

  /// Kabuk sekmesine karşılık gelen satırlarda hangi sayfada olunduğunu gösterir.
  final bool aktif;

  /// Okunmamış sayısı gibi sayaçlar.
  final int? rozet;

  const YanMenuOgesi({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.onTap,
    this.aktif = false,
    this.rozet,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renk = aktif ? cs.primary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 1),
      child: Material(
        color: aktif ? context.renkler.vurguZemin : Colors.transparent,
        borderRadius: BorderRadius.circular(Yaricap.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(Yaricap.m),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Bosluk.m, vertical: Bosluk.m),
            child: Row(
              children: [
                Icon(ikon, size: 22, color: renk),
                const SizedBox(width: Bosluk.m),
                Expanded(
                  child: Text(
                    baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.metin.titleSmall?.copyWith(
                      color: aktif ? cs.primary : cs.onSurface,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (rozet != null && rozet! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Bosluk.s, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(Yaricap.xl),
                    ),
                    child: Text(
                      rozet! > 99 ? '99+' : '$rozet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onError,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
