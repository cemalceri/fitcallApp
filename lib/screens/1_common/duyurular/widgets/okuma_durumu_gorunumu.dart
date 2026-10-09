// lib/screens/1_common/duyurular/widgets/okuma_durumu_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/duyuru_okuma_models.dart';
import 'package:fitcall/screens/1_common/duyurular/widgets/duyuru_bicim.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

/// Bir duyurunun okuma durumu — veriyle beslenen gövde.
///
/// Üstte özet kartı (oran, kaynak dağılımı, "İçeriği gör"), altında isimle
/// arama ve Gördü | Görmedi segmenti. Segment ve arama bu widget'ın durumunda
/// tutulur: satırdan üye detayına gidip dönünce kullanıcı kaldığı yerde olur
/// (ofis görmeyenleri art arda arıyor).
class OkumaDurumuGorunumu extends StatefulWidget {
  final DuyuruOkumaDurumu veri;
  final VoidCallback onIcerikGor;

  /// null ise satırlar tıklanmaz. Yalnız üye profili olan satırda çağrılır.
  final ValueChanged<DuyuruHesabi>? onHesapSec;
  final Future<void> Function() onYenile;

  const OkumaDurumuGorunumu({
    super.key,
    required this.veri,
    required this.onIcerikGor,
    required this.onYenile,
    this.onHesapSec,
  });

  @override
  State<OkumaDurumuGorunumu> createState() => _OkumaDurumuGorunumuState();
}

enum _Segment { gordu, gormedi }

class _OkumaDurumuGorunumuState extends State<OkumaDurumuGorunumu> {
  _Segment _segment = _Segment.gordu;
  final TextEditingController _arama = TextEditingController();

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  bool _eslesir(DuyuruHesabi h) {
    final q = aramaBicimi(_arama.text);
    if (q.isEmpty) return true;
    return h.profiller.any((p) => aramaBicimi(p.ad).contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final veri = widget.veri;
    final ozet = veri.ozet;
    final planli = veri.durum == DuyuruYayinDurumu.planli;
    // Hedef ölçülmüyorsa "görmedi" listesi anlamsız; yalnız kayıtlar gösterilir.
    final segmentVar = ozet.olculuyor && !planli;
    final segment = segmentVar ? _segment : _Segment.gordu;

    final gordu = veri.gordu.where(_eslesir).toList();
    final gormedi = veri.gormedi.where(_eslesir).toList();

    return RefreshIndicator(
      onRefresh: widget.onYenile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.s),
              child: _OzetKarti(veri: veri, onIcerikGor: widget.onIcerikGor),
            ),
          ),
          if (planli)
            SliverToBoxAdapter(
              child: BosDurum(
                ikon: Icons.schedule_rounded,
                baslik: 'Yayın henüz başlamadı',
                aciklama: '${gunAy(veri.duyuru.yayinBaslangic)} tarihinde '
                    'yayına girecek; kimlerin gördüğü o zaman burada görünür.',
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _aramaKutusu(context)),
            if (segmentVar)
              SliverToBoxAdapter(child: _segmentSecici(context)),
            if (segment == _Segment.gordu)
              ..._gorduListesi(gordu)
            else
              ..._gormediListesi(context, gormedi),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: Bosluk.xl)),
        ],
      ),
    );
  }

  Widget _aramaKutusu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, 0),
      child: TextField(
        controller: _arama,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'İsimle ara',
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          suffixIcon: _arama.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Aramayı temizle',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(_arama.clear),
                ),
        ),
      ),
    );
  }

  Widget _segmentSecici(BuildContext context) {
    final veri = widget.veri;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.s),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_Segment>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: _Segment.gordu,
              label: Text('Gördü (${veri.gordu.length})', maxLines: 1),
            ),
            ButtonSegment(
              value: _Segment.gormedi,
              label: Text('Görmedi (${veri.gormedi.length})', maxLines: 1),
            ),
          ],
          selected: {_segment},
          onSelectionChanged: (s) => setState(() => _segment = s.first),
        ),
      ),
    );
  }

  List<Widget> _gorduListesi(List<GorenHesap> liste) {
    if (liste.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _arama.text.isNotEmpty
              ? const _AramaSonucYok()
              : const BosDurum(
                  ikon: Icons.visibility_off_outlined,
                  baslik: 'Henüz kimse görmedi',
                  aciklama: 'Duyuruyu ana sayfada açan ya da açılış popup\'ında '
                      'gören hesaplar burada, en yenisi üstte listelenir.',
                ),
        ),
      ];
    }
    return [
      SliverList.builder(
        itemCount: liste.length,
        itemBuilder: (context, i) {
          final h = liste[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0) const ListeAyraci(),
              _hesapSatiri(
                h,
                altBaslik: gormeSekli(h),
                deger: saatDakika(h.zaman),
                altDeger: gunAy(h.zaman),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _gormediListesi(
      BuildContext context, List<GormeyenHesap> liste) {
    if (liste.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _arama.text.isNotEmpty
              ? const _AramaSonucYok()
              : const BosDurum(
                  ikon: Icons.done_all_rounded,
                  baslik: 'Hedef kitledeki herkes gördü',
                  aciklama: 'Görmeyen hesap kalmadı.',
                ),
        ),
      ];
    }
    final kullanan = liste.where((h) => h.uygulamaKullaniyor).toList();
    final kullanmayan = liste.where((h) => !h.uygulamaKullaniyor).toList();
    return [
      ..._grup(context, 'Uygulamayı kullananlar', kullanan),
      ..._grup(context, 'Uygulamayı kullanmayanlar', kullanmayan),
    ];
  }

  List<Widget> _grup(
      BuildContext context, String baslik, List<GormeyenHesap> grup) {
    if (grup.isEmpty) return const [];
    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: ListeGrupBasligiDelegate(
          baslik: baslik,
          sayi: grup.length,
          yukseklik: listeGrupBasligiYuksekligi(context),
        ),
      ),
      SliverList.builder(
        itemCount: grup.length,
        itemBuilder: (context, i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0) const ListeAyraci(),
            _hesapSatiri(grup[i], altBaslik: rolEtiketleri(grup[i])),
          ],
        ),
      ),
    ];
  }

  Widget _hesapSatiri(
    DuyuruHesabi h, {
    required String altBaslik,
    String? deger,
    String? altDeger,
  }) {
    final secim = widget.onHesapSec;
    // Ok yalnız gidilebilen satırda: antrenör/profilsiz satırda yanlış vaat olur.
    final gidilir = secim != null && h.uyeProfilleri.isNotEmpty;
    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(h.profiller.first.ad),
        ton: ListeTonu.notr,
      ),
      baslik: h.adlar,
      altBaslik: altBaslik,
      deger: deger,
      altDeger: altDeger,
      okGoster: gidilir,
      onTap: gidilir ? () => secim(h) : null,
    );
  }
}

