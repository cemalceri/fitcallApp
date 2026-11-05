// lib/screens/8_ofis/ders_kayit_talepleri/widgets/ofis_talepler_gorunumu.dart
//
// Ofisin talepler sayfasının görsel gövdesi — API çağırmaz, testte render
// edilir. Üç sekme: Bende (karar sende; antrenörün ders kayıt talepleri de
// burada), Beklemede (hocada / üyede), Kapanan (son 30 gün, üye adıyla arama).
// Ofis para görmez: satırda yalnız "Paket yeterli / yetmiyor" gibi metin.

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/ders_kayit_talepleri_gorunumu.dart';
import 'package:flutter/material.dart';

IconData ofisTurIkonu(String tur) => switch (tur) {
      'TELAFI' => Icons.event_repeat_rounded,
      'PAKET' => Icons.confirmation_number_outlined,
      'TEK_DERS' => Icons.sports_tennis_rounded,
      _ => Icons.grid_view_rounded,
    };

class TalepCipi extends StatelessWidget {
  final String metin;
  final ListeTonu ton;
  final IconData? ikon;

  const TalepCipi(this.metin,
      {super.key, this.ton = ListeTonu.notr, this.ikon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: ton.zemin(context), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 13, color: ton.on(context)),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(metin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ton.on(context))),
          ),
        ],
      ),
    );
  }
}

class OfisTaleplerGorunumu extends StatelessWidget {
  final String sekme;
  final OfisTalepListesi? liste;
  final String? hata;
  final VoidCallback? onGeri;
  final ValueChanged<String> onSekme;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<OfisUyeTalep> onUyeTalepAc;
  final ValueChanged<String> onAra;
  final TextEditingController? aramaKontrol;

  // Antrenör talepleri (eski akış)
  final ValueChanged<DersKayitTalebi> onKayitOlustur;
  final ValueChanged<DersKayitTalebi> onReddet;
  final ValueChanged<DersKayitTalebi> onProgramdaGoster;
  final int? islenenTalepId;

  const OfisTaleplerGorunumu({
    super.key,
    required this.sekme,
    required this.liste,
    required this.onSekme,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onUyeTalepAc,
    required this.onAra,
    required this.onKayitOlustur,
    required this.onReddet,
    required this.onProgramdaGoster,
    this.aramaKontrol,
    this.hata,
    this.onGeri,
    this.islenenTalepId,
  });

  @override
  Widget build(BuildContext context) {
    final l = liste;
    return Column(
      children: [
        BaslikBandi(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 6),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                if (onGeri != null)
                  BaslikIkonButonu(
                      ikon: Icons.arrow_back_rounded,
                      ipucu: 'Geri',
                      onTap: onGeri!)
                else
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Talepler',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: baslikYazi(
                        context,
                        const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                OgrenmeButonu(
                  sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
                  sssRotasi: routeEnums[SayfaAdi.ofisYardim]!,
                  kutulu: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.xs),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: 'bende',
                    label: Text(
                        l == null || l.bendeSayisi == 0
                            ? 'Bende'
                            : 'Bende ${l.bendeSayisi}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                ButtonSegment(
                    value: 'beklemede',
                    label: Text(
                        l == null || l.beklemedeSayisi == 0
                            ? 'Beklemede'
                            : 'Beklemede ${l.beklemedeSayisi}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const ButtonSegment(
                    value: 'kapanan',
                    label: Text('Kapanan',
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              selected: {sekme},
              onSelectionChanged: (s) => onSekme(s.first),
            ),
          ),
        ),
        if (sekme == 'kapanan')
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.xs, Bosluk.l, Bosluk.xs),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: onAra,
              controller: aramaKontrol,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Üye adıyla ara',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        Expanded(child: _govde(context)),
      ],
    );
  }

  Widget _govde(BuildContext context) {
    final l = liste;
    if (l == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Talepler yüklenemedi',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
          ikonRengi: context.cs.error,
        );
      }
      return const IskeletListe();
    }
    final bos = l.talepler.isEmpty && l.antrenorTalepleri.isEmpty;
    // Rehber hedefleri: adımın gerektirdiği eylemi olan ilk satır.
    final onerilebilir = l.talepler.where((t) => t.eylemler.oneri).firstOrNull;
    final kaydedilir = l.talepler.where((t) => t.eylemler.kaydet).firstOrNull;
    return RefreshIndicator(
      onRefresh: onYenile,
      child: bos
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                BosDurum(
                  ikon: Icons.inbox_rounded,
                  baslik: switch (sekme) {
                    'beklemede' => 'Beklemede talep yok',
                    'kapanan' => 'Kapanan talep yok',
                    _ => 'Karar bekleyen talep yok',
                  },
                  aciklama:
                      'Üyelerin ders / kort kiralama ve antrenörlerin ders kayıt talepleri burada.',
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final t in l.talepler) ...[
                  ogrenmeHedefiSar(
                    identical(t, onerilebilir)
                        ? Hedef.ofisTalepOnerilebilir
                        : null,
                    ogrenmeHedefiSar(
                      identical(t, kaydedilir)
                          ? Hedef.ofisTalepKaydedilir
                          : null,
                      OfisUyeTalepSatiri(
                          talep: t, onTap: () => onUyeTalepAc(t)),
                    ),
                  ),
                  const ListeAyraci(),
                ],
                if (l.antrenorTalepleri.isNotEmpty) ...[
                  const ListeGrupBasligi(
                      baslik: 'Antrenör ders kayıt talepleri'),
                  for (final t in l.antrenorTalepleri) ...[
                    DersKayitTalebiSatiri(
                      talep: t,
                      kilitli: islenenTalepId != null,
                      onKayitOlustur: () => onKayitOlustur(t),
                      onReddet: () => onReddet(t),
                      onProgramdaGoster: () => onProgramdaGoster(t),
                    ),
                    const ListeAyraci(),
                  ],
                ],
              ],
            ),
    );
  }
}

