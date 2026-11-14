// lib/screens/2_uye/talep/widgets/taleplerim_gorunumu.dart
//
// "Taleplerim" listesi ve talep detayı — API çağırmaz, testte render edilir.
// Durumlar: Ofiste · Cevabını bekliyor · Onaylandı · Kapandı (nedenle).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/talep_adimlari.dart';
import 'package:material_ui/material_ui.dart';

ListeTonu talepTonu(UyeTalep t) => switch (t.uyeDurum) {
      'CEVAP_BEKLIYOR' => ListeTonu.uyari,
      'ONAYLANDI' => ListeTonu.basari,
      'OFISTE' => ListeTonu.bilgi,
      _ => ListeTonu.notr,
    };

class TalepDurumCipi extends StatelessWidget {
  final UyeTalep talep;

  const TalepDurumCipi({super.key, required this.talep});

  @override
  Widget build(BuildContext context) {
    final ton = talepTonu(talep);
    final metin = talep.uyeDurum == 'KAPANDI'
        ? 'Kapandı · ${talep.durumMetni}'
        : talep.durumMetni;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: ton.zemin(context), borderRadius: BorderRadius.circular(20)),
      child: Text(metin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ton.on(context))),
    );
  }
}

class TaleplerimGorunumu extends StatelessWidget {
  final List<UyeTalep>? talepler;
  final String? hata;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<UyeTalep> onAc;
  final VoidCallback onYeni;

  const TaleplerimGorunumu({
    super.key,
    required this.talepler,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onAc,
    required this.onYeni,
    this.hata,
  });

  @override
  Widget build(BuildContext context) {
    final liste = talepler;
    if (liste == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Talepler yüklenemedi',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenidenDene,
        );
      }
      return const IskeletListe();
    }
    // Rehber hedefleri: adımın gerektirdiği durumdaki ilk talep.
    final onerili =
        liste.where((t) => t.cevapBekliyor && t.oneri != null).firstOrNull;
    final geriCekilir = liste.where((t) => t.geriCekilebilir).firstOrNull;
    List<String> hedefler(UyeTalep t) => [
          if (identical(t, onerili)) Hedef.uyeTalepOnerili,
          if (identical(t, geriCekilir)) Hedef.uyeTalepGeriCekilir,
        ];
    return RefreshIndicator(
      onRefresh: onYenile,
      child: liste.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                BosDurum(
                  ikon: Icons.event_available_rounded,
                  baslik: 'Henüz talebin yok',
                  aciklama: 'Ders ya da kort için talep aç, ofis sana dönsün.',
                  eylemEtiketi: 'Talep aç',
                  eylemIkonu: Icons.add_rounded,
                  onEylem: onYeni,
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                ..._grup('Açık talepler', liste.where((t) => t.acik), hedefler),
                ..._grup(
                    'Geçmiş talepler', liste.where((t) => !t.acik), hedefler),
              ],
            ),
    );
  }

  /// Başlık + satırlar; boş grup hiç görünmez.
  List<Widget> _grup(String baslik, Iterable<UyeTalep> talepler,
      List<String> Function(UyeTalep) hedefler) {
    final grup = talepler.toList();
    if (grup.isEmpty) return const [];
    return [
      ListeGrupBasligi(baslik: baslik, sayi: grup.length),
      for (var i = 0; i < grup.length; i++) ...[
        if (i > 0) const ListeAyraci(),
        hedefler(grup[i]).fold<Widget>(
            _satir(grup[i]), (cocuk, id) => ogrenmeHedefiSar(id, cocuk)),
      ],
    ];
  }

  Widget _satir(UyeTalep t) => ListeSatiri(
        onGorsel: ListeAvatari(ikon: turIkonu(t.tur), ton: talepTonu(t)),
        // Onaylananda istenen değil kaydedilen ders görünür
        // (saat kaymış, "Fark etmez" hoca/kort atanmış olabilir).
        baslik: t.uyeDurum == 'ONAYLANDI' && t.dersAciklamasi.isNotEmpty
            ? '${t.turAdi} · ${t.dersAciklamasi}'
            : '${t.turAdi} · ${t.dersTanimi}',
        altBaslik: t.cevapBekliyor && t.oneri != null
            ? 'Öneri: ${t.oneri!.dersTanimi}'
            : '${t.antrenorAdi} · ${t.kortAdi}${t.uyeAdi.isNotEmpty ? ' · ${t.uyeAdi}' : ''}',
        sonEk: TalepDurumCipi(talep: t),
        okGoster: true,
        onTap: () => onAc(t),
      );
}

