// lib/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

/// Antrenör listesi satırı — ortak [ListeSatiri] kalıbı üzerine kurulu.
class AntrenorListeItemWidget extends StatelessWidget {
  final AntrenorListeItem antrenor;
  final VoidCallback? onTap;

  const AntrenorListeItemWidget({
    super.key,
    required this.antrenor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(antrenor.adSoyad),
        ton: antrenor.aktifMi ? ListeTonu.bilgi : ListeTonu.notr,
      ),
      baslik: antrenor.adSoyad,
      rozet: antrenor.aktifMi ? null : const _PasifRozeti(),
      altBaslik: 'Bugün ${antrenor.bugunDersSayisi} ders · '
          'hafta ${antrenor.haftalikDersSayisi} · '
          '${antrenor.ogrenciSayisi} öğrenci',
      sonEk: _Puan(puan: antrenor.ortalamaPuan),
      okGoster: onTap != null,
      onTap: onTap,
    );
  }
}

/// Ortalama puan rozeti.
///
/// Puan yokken tire koymak bir durum değil, boşluk işareti — okuyan "veri mi
/// yok, sıfır mı?" diye takılıyor. Rozet aynı biçimde kalır, yalnız içeriği ve
/// tonu değişir: dolu yıldız + puan, ya da içi boş yıldız + "Puan yok".
class _Puan extends StatelessWidget {
  final double? puan;

  const _Puan({required this.puan});

  @override
  Widget build(BuildContext context) {
    final renkler = context.renkler;
    final puanVar = puan != null;

    final zemin = puanVar ? renkler.uyariZemin : context.cs.surfaceContainer;
    final on = puanVar ? renkler.uyari : context.cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 3),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            puanVar ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: on,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              puanVar ? puan!.toStringAsFixed(1) : 'Puan yok',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.labelLarge?.copyWith(color: on),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasifRozeti extends StatelessWidget {
  const _PasifRozeti();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        'Pasif',
        style: context.metin.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
