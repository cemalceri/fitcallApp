// lib/screens/2_uye/talep/widgets/talep_adimlari.dart
//
// Talep sihirbazının üç adımının görsel gövdeleri — API
// çağırmaz, testte doğrudan render edilir (sayfa: ../uye_talep_page.dart).
//   1. Neyle?   : telafi · paketim · tek seferlik ders · kort kiralama
//   2. Ne zaman?: süre + hoca şeridi, haftalık uygunluk haritası
//   3. Detay    : hoca, kort, esneme, kişi sayısı, açıklama, ücret/düşüm satırı

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/uygunluk_haritasi.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

IconData turIkonu(String tur) => switch (tur) {
      TalepTuru.telafi => Icons.event_repeat_rounded,
      TalepTuru.paket => Icons.confirmation_number_outlined,
      TalepTuru.tekDers => Icons.sports_tennis_rounded,
      _ => Icons.grid_view_rounded,
    };

String sureMetni(int dk) {
  if (dk % 60 == 0) return '${dk ~/ 60} saat';
  if (dk < 60) return '$dk dk';
  return '${dk ~/ 60},5 saat';
}

class _Bilgi extends StatelessWidget {
  final String metin;
  final ListeTonu ton;
  final IconData ikon;

  const _Bilgi(this.metin,
      {this.ton = ListeTonu.bilgi, this.ikon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: ton.on(context)),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(metin,
                style: TextStyle(fontSize: 13, color: context.cs.onSurface)),
          ),
        ],
      ),
    );
  }
}

/* ================================ 1. adım ================================ */

class TalepAdim1Gorunumu extends StatelessWidget {
  final TalepBaslangic veri;
  final String? seciliTur;
  final int seciliUyeId;
  final ValueChanged<int> onUyeSec;
  final ValueChanged<String> onTurSec;
  final VoidCallback? onDevam;
  final VoidCallback onTaleplerim;

  const TalepAdim1Gorunumu({
    super.key,
    required this.veri,
    required this.seciliTur,
    required this.seciliUyeId,
    required this.onUyeSec,
    required this.onTurSec,
    required this.onDevam,
    required this.onTaleplerim,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xl),
      children: [
        if (veri.kiminIcin.length > 1) ...[
          Text('Kimin için?', style: context.metin.titleSmall),
          const SizedBox(height: Bosluk.s),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.xs,
            children: [
              for (final k in veri.kiminIcin)
                ChoiceChip(
                  label: Text(k.ad),
                  selected: k.id == seciliUyeId,
                  onSelected: (_) => onUyeSec(k.id),
                ),
            ],
          ),
          const SizedBox(height: Bosluk.l),
        ],
        Text('Neyle?', style: context.metin.titleSmall),
        const SizedBox(height: Bosluk.s),
        OgrenmeHedefi(
          id: Hedef.uyeTalepTurleri,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in veri.secenekler)
                _SecenekSatiri(
                  secenek: s,
                  secili: s.tur == seciliTur,
                  onTap: s.uygun ? () => onTurSec(s.tur) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: Bosluk.m),
        if (veri.mesaiNotu.isNotEmpty) ...[
          _Bilgi(veri.mesaiNotu, ikon: Icons.schedule_rounded),
          const SizedBox(height: Bosluk.s),
        ],
        if (!veri.acikMi)
          const _Bilgi('Talep açma şu an kapalı.', ton: ListeTonu.uyari)
        else if (veri.limitDoldu)
          _Bilgi(
            'En fazla ${veri.maxAcik} açık talebin olabilir. '
            'Yenisi için birini bekle ya da geri çek.',
            ton: ListeTonu.uyari,
          ),
        const SizedBox(height: Bosluk.l),
        FilledButton(
          onPressed: onDevam,
          child: const Text('Devam'),
        ),
        const SizedBox(height: Bosluk.s),
        TextButton.icon(
          onPressed: onTaleplerim,
          icon: const Icon(Icons.list_alt_rounded),
          label: Text(veri.acikTalepSayisi > 0
              ? 'Taleplerim (${veri.acikTalepSayisi} açık)'
              : 'Taleplerim'),
        ),
      ],
    );
  }
}

class _SecenekSatiri extends StatelessWidget {
  final TalepSecenegi secenek;
  final bool secili;
  final VoidCallback? onTap;