/// Talep detayı (alt sayfa). Öneri varsa Kabul et / Reddet; açık talepte
/// Geri çek ve (Ofiste iken) Düzenle; kapanmışsa Benzerini aç.
class TalepDetayGorunumu extends StatelessWidget {
  final UyeTalep talep;
  final bool isleniyor;
  final VoidCallback onKabul;
  final VoidCallback onReddet;
  final VoidCallback onGeriCek;
  final VoidCallback onDuzenle;
  final VoidCallback onBenzeri;

  const TalepDetayGorunumu({
    super.key,
    required this.talep,
    required this.isleniyor,
    required this.onKabul,
    required this.onReddet,
    required this.onGeriCek,
    required this.onDuzenle,
    required this.onBenzeri,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = talep;
    final o = t.oneri;
    Widget satir(String etiket, String deger) => Padding(
          padding: const EdgeInsets.only(bottom: Bosluk.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(etiket,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
              Expanded(
                  child: Text(deger, style: const TextStyle(fontSize: 14))),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.turAdi, style: context.metin.titleMedium)),
              TalepDurumCipi(talep: t),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          satir('İstediğin', t.dersTanimi),
          satir('Süre', sureMetni(t.sureDk)),
          satir('Hoca', t.antrenorAdi),
          satir('Kort', t.kortAdi),
          if (t.kisiSayisi != null) satir('Kişi', '${t.kisiSayisi}'),
          if (t.esneme) satir('Esneme', 'Saat biraz kayabilir'),
          if (t.uyeAdi.isNotEmpty) satir('Kimin için', t.uyeAdi),
          if (t.aciklama.isNotEmpty) satir('Açıklaman', t.aciklama),
          if (t.ozet.isNotEmpty) satir('Tahmini', t.ozet),
          if (t.dersAciklamasi.isNotEmpty) satir('Ders', t.dersAciklamasi),
          for (final d in t.dersDegisenler) satir('Değişen', d),
          if (t.redNedeni.isNotEmpty) satir('Neden', t.redNedeni),
          if (o != null && t.cevapBekliyor) ...[
            const SizedBox(height: Bosluk.m),
            OgrenmeHedefi(
              id: Hedef.uyeTalepOneri,
              child: Container(
                padding: const EdgeInsets.all(Bosluk.m),
                decoration: BoxDecoration(
                  color: ListeTonu.uyari.zemin(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ofisin önerisi', style: context.metin.titleSmall),
                    const SizedBox(height: Bosluk.xs),
                    Text(o.dersTanimi,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(sureMetni(o.sureDk),
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    if (o.kisiSayisi != null)
                      Text('${o.kisiSayisi} kişi',
                          style: const TextStyle(fontSize: 13)),
                    if (o.urunAdi.isNotEmpty)
                      Text(o.urunAdi, style: const TextStyle(fontSize: 13)),
                    if (o.ozet.isNotEmpty)
                      Text(o.ozet, style: const TextStyle(fontSize: 13)),
                    if (o.degisenler.isNotEmpty) ...[
                      const SizedBox(height: Bosluk.xs),
                      Text('Değişenler',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      for (final d in o.degisenler)
                        Text('• $d',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                    if (o.ekstraUcretMetni.isNotEmpty && o.degisenler.isEmpty)
                      Text(o.ekstraUcretMetni,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    if (o.notu.isNotEmpty) ...[
                      const SizedBox(height: Bosluk.xs),
                      Text('“${o.notu}”', style: const TextStyle(fontSize: 13)),
                    ],
                    if (o.sonCevapMetni.isNotEmpty) ...[
                      const SizedBox(height: Bosluk.xs),
                      Text(
                          'Son cevap: ${o.sonCevapMetni}. Cevap vermezsen talep kapanır.',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Bosluk.m),
            Row(
              children: [
                Expanded(
                    child: YikiciButon(
                        etiket: 'Reddet',
                        onPressed: isleniyor ? null : onReddet)),
                const SizedBox(width: Bosluk.m),
                Expanded(
                  child: FilledButton(
                    onPressed: isleniyor ? null : onKabul,
                    child: isleniyor
                        ? const ButonYukleniyorGostergesi()
                        : const Text('Kabul et'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Bosluk.m),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.xs,
            children: [
              if (t.duzenlenebilir)
                OutlinedButton.icon(
                  onPressed: isleniyor ? null : onDuzenle,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                ),
              if (t.geriCekilebilir)
                TextButton.icon(
                  onPressed: isleniyor ? null : onGeriCek,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Geri çek'),
                ),
              if (!t.acik)
                OutlinedButton.icon(
                  onPressed: isleniyor ? null : onBenzeri,
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('Benzerini aç'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
