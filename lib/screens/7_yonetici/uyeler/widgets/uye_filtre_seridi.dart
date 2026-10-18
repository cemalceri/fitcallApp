// lib/screens/7_yonetici/uyeler/widgets/uye_filtre_seridi.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Arama kutusunun altındaki iki düğme: **Filtrele (n)** ve **Sırala: …**.
///
/// Başlık bandının üstünde durur; kartlar gibi `surface` zeminli, filtre
/// varken Filtrele düğmesi vurgulu.
class UyeFiltreDugmeleri extends StatelessWidget {
  final UyeFiltreleri filtreler;
  final UyeSiralama siralama;
  final VoidCallback onFiltrele;
  final VoidCallback onSirala;

  const UyeFiltreDugmeleri({
    super.key,
    required this.filtreler,
    required this.siralama,
    required this.onFiltrele,
    required this.onSirala,
  });

  static const double _dikey = 8;
  static const double _yaziBoyu = 13;

  /// Başlık şeridinin (SliverAppBar bottom) hesabı için; yazı ölçeği 1.3'e
  /// çıkabildiği için sabit değer verilmez.
  static double yukseklik(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    final yazi = olcek.scale(_yaziBoyu) * 1.3;
    return _dikey * 2 + (yazi > 18 ? yazi : 18) + 2; // ikon 18, kenarlık
  }

  @override
  Widget build(BuildContext context) {
    final sayi = filtreler.aktifSayisi;
    return SizedBox(
      height: yukseklik(context),
      child: Row(
        children: [
          Expanded(
            child: _SeritDugmesi(
              ikon: Icons.tune_rounded,
              etiket: sayi > 0 ? 'Filtrele ($sayi)' : 'Filtrele',
              anlam: sayi > 0 ? 'Filtrele, $sayi filtre etkin' : 'Filtrele',
              etkin: sayi > 0,
              onTap: onFiltrele,
            ),
          ),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: _SeritDugmesi(
              ikon: Icons.swap_vert_rounded,
              etiket: 'Sırala: ${siralama.kisaEtiket}',
              anlam: 'Sırala, şu an ${siralama.etiket}',
              etkin: siralama != UyeSiralama.varsayilan,
              onTap: onSirala,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeritDugmesi extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final String anlam;
  final bool etkin;
  final VoidCallback onTap;

  const _SeritDugmesi({
    required this.ikon,
    required this.etiket,
    required this.anlam,
    required this.etkin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const ton = ListeTonu.vurgu;
    final on = etkin ? ton.on(context) : cs.onSurface;
    final yaricap = BorderRadius.circular(Yaricap.m);
    return Semantics(
      button: true,
      label: anlam,
      excludeSemantics: true,
      child: Material(
        color: etkin ? ton.zemin(context) : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: yaricap,
          side: BorderSide(
            color: etkin ? on : cs.outlineVariant,
            width: etkin ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: yaricap,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.m,
              vertical: UyeFiltreDugmeleri._dikey,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ikon, size: 18, color: on),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    etiket,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: UyeFiltreDugmeleri._yaziBoyu,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: on,
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

/// Listenin üstünde: etkin filtre çipleri (her birinde ×), "Tümünü temizle"
/// ve süzülen kümenin özeti ("37 üye · 48.200 ₺ borç").
class UyeEtkinFiltreler extends StatelessWidget {
  final UyeFiltreleri filtreler;
  final UyeFiltreOzeti? ozet;
  final ValueChanged<UyeFiltreleri> onDegistir;

  const UyeEtkinFiltreler({
    super.key,
    required this.filtreler,
    required this.ozet,
    required this.onDegistir,
  });

  static final _tl =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  static final _sayi = NumberFormat.decimalPattern('tr_TR');

  /// "37 üye · 48.200 ₺ borç"; borç yoksa yalnız üye sayısı.
  static String ozetMetni(UyeFiltreOzeti ozet) {
    final uye = '${_sayi.format(ozet.uyeSayisi)} üye';
    if (ozet.toplamBorc <= 0) return uye;
    return '$uye · ${_tl.format(ozet.toplamBorc)} borç';
  }

  @override
  Widget build(BuildContext context) {
    final cipler = filtreler.cipler;
    final o = ozet;
    if (cipler.isEmpty && o == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cipler.isNotEmpty)
            Wrap(
              spacing: Bosluk.s,
              runSpacing: Bosluk.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final cip in cipler)
                  InputChip(
                    label: Text(cip.etiket),
                    onDeleted: () => onDegistir(cip.kaldirilmis),
                    deleteButtonTooltipMessage: 'Kaldır',
                    visualDensity: VisualDensity.compact,
                  ),
                TextButton(
                  onPressed: () => onDegistir(UyeFiltreleri.bos),
                  child: const Text('Tümünü temizle'),
                ),
              ],
            ),
          if (o != null)
            Padding(
              padding: EdgeInsets.only(top: cipler.isEmpty ? 0 : Bosluk.xs),
              child: Text(
                ozetMetni(o),
                style: context.metin.labelLarge?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