class _AramaSonucYok extends StatelessWidget {
  const _AramaSonucYok();

  @override
  Widget build(BuildContext context) {
    return const BosDurum(
      ikon: Icons.search_off_rounded,
      baslik: 'Sonuç yok',
      aciklama: 'Bu adla eşleşen hesap bulunamadı.',
    );
  }
}

/// Üstteki özet: başlık, alt satır, oran + çubuk, kaynak dağılımı, "İçeriği gör".
class _OzetKarti extends StatelessWidget {
  final DuyuruOkumaDurumu veri;
  final VoidCallback onIcerikGor;

  const _OzetKarti({required this.veri, required this.onIcerikGor});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    final d = veri.duyuru;
    final ozet = veri.ozet;
    final oran = ozet.oran;
    final planli = veri.durum == DuyuruYayinDurumu.planli;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Bosluk.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.baslik,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: metin.titleMedium,
            ),
            const SizedBox(height: Bosluk.xs),
            Text(
              duyuruAltSatiri(
                hedefKitle: d.hedefKitle,
                yayinBaslangic: d.yayinBaslangic,
                yayinBitis: d.yayinBitis,
                aktifMi: veri.aktifMi,
                popupGoster: d.popupGoster,
                onemliMi: d.onemliMi,
              ),
              style: metin.bodySmall,
            ),
            const SizedBox(height: Bosluk.l),
            if (!ozet.olculuyor)
              Text(
                'Bu duyurunun hedef kitlesi uygulamada ölçülmüyor: antrenörler '
                'duyuruyu yalnız açılış popup\'ında görür. '
                '${ozet.toplamGoren} görme kaydı var.',
                style: metin.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else if (!planli) ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: Bosluk.s,
                children: [
                  Text(
                    oran == null ? '—' : oranMetni(oran),
                    style: metin.headlineMedium?.copyWith(color: cs.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${ozet.gorenSayisi} / ${ozet.hedefSayisi} hesap gördü',
                      style: metin.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Bosluk.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(Yaricap.s),
                child: LinearProgressIndicator(
                  value: oran ?? 0,
                  minHeight: 8,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: Bosluk.s),
              Text(
                [
                  'Ana sayfadan açan ${ozet.anaSayfa}',
                  "Popup'ta gören ${ozet.popup}",
                  'Detayı açan ${ozet.detayAcan}',
                  if (ozet.kullanmayanSayisi > 0)
                    '${ozet.kullanmayanSayisi} hesap uygulamayı kullanmıyor',
                ].join(' · '),
                style: metin.bodySmall,
              ),
            ],
            const SizedBox(height: Bosluk.m),
            OutlinedButton.icon(
              onPressed: onIcerikGor,
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('İçeriği gör'),
            ),
          ],
        ),
      ),
    );
  }
}
