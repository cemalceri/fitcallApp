// lib/screens/6_muhasebe/havale/widgets/dekont_detay.dart
//
// Dekont satırına dokununca açılan alt sayfa: durum, tutar, açıklama, ret
// gerekçesinin tamamı, dosyayı görme ve (bekliyorsa) geri çekme.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_listesi.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DekontDetayIcerik extends StatelessWidget {
  final DekontModel dekont;
  final VoidCallback? onDosyaGor;
  final VoidCallback? onGeriCek;
  final bool dosyaAciliyor;

  const DekontDetayIcerik({
    super.key,
    required this.dekont,
    this.onDosyaGor,
    this.onGeriCek,
    this.dosyaAciliyor = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = dekont;
    final cs = context.cs;
    final metin = context.metin;
    final r = context.renkler;
    final yuklenme = d.yuklenme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ListeAvatari(ikon: dekontIkonu(d.durum), ton: d.ton, cap: 40),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.durumMetni,
                        style: metin.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (yuklenme != null)
                      Text(
                        'Yüklendi ${DateFormat('d MMMM yyyy HH:mm', 'tr').format(yuklenme)}',
                        style: metin.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          _Bilgi(
            etiket: d.durum == DekontDurumu.islendi ? 'İşlenen tutar' : 'Yazdığın tutar',
            deger: dekontTutarMetni(d),
          ),
          if (d.durum == DekontDurumu.islendi && d.islenenUyeler.isNotEmpty)
            _Bilgi(etiket: 'Yazıldığı hesap', deger: d.islenenUyeler.join(', ')),
          if (d.aciklama.isNotEmpty) _Bilgi(etiket: 'Açıklaman', deger: d.aciklama),
          if (d.dosyaAdi.isNotEmpty)
            _Bilgi(etiket: 'Dosya', deger: '${d.dosyaAdi}${d.pdfMi ? ' (PDF)' : ''}'),
          if (d.durum == DekontDurumu.reddedildi && d.redNedeni.isNotEmpty)
            _Kutu(
              zemin: r.hataZemin,
              renk: r.hata,
              ikon: Icons.info_outline_rounded,
              baslik: 'Reddedilme gerekçesi',
              metin: d.redNedeni,
            ),
          if (d.yenidenKontrol)
            _Kutu(
              zemin: r.bilgiZemin,
              renk: r.bilgi,
              ikon: Icons.autorenew_rounded,
              baslik: 'Yeniden kontrol ediliyor',
              metin: 'Kulüp bu dekontun kaydını düzeltiyor. Bakiyen işlem '
                  'bitince güncellenir.',
            ),
          if (d.bekliyor && !d.yenidenKontrol)
            Padding(
              padding: const EdgeInsets.only(top: Bosluk.s),
              child: Text(
                'Bakiyen dekont kontrol edilip işlenince güncellenir.',
                style: metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: Bosluk.l),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.s,
            alignment: WrapAlignment.end,
            children: [
              if (onDosyaGor != null)
                OutlinedButton.icon(
                  onPressed: dosyaAciliyor ? null : onDosyaGor,
                  icon: dosyaAciliyor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: ButonYukleniyorGostergesi(),
                        )
                      : Icon(d.pdfMi
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined),
                  label: const Text('Dosyayı gör'),
                ),
              if (d.bekliyor && onGeriCek != null)
                YikiciButon(
                  etiket: 'Geri çek',
                  ikon: Icons.undo_rounded,
                  onPressed: onGeriCek,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bilgi extends StatelessWidget {
  final String etiket;
  final String deger;

  const _Bilgi({required this.etiket, required this.deger});

  @override
  Widget build(BuildContext context) {
    final metin = context.metin;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Bosluk.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket,
              style: metin.labelSmall
                  ?.copyWith(color: context.cs.onSurfaceVariant)),
          Text(deger, style: metin.bodyMedium),
        ],
      ),
    );
  }
}

class _Kutu extends StatelessWidget {
  final Color zemin;
  final Color renk;
  final IconData ikon;
  final String baslik;
  final String metin;

  const _Kutu({
    required this.zemin,
    required this.renk,
    required this.ikon,
    required this.baslik,
    required this.metin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Bosluk.s),
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 20),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: TextStyle(fontWeight: FontWeight.w700, color: renk)),
                const SizedBox(height: 2),
                Text(metin, style: TextStyle(color: renk, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