String beklemeMetni(int dk) {
  if (dk < 60) return '$dk dk önce';
  if (dk < 60 * 24) return '${dk ~/ 60} saattir bekliyor';
  return '${dk ~/ (60 * 24)} gündür bekliyor';
}

class OfisUyeTalepSatiri extends StatelessWidget {
  final OfisUyeTalep talep;
  final VoidCallback onTap;

  const OfisUyeTalepSatiri(
      {super.key, required this.talep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = talep;
    final ciplar = <Widget>[
      if (t.etiketMetni.isNotEmpty)
        TalepCipi(t.etiketMetni,
            ton: t.etiketMetni == 'Tekrar bak' ||
                    t.etiketMetni == 'Hoca cevap vermedi'
                ? ListeTonu.uyari
                : ListeTonu.bilgi),
      if (t.kapanisMetni.isNotEmpty) TalepCipi(t.kapanisMetni),
      if (t.acil)
        const TalepCipi('Acil', ton: ListeTonu.hata, ikon: Icons.bolt_rounded),
      if (t.ayniSaate > 1)
        TalepCipi('Aynı saate ${t.ayniSaate} talep', ton: ListeTonu.uyari),
      if (t.inceleyenAdi.isNotEmpty)
        TalepCipi('${t.inceleyenAdi} bakıyor',
            ton: ListeTonu.vurgu, ikon: Icons.visibility_outlined),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListeAvatari(
              ikon: ofisTurIkonu(t.tur),
              ton: t.acil ? ListeTonu.hata : ListeTonu.vurgu,
            ),
            const SizedBox(width: Bosluk.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.uyeAdi} · ${t.turAdi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.titleSmall),
                  Text(t.dersTanimi,
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  Text('Hoca: ${t.antrenorAdi} · Kort: ${t.kortAdi}',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  Text(t.hakDurumu,
                      style: TextStyle(
                          fontSize: 13,
                          color: t.hakUygun
                              ? context.renkler.basari
                              : context.renkler.hata)),
                  if (t.cakisma.isNotEmpty)
                    Text(t.cakisma,
                        style: TextStyle(
                            fontSize: 13, color: context.renkler.hata)),
                  if (t.oneri != null && t.sekme == 'beklemede')
                    Text(
                        'Öneri: ${t.oneri!.dersTanimi}'
                        '${t.oneri!.sonCevapMetni.isNotEmpty ? ' · son cevap ${t.oneri!.sonCevapMetni}' : ''}',
                        style: TextStyle(fontSize: 13, color: cs.primary)),
                  if (t.olusanDersTanimi.isNotEmpty)
                    Text('Kaydedilen: ${t.olusanDersTanimi}',
                        style: TextStyle(
                            fontSize: 13, color: context.renkler.basari)),
                  if (t.beklemeDk != null && t.sekme == 'bende')
                    Text(
                        t.beklemeMetni.isNotEmpty
                            ? t.beklemeMetni
                            : beklemeMetni(t.beklemeDk!),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  if (ciplar.isNotEmpty) ...[
                    const SizedBox(height: Bosluk.xs),
                    Wrap(
                        spacing: Bosluk.xs,
                        runSpacing: Bosluk.xs,
                        children: ciplar),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline),
          ],
        ),
      ),
    );
  }
}
