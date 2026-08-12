// lib/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Yönetici üye listesinin sunum gövdesi.
///
/// API çağrısı içermez; veri dışarıdan verilir. Böylece taşma testinde
/// doğrudan pump edilebilir (bkz. CLAUDE.md "Layout / overflow discipline").
class UyelerGorunumu extends StatelessWidget {
  final UyeIstatistik? istatistik;

  /// Filtrelenmiş liste.
  final List<UyeListeItem> uyeler;

  final bool yukleniyor;
  final String? hata;

  /// 'tumu' | 'aktif' | 'pasif' | 'borclu'
  final String filtre;
  final TextEditingController aramaDenetleyicisi;

  final ValueChanged<String> onFiltre;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<UyeListeItem> onUyeSec;
  final ValueChanged<UyeListeItem> onAra;
  final ValueChanged<UyeListeItem> onWhatsapp;

  const UyelerGorunumu({
    super.key,
    required this.istatistik,
    required this.uyeler,
    required this.yukleniyor,
    required this.hata,
    required this.filtre,
    required this.aramaDenetleyicisi,
    required this.onFiltre,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onUyeSec,
    required this.onAra,
    required this.onWhatsapp,
  });

  static final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  static const _filtreler = [
    ('tumu', 'Tümü'),
    ('aktif', 'Aktif'),
    ('pasif', 'Pasif'),
    ('borclu', 'Borçlular'),
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onYenile,
      // Yenilemede iskelet çıkmaz; mevcut liste durur, üstte çubuk döner.
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _baslikBari(context),
          ..._govde(context),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  /// Başlık + arama + filtre çipleri.
  ///
  /// `floating` + `snap`: aşağı kaydırınca yukarı kayar, yukarı çekince anında
  /// geri gelir — arama kutusu için liste başına dönmek gerekmiyor.
  Widget _baslikBari(BuildContext context) {
    final cs = context.cs;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      title: const Text('Üyeler'),
      actions: [
        if (istatistik != null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.l),
            child: Center(
              child: Text(
                '${istatistik!.toplamUye} kayıt',
                style: context.metin.bodySmall,
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_aramaSeridiYuksekligi(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.s),
              child: TextField(
                controller: aramaDenetleyicisi,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'İsim, telefon veya üye no',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: aramaDenetleyicisi.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Temizle',
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: aramaDenetleyicisi.clear,
                        ),
                  fillColor: cs.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Bosluk.l,
                    vertical: Bosluk.m,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Yaricap.m),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Yaricap.m),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _cipYuksekligi(context),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
                children: [
                  for (final (deger, etiket) in _filtreler)
                    Padding(
                      padding: const EdgeInsets.only(right: Bosluk.s),
                      child: _FiltreCipi(
                        etiket: etiket,
                        secili: filtre == deger,
                        onSec: () => onFiltre(deger),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama kutusu + çip şeridinin toplam yüksekliği. Yazı ölçeği 1.3'e
  /// çıkabildiği için sabit değer taşma üretiyordu.
  double _aramaSeridiYuksekligi(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    final arama = olcek.scale(16) * 1.4 + Bosluk.m * 2 + 2;
    return arama + Bosluk.s + _cipYuksekligi(context) + Bosluk.s;
  }

  double _cipYuksekligi(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(13) * 1.3 + Bosluk.s * 2;

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
            baslik: 'Liste alınamadı',
            aciklama: hata!,
            ikonRengi: context.renkler.hata,
            eylemEtiketi: 'Tekrar dene',
            eylemIkonu: Icons.refresh_rounded,
            onEylem: onYenidenDene,
          ),
        ),
      ];
    }

    if (uyeler.isEmpty) {
      final aramaVar = aramaDenetleyicisi.text.trim().isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: BosDurum(
            ikon: aramaVar
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            baslik: aramaVar ? 'Sonuç yok' : 'Üye yok',
            aciklama: aramaVar
                ? '"${aramaDenetleyicisi.text.trim()}" için eşleşen üye '
                    'bulunamadı. Farklı bir arama deneyin.'
                : 'Bu filtreye uyan üye bulunmuyor.',
            eylemEtiketi: aramaVar ? 'Aramayı temizle' : null,
            eylemIkonu: Icons.clear_rounded,
            onEylem: aramaVar ? aramaDenetleyicisi.clear : null,
          ),
        ),
      ];
    }

    // Yöneticinin listede aradığı ilk şey borç durumu; gruplar ona göre.
    final borclular = uyeler.where((u) => u.bakiye < 0).toList();
    final guncel = uyeler.where((u) => u.bakiye >= 0).toList();

    return [
      if (istatistik != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.l),
            child: UyeIstatistikKartlar(data: istatistik!),
          ),
        ),
      ..._grup(context, 'Borçlu', borclular),
      ..._grup(context, 'Güncel', guncel),
    ];
  }

  /// Yapışkan grup başlığı + satırlar. Grup boşsa hiç çizilmez.
  List<Widget> _grup(
    BuildContext context,
    String baslik,
    List<UyeListeItem> grup,
  ) {
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
        itemBuilder: (context, index) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0) const ListeAyraci(),
            _satir(context, grup[index]),
          ],
        ),
      ),
    ];
  }

  Widget _satir(BuildContext context, UyeListeItem uye) {
    final renkler = context.renkler;
    final telVar = uye.telefon != null && uye.telefon!.isNotEmpty;

    final (Color degerRengi, ListeTonu avatarTonu) = switch (uye) {
      _ when !uye.aktifMi => (context.cs.onSurfaceVariant, ListeTonu.notr),
      _ when uye.bakiye < 0 => (renkler.hata, ListeTonu.hata),
      _ when uye.bakiye > 0 => (renkler.basari, ListeTonu.bilgi),
      _ => (context.cs.onSurfaceVariant, ListeTonu.bilgi),
    };

    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(uye.adSoyad),
        ton: avatarTonu,
      ),
      baslik: uye.adSoyad,
      rozet: uye.aktifMi ? null : const _PasifRozeti(),
      altBaslik: _altBaslik(uye),
      deger: _currency.format(uye.bakiye),
      degerRengi: degerRengi,
      altDeger: '#${uye.uyeNo}',
      onTap: () => onUyeSec(uye),
      eylemler: [
        if (telVar)
          ListeEylemi(
            etiket: 'Ara',
            ikon: Icons.phone_rounded,
            ton: ListeTonu.basari,
            onSec: () => onAra(uye),
          ),
        if (telVar)
          ListeEylemi(
            etiket: 'WhatsApp',
            ikon: Icons.chat_rounded,
            ton: ListeTonu.bilgi,
            onSec: () => onWhatsapp(uye),
          ),
      ],
    );
  }

  /// Telefon ve üye no aramada zaten eşleşiyor; ikinci satırda üyeyi
  /// hatırlatan bilgi durur.
  String _altBaslik(UyeListeItem uye) {
    final parcalar = <String>[
      if (uye.seviyeRengi.isNotEmpty) '${uye.seviyeRengi} seviye',
      uye.uyeTuru,
      if (uye.yas != null) '${uye.yas} yaş',
    ];
    return parcalar.join(' · ');
  }
}

class _PasifRozeti extends StatelessWidget {
  const _PasifRozeti();

  @override
  Widget build(BuildContext context) {
    final renkler = context.renkler;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: renkler.uyariZemin,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        'Pasif',
        style: context.metin.labelSmall?.copyWith(color: renkler.uyari),
      ),
    );
  }
}

class _FiltreCipi extends StatelessWidget {
  final String etiket;
  final bool secili;
  final VoidCallback onSec;

  const _FiltreCipi({
    required this.etiket,
    required this.secili,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Semantics(
      button: true,
      selected: secili,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSec();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: secili ? cs.primary : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(Yaricap.xl),
          ),
          child: Text(
            etiket,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
              color: secili ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
