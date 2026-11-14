// lib/screens/7_yonetici/dashboard/widgets/dikkat_karti.dart
//
// Ana sayfanın "Dikkat isteyenler" kartı: yöneticinin bakması gereken konular
// tek yerde. Maddeler ve metinleri sunucudan gelir (yoneticiDashboard.dikkat);
// burada yalnız ikon ve hedef seçilir. Yönetici aksiyon almaz, ilgili listeye
// gider.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:material_ui/material_ui.dart';

class DikkatKarti extends StatelessWidget {
  final List<DikkatMaddesi> maddeler;

  /// Maddeye dokununca; null dönen maddeler (hedefi olmayan) ok göstermez.
  final VoidCallback? Function(DikkatMaddesi madde) hedef;

  const DikkatKarti({super.key, required this.maddeler, required this.hedef});

  static IconData ikon(String kod) => switch (kod) {
        'onay_bekleyen' => Icons.schedule_rounded,
        'dekont_bekleyen' => Icons.receipt_long_rounded,
        'bugun_iptal' => Icons.cancel_outlined,
        'gelmeyen_uye' => Icons.person_off_outlined,
        'ekip' => Icons.badge_outlined,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return PanoKarti(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanoBasligi(
            'Dikkat isteyenler',
            sag: maddeler.isEmpty
                ? null
                : DurumHapi('${maddeler.length} konu', ton: ListeTonu.uyari),
          ),
          const SizedBox(height: 6),
          if (maddeler.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Row(
                children: [
                  const TonKarosu(
                    ikon: Icons.check_rounded,
                    ton: ListeTonu.basari,
                  ),
                  const SizedBox(width: Bosluk.m),
                  Expanded(
                    child: Text(
                      'Şu an dikkat isteyen bir konu yok.',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < maddeler.length; i++) ...[
            if (i > 0) Divider(height: 1, color: cs.outlineVariant),
            _Satir(madde: maddeler[i], onTap: hedef(maddeler[i])),
          ],
        ],
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  final DikkatMaddesi madde;
  final VoidCallback? onTap;

  const _Satir({required this.madde, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Yaricap.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            TonKarosu(ikon: DikkatKarti.ikon(madde.kod), ton: tonCoz(madde.ton)),
            const SizedBox(width: Bosluk.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    madde.baslik,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  if ((madde.aciklama ?? '').isNotEmpty)
                    Text(
                      madde.aciklama!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
