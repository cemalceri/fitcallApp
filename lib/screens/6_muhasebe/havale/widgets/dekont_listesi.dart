// lib/screens/6_muhasebe/havale/widgets/dekont_listesi.dart
//
// "Dekontlarım": üyenin yüklediği dekontlar, en yeni üstte. Durum kelime +
// ikonla anlatılır (renk tek başına değil); ret gerekçesi satırın altında,
// listede görünür. Geri çekme yalnız kontrol bekleyende (sola kaydır ya da
// uzun bas). Geri çekilenler sunucudan hiç gelmez.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
// Tam tutarlar kuruşsuz: "₺1.250.000,00" 320 px'te 1.3 ölçekte satırı taşırıyordu.
final _tlTam = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

IconData dekontIkonu(DekontDurumu durum) => switch (durum) {
      DekontDurumu.bekliyor => Icons.schedule_rounded,
      DekontDurumu.islendi => Icons.check_circle_outline_rounded,
      DekontDurumu.reddedildi => Icons.cancel_outlined,
      _ => Icons.receipt_long_outlined,
    };

String dekontBasligi(DekontModel d) {
  final t = d.yuklenme;
  return t == null ? 'Dekont' : 'Dekont · ${DateFormat('d MMM yyyy', 'tr').format(t)}';
}

String dekontTutarMetni(DekontModel d) {
  final tutar = d.gosterilenTutar;
  if (tutar == null) return 'Tutar yok';
  return (tutar == tutar.roundToDouble() ? _tlTam : _tl).format(tutar);
}

/// Satırın ikinci satırı: durum; işlenmişse ödemenin yazıldığı profiller.
String dekontAltBasligi(DekontModel d) {
  if (d.durum == DekontDurumu.islendi && d.islenenUyeler.isNotEmpty) {
    return 'İşlendi · ${d.islenenUyeler.join(', ')} hesabına';
  }
  return d.durumMetni;
}

class DekontlarimGorunumu extends StatelessWidget {
  final List<DekontModel> dekontlar;

  /// Az önce yüklenen dekont kısa süre vurgulanır.
  final int? vurgulananId;
  final ValueChanged<DekontModel> onTap;
  final ValueChanged<DekontModel> onGeriCek;
  final VoidCallback? onDekontYukle;
  final Future<void> Function()? onYenile;

  const DekontlarimGorunumu({
    super.key,
    required this.dekontlar,
    required this.onTap,
    required this.onGeriCek,
    this.vurgulananId,
    this.onDekontYukle,
    this.onYenile,
  });

  @override
  Widget build(BuildContext context) {
    final liste = dekontlar.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Bosluk.xl),
                child: BosDurum(
                  ikon: Icons.receipt_long_outlined,
                  baslik: 'Henüz dekont yok',
                  aciklama:
                      'Havale yaptıysan dekontunu yükle; kulüp kontrol edip '
                      'hesabına işler.',
                  eylemEtiketi: onDekontYukle == null ? null : 'Dekont yükle',
                  eylemIkonu: Icons.upload_rounded,
                  onEylem: onDekontYukle,
                ),
              ),
            ],
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Bosluk.xl),
            itemCount: dekontlar.length + 1,
            itemBuilder: (context, i) {
              if (i == dekontlar.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Bosluk.l, Bosluk.m, Bosluk.l, 0),
                  child: Text(
                    'Bekleyen dekontu sola kaydırıp geri çekebilirsin. '
                    'İşlenen dekont silinemez.',
                    style: context.metin.bodySmall
                        ?.copyWith(color: context.cs.onSurfaceVariant),
                  ),
                );
              }
              final d = dekontlar[i];
              return DekontSatiri(
                dekont: d,
                vurgulu: d.id == vurgulananId,
                onTap: () => onTap(d),
                onGeriCek: () => onGeriCek(d),
              );
            },
          );
    if (onYenile == null) return liste;
    return RefreshIndicator(onRefresh: onYenile!, child: liste);
  }
}

class DekontSatiri extends StatelessWidget {
  final DekontModel dekont;
  final bool vurgulu;
  final VoidCallback onTap;
  final VoidCallback onGeriCek;

  const DekontSatiri({
    super.key,
    required this.dekont,
    required this.onTap,
    required this.onGeriCek,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = dekont;
    final gerekce = d.durum == DekontDurumu.reddedildi && d.redNedeni.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: vurgulu
          ? context.cs.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListeSatiri(
            onGorsel: ListeAvatari(ikon: dekontIkonu(d.durum), ton: d.ton),
            baslik: dekontBasligi(d),
            altBaslik: dekontAltBasligi(d),
            deger: dekontTutarMetni(d),
            onTap: onTap,
            eylemler: [
              if (d.bekliyor)
                ListeEylemi(
                  etiket: 'Geri çek',
                  ikon: Icons.undo_rounded,
                  ton: ListeTonu.hata,
                  onSec: onGeriCek,
                ),
            ],
          ),
          if (gerekce)
            Padding(
              // Avatarın sağındaki metin hizası (16 + 44 + 12).
              padding: const EdgeInsets.fromLTRB(72, 0, Bosluk.l, Bosluk.m),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'Gerekçe: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.renkler.hata,
                    ),
                  ),
                  TextSpan(text: d.redNedeni),
                ]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.metin.bodySmall
                    ?.copyWith(color: context.cs.onSurfaceVariant),
              ),
            ),
          const ListeAyraci(),
        ],
      ),
    );
  }
}
