// lib/screens/8_ofis/uyeler/widgets/ofis_uyeler_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Ofis üye listesinin sunum gövdesi.
///
/// Yönetici listesinden iki farkı var: satırın sağ değeri bakiye değil SON DERS
/// tarihi, ve gruplama borç yerine aktif/pasif üzerinden. Model zaten bakiye
/// taşımıyor (bkz. lib/models/10_ofis/ofis_uye_models.dart), yani buradaki
/// tercih değil sınırın kendisi.
///
/// API çağrısı içermez; veri dışarıdan verilir. Böylece taşma testinde
/// doğrudan pump edilebilir (bkz. CLAUDE.md "Layout / overflow discipline").
class OfisUyelerGorunumu extends StatelessWidget {
  /// Filtrelenmiş liste.
  final List<OfisUyeListeItem> uyeler;

  final bool yukleniyor;
  final String? hata;

  /// 'tumu' | 'aktif' | 'pasif'
  final String filtre;
  final TextEditingController aramaDenetleyicisi;

  final ValueChanged<String> onFiltre;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<OfisUyeListeItem> onUyeSec;
  final ValueChanged<OfisUyeListeItem> onAra;
  final ValueChanged<OfisUyeListeItem> onWhatsapp;

  const OfisUyelerGorunumu({
    super.key,
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

  static final _gun = DateFormat('d MMM', 'tr_TR');

  static const _filtreler = [
    ('tumu', 'Tümü'),
    ('aktif', 'Aktif'),
    ('pasif', 'Pasif'),
  ];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onYenile,
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

  Widget _baslikBari(BuildContext context) {
    final cs = context.cs;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      title: const Text('Üyeler'),
      actions: [
        if (!yukleniyor && hata == null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.l),
            child: Center(
              child: Text(
                '${uyeler.length} kayıt',
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

    // Ön büroda aranan üye neredeyse her zaman aktif olan; pasifler altta.
    final aktifler = uyeler.where((u) => u.aktifMi).toList();
    final pasifler = uyeler.where((u) => !u.aktifMi).toList();

    return [
      ..._grup(context, 'Aktif', aktifler),
      ..._grup(context, 'Pasif', pasifler),
    ];
  }

  /// Yapışkan grup başlığı + satırlar. Grup boşsa hiç çizilmez.
  List<Widget> _grup(
    BuildContext context,
    String baslik,
    List<OfisUyeListeItem> grup,
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

  Widget _satir(BuildContext context, OfisUyeListeItem uye) {
    final telVar = uye.telefon != null && uye.telefon!.isNotEmpty;

    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(uye.adSoyad),
        ton: uye.aktifMi ? ListeTonu.bilgi : ListeTonu.notr,
      ),
      baslik: uye.adSoyad,
      rozet: uye.aktifMi ? null : const _PasifRozeti(),
      altBaslik: _altBaslik(uye),
      deger: uye.sonDersTarihi != null ? _gun.format(uye.sonDersTarihi!) : '—',
      degerRengi: context.cs.onSurfaceVariant,
      altDeger: uye.sonDersTarihi != null ? 'son ders' : null,
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
  String _altBaslik(OfisUyeListeItem uye) {
    final parcalar = <String>[
      '#${uye.uyeNo}',
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
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        'Pasif',
        style: context.metin.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Yaricap.xl),
        onTap: () {
          HapticFeedback.selectionClick();
          onSec();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.m, vertical: Bosluk.s),
          decoration: BoxDecoration(
            color: secili ? cs.primary : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(Yaricap.xl),
          ),
          child: Text(
            etiket,
            maxLines: 1,
            style: context.metin.labelLarge?.copyWith(
              color: secili ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
