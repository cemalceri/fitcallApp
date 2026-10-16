// lib/screens/1_common/degerlendirmeler/widgets/degerlendirme_detayi.dart
//
// Tek değerlendirmenin alt sayfası: puan, tam yorum, dersin bilgileri ve
// diğer katılımcıların kendi puanları. Listede satıra dokununca açılır.
// API çağrısı içermez; taşma testinde doğrudan çizilir.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Değerlendirme detayını alt sayfada açar.
Future<void> degerlendirmeDetayiAc(
    BuildContext context, DersDegerlendirmesi degerlendirme) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, kaydirma) => DegerlendirmeDetayi(
        degerlendirme: degerlendirme,
        kaydirma: kaydirma,
      ),
    ),
  );
}

class DegerlendirmeDetayi extends StatelessWidget {
  final DersDegerlendirmesi degerlendirme;
  final ScrollController? kaydirma;

  const DegerlendirmeDetayi({
    super.key,
    required this.degerlendirme,
    this.kaydirma,
  });

  static final _gun = DateFormat('d MMMM y, EEEE', 'tr_TR');
  static final _saat = DateFormat('HH:mm', 'tr_TR');
  static final _kisaGun = DateFormat('d MMM y', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final d = degerlendirme;
    final ders = d.ders;
    final digerleri = ders.digerKatilimcilar;

    return ListView(
      controller: kaydirma,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, Bosluk.xl),
      children: [
        _ust(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.l),
          child: _yorum(context),
        ),
        const ListeGrupBasligi(baslik: 'Ders'),
        if (ders.iptalMi)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.m, Bosluk.l, 0),
            child: _IptalNotu(),
          ),
        _BilgiSatiri(
          ikon: Icons.event_rounded,
          etiket: 'Tarih',
          deger: _gun.format(ders.baslangic),
        ),
        _BilgiSatiri(
          ikon: Icons.schedule_rounded,
          etiket: 'Saat',
          deger:
              '${_saat.format(ders.baslangic)} – ${_saat.format(ders.bitis)}',
        ),
        if (ders.kortAdi.isNotEmpty)
          _BilgiSatiri(
            ikon: Icons.place_outlined,
            etiket: 'Kort',
            deger: ders.kortAdi,
          ),
        if (ders.antrenorAdi.isNotEmpty)
          _BilgiSatiri(
            ikon: Icons.sports_tennis_rounded,
            etiket: 'Antrenör',
            deger: ders.yardimciAntrenorAdi == null
                ? ders.antrenorAdi
                : '${ders.antrenorAdi} · yardımcı ${ders.yardimciAntrenorAdi}',
          ),
        if (ders.urunAdi.isNotEmpty)
          _BilgiSatiri(
            ikon: Icons.inventory_2_outlined,
            etiket: 'Ders',
            deger: ders.urunAdi,
          ),
        const SizedBox(height: Bosluk.m),
        ListeGrupBasligi(
          baslik: 'Diğer katılımcılar',
          sayi: digerleri.isEmpty ? null : digerleri.length,
        ),
        if (digerleri.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.m, Bosluk.l, 0),
            child: Text(
              'Derste başka katılımcı yoktu.',
              style: context.metin.bodyMedium
                  ?.copyWith(color: context.cs.onSurfaceVariant),
            ),
          )
        else
          for (var i = 0; i < digerleri.length; i++) ...[
            if (i > 0) const ListeAyraci(solBosluk: 64),
            _KatilimciSatiri(kisi: digerleri[i]),
          ],
      ],
    );
  }

  Widget _ust(BuildContext context) {
    final d = degerlendirme;
    final tarih = d.tarih;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
      child: Row(
        children: [
          ListeAvatari(
            basHarfler: ListeAvatari.harfler(d.degerlendiren.adSoyad),
            fotoUrl: d.degerlendiren.profilFotografi,
            cap: 48,
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.degerlendiren.adSoyad,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                YildizSirasi(puan: d.puan, boyut: 22),
                if (tarih != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_kisaGun.format(tarih)} tarihinde puanladı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.metin.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yorum(BuildContext context) {
    final yorum = degerlendirme.yorum;
    final cs = context.cs;
    if (yorum == null) {
      return Text(
        'Yorum yazılmamış.',
        style: context.metin.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(Yaricap.m),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: SelectableText(yorum, style: context.metin.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final String deger;

  const _BilgiSatiri({
    required this.ikon,
    required this.etiket,
    required this.deger,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: Bosluk.m),
          SizedBox(
            width: 72,
            child: Text(
              etiket,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(deger, style: context.metin.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _IptalNotu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final renkler = context.renkler;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Bosluk.m, vertical: Bosluk.s),
      decoration: BoxDecoration(
        color: renkler.hataZemin,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded, size: 18, color: renkler.hata),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(
              'Bu ders sonradan iptal edildi.',
              style: context.metin.bodySmall?.copyWith(color: renkler.hata),
            ),
          ),
        ],
      ),
    );
  }
}

class _KatilimciSatiri extends StatelessWidget {
  final DegerlendirmeKatilimcisi kisi;

  const _KatilimciSatiri({required this.kisi});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final notlar = [
      if (kisi.misafir) 'Misafir',
      if (kisi.katildi == false) 'Derse gelmedi',
    ];
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Bosluk.l, vertical: Bosluk.s),
      child: Row(
        children: [
          ListeAvatari(
            basHarfler: ListeAvatari.harfler(kisi.adSoyad),
            fotoUrl: kisi.profilFotografi,
            ton: kisi.misafir ? ListeTonu.notr : ListeTonu.bilgi,
            cap: 36,
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kisi.adSoyad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodyLarge,
                ),
                if (notlar.isNotEmpty)
                  Text(
                    notlar.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.metin.labelSmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: Bosluk.s),
          if (kisi.puan != null)
            PuanRozeti(puan: kisi.puan!.toDouble(), tamSayi: true)
          else if (!kisi.misafir)
            Text(
              'Puanlamadı',
              maxLines: 1,
              style: context.metin.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
