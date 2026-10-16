// lib/screens/1_common/degerlendirmeler/widgets/degerlendirmeler_gorunumu.dart
//
// Bir antrenörün ders değerlendirmeleri listesinin sunum gövdesi (yalnız
// yönetici; Antrenörler listesindeki puandan açılır). Satırda puanı veren,
// yorumun ilk satırı, puan ve dersin günü; satıra dokununca detay alt sayfası
// açılır (degerlendirme_detayi.dart).
//
// API çağrısı içermez; veri dışarıdan verilir. Böylece taşma testinde
// doğrudan çizilir (bkz. CLAUDE.md "Layout / overflow discipline").

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/1_common/degerlendirme_models.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/widgets/puan_parcalari.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/sayfali_liste_parcalari.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Liste süzgeçleri (sunucudaki `FILTRELER` ile aynı değerler).
const List<(String, String)> degerlendirmeSuzgecleri = [
  ('tumu', 'Tümü'),
  ('yorumlu', 'Yorumlu'),
  ('dusuk', '3 ve altı'),
];

class DegerlendirmelerGorunumu extends StatelessWidget {
  final String baslik;

  /// Başlığın altındaki satır (antrenörün adı).
  final String? altBaslik;

  final List<DersDegerlendirmesi> degerlendirmeler;
  final DegerlendirmeOzeti? ozet;

  /// Süzgece uyan toplam kayıt; bilinmiyorsa yüklenen sayı yazılır.
  final int? toplam;

  final bool yukleniyor;
  final String? hata;
  final bool dahaYukleniyor;
  final String? dahaHatasi;

  /// 'tumu' | 'yorumlu' | 'dusuk'
  final String filtre;

  final ValueChanged<String> onFiltre;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<DersDegerlendirmesi> onSec;
  final VoidCallback? onDahaFazla;
  final VoidCallback? onDahaTekrarDene;

  const DegerlendirmelerGorunumu({
    super.key,
    required this.baslik,
    this.altBaslik,
    required this.degerlendirmeler,
    this.ozet,
    this.toplam,
    required this.yukleniyor,
    required this.hata,
    this.dahaYukleniyor = false,
    this.dahaHatasi,
    required this.filtre,
    required this.onFiltre,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onSec,
    this.onDahaFazla,
    this.onDahaTekrarDene,
  });

  static final _gun = DateFormat('d MMM', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onYenile,
      child: SayfaSonuDinleyici(
        onSonaYaklasti: onDahaFazla,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _baslikBari(context),
            ..._govde(context),
            const SliverToBoxAdapter(child: SizedBox(height: Bosluk.xxl)),
          ],
        ),
      ),
    );
  }

  /// Sabit başlık: ad, sağda genel ortalama, altta tam genişlik süzgeç.
  Widget _baslikBari(BuildContext context) {
    final o = ozet;
    final seciciYuksekligi = BaslikSecici.yukseklik(context);

    return SliverAppBar(
      pinned: true,
      title: altBaslik == null
          ? Text(baslik)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  altBaslik!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baslikYazi(context, context.metin.bodySmall),
                ),
              ],
            ),
      actions: [
        if (o != null && o.adet > 0)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.l),
            child: Center(
              child: BaslikKapsulu(
                '${o.ortalama?.toStringAsFixed(1) ?? '–'} · ${o.adet}',
                ikon: Icons.star_rounded,
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(seciciYuksekligi + Bosluk.m),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.m),
          child: SizedBox(
            height: seciciYuksekligi,
            child: BaslikSecici<String>(
              secenekler: degerlendirmeSuzgecleri,
              secili: filtre,
              onSec: onFiltre,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _govde(BuildContext context) {
    if (yukleniyor) {
      return const [
        SliverToBoxAdapter(child: IskeletListe(kaydirilabilir: false)),
      ];
    }

    if (hata != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: BosDurum(
            ikon: Icons.error_outline_rounded,
            baslik: 'Değerlendirmeler alınamadı',
            aciklama: hata!,
            ikonRengi: context.renkler.hata,
            eylemEtiketi: 'Tekrar dene',
            eylemIkonu: Icons.refresh_rounded,
            onEylem: onYenidenDene,
          ),
        ),
      ];
    }

    if (degerlendirmeler.isEmpty) {
      final (bosBaslik, bosAciklama) = switch (filtre) {
        'yorumlu' => (
            'Yorumlu değerlendirme yok',
            'Üyeler puan verirken yorum yazmamış.'
          ),
        'dusuk' => (
            '3 ve altı puan yok',
            'Bu listede düşük puanlı değerlendirme bulunmuyor.'
          ),
        _ => (
            'Henüz değerlendirme yok',
            'Üyeler derslerini puanladıkça burada görünecek.'
          ),
      };
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: BosDurum(
            ikon: Icons.star_outline_rounded,
            baslik: bosBaslik,
            aciklama: bosAciklama,
          ),
        ),
      ];
    }

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: ListeGrupBasligiDelegate(
          baslik: 'En yeni önce',
          sayi: toplam ?? degerlendirmeler.length,
          yukseklik: listeGrupBasligiYuksekligi(context),
        ),
      ),
      SliverList.builder(
        itemCount: degerlendirmeler.length,
        itemBuilder: (context, i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0) const ListeAyraci(),
            _satir(context, degerlendirmeler[i]),
          ],
        ),
      ),
      ...sayfaSonuSliverlari(
        context,
        dahaYukleniyor: dahaYukleniyor,
        dahaHatasi: dahaHatasi,
        onTekrarDene: onDahaTekrarDene,
      ),
    ];
  }

  Widget _satir(BuildContext context, DersDegerlendirmesi d) {
    final yorum = d.yorum == null ? 'Yorum yok' : '“${d.yorum!}”';

    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(d.degerlendiren.adSoyad),
        fotoUrl: d.degerlendiren.profilFotografi,
        // Yalnız dikkat isteyen satır tondan ayrılır.
        ton: d.puan <= 2 ? ListeTonu.hata : ListeTonu.bilgi,
      ),
      baslik: d.degerlendiren.adSoyad,
      altBaslik: yorum,
      sonEk: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          PuanRozeti(puan: d.puan.toDouble(), tamSayi: true),
          const SizedBox(height: 2),
          Text(
            _gun.format(d.ders.baslangic),
            maxLines: 1,
            style: context.metin.labelSmall,
          ),
        ],
      ),
      onTap: () => onSec(d),
    );
  }
}
