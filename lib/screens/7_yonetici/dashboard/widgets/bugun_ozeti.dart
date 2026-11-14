// lib/screens/7_yonetici/dashboard/widgets/bugun_ozeti.dart
//
// Ana sayfanın en üstü: seçili dönemden bağımsız, hep BUGÜN.
//   - kimlik yüzeyinde bugün tahsil edilen (kıyassız; yanında son giriş saati)
//   - bugünkü ders (biten / toplam, iptal ve onay bekleyen)
//   - bugünkü doluluk
//
// Tahsil edilenin yüzdesi yok: ödemeler sisteme gecikmeli girildiği için günün
// kıyası yanıltıyor; "son giriş" rakamın ne kadar güncel olduğunu söyler.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/7_yonetici/widgets/pano_parcalari.dart';
import 'package:material_ui/material_ui.dart';

class BugunOzeti extends StatelessWidget {
  final GununOzeti ozet;

  /// Bugün dersi bitmiş ama ofis onayı olmayanlar.
  final int onayBekleyen;

  /// Ders kartına dokununca (Dersler sekmesi).
  final VoidCallback? onDersler;

  const BugunOzeti({
    super.key,
    required this.ozet,
    required this.onayBekleyen,
    this.onDersler,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KasaKarti(ozet: ozet),
        const SizedBox(height: Bosluk.m),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OgrenmeHedefi(
                  id: Hedef.yoneticiBugunDersleri,
                  child: _DersKarti(
                    ozet: ozet,
                    onayBekleyen: onayBekleyen,
                    onTap: onDersler,
                  ),
                ),
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(child: _DolulukKarti(yuzde: ozet.dolulukYuzdesi)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KasaKarti extends StatelessWidget {
  final GununOzeti ozet;
  const _KasaKarti({required this.ozet});

  @override
  Widget build(BuildContext context) {
    final yazi = context.gecis.onKimlik;
    final sonGiris = ozet.bugunSonGiris;
    final altYazi = sonGiris == null
        ? 'Bugün henüz ödeme girilmedi'
        : 'Son giriş ${saatYaz(sonGiris)} · ${ozet.bugunTahsilatIslem} ödeme';

    return KimlikYuzeyi(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahsil edilen · bugün',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: yazi,
            ),
          ),
          const SizedBox(height: 4),
          TutarYazisi(
            tutarYaz(ozet.bugunTahsilat ?? 0),
            birim: 'TL',
            boyut: 34,
            renk: yazi,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: yazi),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  altYazi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: yazi),
                ),
              ),
            ],
          ),
          if (ozet.yeniKayit > 0) ...[
            const SizedBox(height: 10),
            KimlikKapsulu(
              'Bugün ${ozet.yeniKayit} yeni üye',
              ikon: Icons.person_add_alt_1_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _DersKarti extends StatelessWidget {
  final GununOzeti ozet;
  final int onayBekleyen;
  final VoidCallback? onTap;

  const _DersKarti({
    required this.ozet,
    required this.onayBekleyen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final toplam = ozet.bugunToplamDers ?? 0;
    final biten = ozet.bugunBitenDers;
    return PanoKarti(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: PanoEtiketi('Bugünkü ders')),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: context.cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 4),
          TutarYazisi('$biten', birim: '/ $toplam'),
          // "x / y" tek başına anlaşılmıyordu: x saati geçen (yönetici onayı
          // aranmaz), y bugünün iptal edilmeyen dersleri.
          Text(
            'Saati biten / bugünkü toplam ders (iptaller hariç)',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          IlerlemeCizgisi(toplam == 0 ? 0 : biten / toplam),
          if (ozet.bugunIptalDers > 0 || onayBekleyen > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (ozet.bugunIptalDers > 0)
                  DurumHapi('${ozet.bugunIptalDers} iptal',
                      ton: ListeTonu.hata),
                if (onayBekleyen > 0)
                  DurumHapi('$onayBekleyen onay bekliyor',
                      ton: ListeTonu.uyari),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DolulukKarti extends StatelessWidget {
  final double yuzde;
  const _DolulukKarti({required this.yuzde});

  @override
  Widget build(BuildContext context) {
    return PanoKarti(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanoEtiketi('Doluluk'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: TutarYazisi('%${yuzde.toStringAsFixed(0)}')),
              const SizedBox(width: Bosluk.s),
              HalkaGosterge(yuzde / 100, boyut: 48),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 8),
          Text(
            'Kortlarda bugün dersli süre',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: context.cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
