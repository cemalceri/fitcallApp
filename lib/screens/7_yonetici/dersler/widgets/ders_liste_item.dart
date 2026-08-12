// lib/screens/7_yonetici/dersler/widgets/ders_liste_item.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

/// Ders listesi satırı — ortak [ListeSatiri] kalıbı üzerine kurulu.
///
/// Avatar yerine saat bloğu duruyor: ders listesinde satırı ayırt eden şey
/// kişi değil, saat.
class DersListeItemWidget extends StatelessWidget {
  final DersListeItem ders;
  final VoidCallback? onTap;

  const DersListeItemWidget({
    super.key,
    required this.ders,
    this.onTap,
  });

  /// Ders durumunun anlam tonu — renkler temadan gelir, sabit `Colors.green`
  /// gibi değerler koyu temada okunmuyordu.
  static ListeTonu tonu(String durum) => switch (durum) {
        'tamamlandi' => ListeTonu.basari,
        'devam_ediyor' => ListeTonu.bilgi,
        'iptal' => ListeTonu.hata,
        _ => ListeTonu.uyari,
      };

  String _altBaslik() {
    final antrenor = ders.antrenorAdi ?? 'Antrenör belirtilmedi';
    return '$antrenor · ${ders.katilimciSayisi} katılımcı';
  }

  @override
  Widget build(BuildContext context) {
    final ton = tonu(ders.durum);

    return ListeSatiri(
      onGorsel: _SaatBloku(saat: ders.saat, ton: ton),
      baslik: ders.kortAdi ?? 'Kort belirtilmedi',
      rozet: _DurumRozeti(ton: ton, etiket: ders.durumText),
      altBaslik: _altBaslik(),
      okGoster: onTap != null,
      onTap: onTap,
    );
  }
}

/// Satırın solundaki saat bloğu — durum rengiyle zeminlenmiş.
class _SaatBloku extends StatelessWidget {
  final String saat;
  final ListeTonu ton;

  const _SaatBloku({required this.saat, required this.ton});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: Bosluk.s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Text(
        saat,
        maxLines: 1,
        style: context.metin.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: ton.on(context),
        ),
      ),
    );
  }
}

class _DurumRozeti extends StatelessWidget {
  final ListeTonu ton;
  final String etiket;

  const _DurumRozeti({required this.ton, required this.etiket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        etiket,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.metin.labelSmall?.copyWith(color: ton.on(context)),
      ),
    );
  }
}