  const _SecenekSatiri(
      {required this.secenek, required this.secili, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final pasif = onTap == null;
    final renk = pasif ? cs.outline : cs.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: Bosluk.s),
      child: Material(
        color: secili ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Bosluk.m, vertical: Bosluk.m),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: secili ? cs.primary : cs.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  secili
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: pasif ? cs.outline : cs.primary,
                ),
                const SizedBox(width: Bosluk.m),
                Icon(turIkonu(secenek.tur), size: 20, color: renk),
                const SizedBox(width: Bosluk.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(secenek.baslik,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: renk)),
                      if (secenek.aciklama.isNotEmpty)
                        Text(secenek.aciklama,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
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

/* ================================ 2. adım ================================ */

class TalepAdim2Gorunumu extends StatelessWidget {
  final String tur;
  final TalepBaslangic veri;
  final int sureDk;
  final int? antrenorId;
  final TalepHarita? harita;
  final String? hata;
  final DateTime? secili;
  final ValueChanged<int> onSure;
  final ValueChanged<int?> onHoca;
  final ValueChanged<int> onHafta; // -1 önceki, +1 sonraki
  final ValueChanged<DateTime> onSaatSec;
  final VoidCallback onYenidenDene;
  final VoidCallback? onDevam;

  const TalepAdim2Gorunumu({
    super.key,
    required this.tur,
    required this.veri,
    required this.sureDk,
    required this.antrenorId,
    required this.harita,
    required this.secili,
    required this.onSure,
    required this.onHoca,
    required this.onHafta,
    required this.onSaatSec,
    required this.onYenidenDene,
    required this.onDevam,
    this.hata,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final telafi = veri.secenek(TalepTuru.telafi);
    final sabitSure = tur == TalepTuru.telafi ? telafi?.sabitSureDk : null;
    final h = harita;

    return Column(
      children: [
        // Şerit: süre + hoca
        Container(
          color: cs.surface,
          padding:
              const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sabitSure != null)
                Text('Süre: ${sureMetni(sabitSure)} (telafide değişmez)',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))
              else
                Wrap(
                  spacing: Bosluk.s,
                  runSpacing: Bosluk.xs,
                  children: [
                    for (final s in veri.surelerDk)
                      ChoiceChip(
                        label: Text(sureMetni(s)),
                        selected: s == sureDk,
                        onSelected: (_) => onSure(s),
                      ),
                  ],
                ),
              if (TalepTuru.hocali(tur)) ...[
                const SizedBox(height: Bosluk.s),
                DropdownButtonFormField<int?>(
                  key: ValueKey('ac1-$antrenorId'),
                  initialValue: antrenorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Hoca',
                      isDense: true,
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Fark etmez')),
                    for (final hc in veri.hocalar)
                      DropdownMenuItem<int?>(
                          value: hc.id,
                          child: Text(hc.ad, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: onHoca,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: h == null
              ? (hata != null
                  ? BosDurum(
                      ikon: Icons.error_outline_rounded,
                      baslik: 'Harita yüklenemedi',
                      aciklama: hata!,
                      eylemEtiketi: 'Tekrar dene',
                      eylemIkonu: Icons.refresh_rounded,
                      onEylem: onYenidenDene,
                    )
                  : const IskeletTakvim())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Bosluk.m, Bosluk.s, Bosluk.m, Bosluk.l),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Önceki hafta',
                          onPressed: h.oncekiHafta ? () => onHafta(-1) : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '${DateFormat('d MMM', 'tr_TR').format(h.haftaBaslangic)} – '
                            '${DateFormat('d MMM', 'tr_TR').format(h.haftaBaslangic.add(const Duration(days: 6)))}',
                            textAlign: TextAlign.center,
                            style: context.metin.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sonraki hafta',
                          onPressed: h.sonrakiHafta ? () => onHafta(1) : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    Text('Uygun bir kareye dokun.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: Bosluk.s),
                    UygunlukHaritasi(
                        harita: h, secili: secili, onSec: onSaatSec),
                    const SizedBox(height: Bosluk.m),
                    const HaritaLejanti(),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.m),
            // Saat seçilmeden hedef yok: kare kaybolunca (hafta değişti)
            // rehber pasif düğmeye atlamasın.
            child: ogrenmeHedefiSar(
              onDevam == null ? null : Hedef.uyeTalepSaatDevam,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDevam,
                  child: Text(secili == null
                      ? 'Saat seç'
                      : '${DateFormat('d MMM EEE HH:mm', 'tr_TR').format(secili!)} · Devam'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ================================ 3. adım ================================ */

class TalepAdim3Gorunumu extends StatelessWidget {
  final String tur;
  final TalepBaslangic veri;
  final TalepSecenekleri? secenekler;
  final String? hata;
  final int? antrenorId;
  final int? kortId;
  final bool esneme;
  final int kisiSayisi;
  final TextEditingController aciklama;
  final bool gonderiliyor;
  final ValueChanged<int?> onHoca;
  final ValueChanged<int?> onKort;
  final ValueChanged<bool> onEsneme;
  final ValueChanged<int> onKisi;
  final VoidCallback onYenidenDene;
  final VoidCallback? onGonder;

  /// Paket yetmiyorsa süreyi en kısaya çevirir (null: düğme yok).
  final VoidCallback? onSureyiKisalt;

  const TalepAdim3Gorunumu({
    super.key,
    required this.tur,
    required this.veri,
    required this.secenekler,
    required this.antrenorId,
    required this.kortId,
    required this.esneme,
    required this.kisiSayisi,
    required this.aciklama,
    required this.gonderiliyor,
    required this.onHoca,
    required this.onKort,
    required this.onEsneme,
    required this.onKisi,
    required this.onYenidenDene,
    required this.onGonder,
    this.onSureyiKisalt,
    this.hata,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = secenekler;
    if (s == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Seçenekler yüklenemedi',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
        );
      }
      return const IskeletListe();
    }
    final tahmin = s.tahminFor(antrenorId);
    final hocaVar =
        antrenorId == null || s.hocalar.any((h) => h.id == antrenorId);
    final kortVar = kortId == null || s.kortlar.any((k) => k.id == kortId);

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xl),
      children: [
        Text(s.dersTanimi, style: context.metin.titleMedium),
        Text('${sureMetni(s.sureDk)} · ${veri.secenek(tur)?.baslik ?? ''}',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: Bosluk.l),
        if (TalepTuru.hocali(tur)) ...[
          DropdownButtonFormField<int?>(
            key: ValueKey('ac2-${hocaVar ? antrenorId : null}'),
            initialValue: hocaVar ? antrenorId : null,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Hoca (o saatte boş olanlar)',
                border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('Fark etmez')),
              for (final h in s.hocalar)
                DropdownMenuItem<int?>(
                    value: h.id,
                    child: Text(h.ad, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onHoca,
          ),
          const SizedBox(height: Bosluk.m),
        ] else ...[
          const _Bilgi('Kort kiralama antrenörsüzdür.',
              ikon: Icons.person_off_outlined),
          const SizedBox(height: Bosluk.m),
        ],
        DropdownButtonFormField<int?>(
          key: ValueKey('ac3-${kortVar ? kortId : null}'),
          initialValue: kortVar ? kortId : null,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Kort (o saatte boş olanlar)',
              border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('Fark etmez')),
            for (final k in s.kortlar)
              DropdownMenuItem<int?>(
                  value: k.id,
                  child: Text(k.ad, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onKort,
        ),
        if (tur == TalepTuru.kort) ...[
          const SizedBox(height: Bosluk.m),
          Row(
            children: [
              Expanded(
                  child: Text('Kaç kişi oynayacak?',
                      style: context.metin.bodyMedium)),
              IconButton(
                tooltip: 'Azalt',
                onPressed: kisiSayisi > 1 ? () => onKisi(kisiSayisi - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$kisiSayisi', style: context.metin.titleMedium),
              IconButton(
                tooltip: 'Artır',
                onPressed: kisiSayisi < veri.maxKisi
                    ? () => onKisi(kisiSayisi + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Text('Kişi sayısı yalnız bilgi içindir, ücreti değiştirmez.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: Bosluk.s),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: esneme,
          onChanged: onEsneme,
          title: Text('${veri.esnemeSaat} saat esnetebilirim'),
          subtitle: const Text('Ofis saati sana sormadan biraz kaydırabilir.'),
        ),
        const SizedBox(height: Bosluk.s),
        TextField(
          controller: aciklama,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Açıklama (isteğe bağlı)',
            hintText:
                'Diğer tüm detay ve taleplerinizi buraya iletebilirsiniz.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: Bosluk.s),
        if (tahmin.metin.isNotEmpty)
          _Bilgi(tahmin.metin, ton: ListeTonu.vurgu, ikon: turIkonu(tur)),
        if (tahmin.paketYetmiyor && tahmin.uyari.isNotEmpty) ...[
          const SizedBox(height: Bosluk.s),
          _Bilgi(tahmin.uyari,
              ton: ListeTonu.uyari, ikon: Icons.warning_amber_rounded),
          if (onSureyiKisalt != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onSureyiKisalt,
                icon: const Icon(Icons.timelapse_rounded, size: 18),
                label: Text('Süreyi ${sureMetni(veri.surelerDk.first)} yap'),
              ),
            ),
        ],
        if (antrenorId == null &&
            TalepTuru.hocali(tur) &&
            tur == TalepTuru.paket)
          Padding(
            padding: const EdgeInsets.only(top: Bosluk.xs),
            child: Text(
                'Düşecek ders, ofisin seçeceği hocaya göre değişebilir.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        if (!s.uyeBos) ...[
          const SizedBox(height: Bosluk.s),
          const _Bilgi('Bu saatte başka dersin ya da talebin var.',
              ton: ListeTonu.hata),
        ],
        if (veri.iptalKurali.isNotEmpty) ...[
          const SizedBox(height: Bosluk.m),
          Text(veri.iptalKurali,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: Bosluk.l),
        FilledButton(
          onPressed: gonderiliyor ? null : onGonder,
          child: gonderiliyor
              ? const ButonYukleniyorGostergesi()
              : const Text('Ofise gönder'),
        ),
      ],
    );
  }
}
