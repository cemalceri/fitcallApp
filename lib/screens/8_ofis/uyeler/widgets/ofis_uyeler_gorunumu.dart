// lib/screens/8_ofis/uyeler/widgets/ofis_uyeler_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/sayfali_liste_parcalari.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ofis üye listesinin sunum gövdesi.
///
/// Yönetici listesinden farkı: satırın sağ değeri bakiye değil SON DERS
/// tarihi. Model zaten bakiye taşımıyor (bkz.
/// lib/models/10_ofis/ofis_uye_models.dart), yani buradaki tercih değil
/// sınırın kendisi.
///
/// Liste sayfalı gelir (aşağı kaydırdıkça 20'şer, bkz. SayfaliListe) ve baş
/// harf gruplarına bölünür.
///
/// API çağrısı içermez; veri dışarıdan verilir. Böylece taşma testinde
/// doğrudan pump edilebilir (bkz. CLAUDE.md "Layout / overflow discipline").
class OfisUyelerGorunumu extends StatelessWidget {
  /// Şimdiye kadar yüklenen sayfalar (sunucuda süzülmüş, ada göre sıralı).
  final List<OfisUyeListeItem> uyeler;

  /// Filtre + aramaya uyan toplam kayıt; bilinmiyorsa yüklenen sayı yazılır.
  final int? toplam;

  final bool yukleniyor;
  final String? hata;

  /// Sonraki sayfa yükleniyor / alınamadı.
  final bool dahaYukleniyor;
  final String? dahaHatasi;

  /// 'tumu' | 'aktif' | 'pasif'
  final String filtre;
  final TextEditingController aramaDenetleyicisi;

  final ValueChanged<String> onFiltre;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<OfisUyeListeItem> onUyeSec;
  final ValueChanged<OfisUyeListeItem> onAra;
  final ValueChanged<OfisUyeListeItem> onWhatsapp;

  /// Liste sonuna yaklaşıldı; sonraki sayfa istenir.
  final VoidCallback? onDahaFazla;
  final VoidCallback? onDahaTekrarDene;

  const OfisUyelerGorunumu({
    super.key,
    required this.uyeler,
    this.toplam,
    required this.yukleniyor,
    required this.hata,
    this.dahaYukleniyor = false,
    this.dahaHatasi,
    this.onDahaFazla,
    this.onDahaTekrarDene,
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
    // Durum çubuğunun arkası sabit takım renginde; kayan başlık onun altından
    // geçer. Yoksa başlık kayarken yazısı saat/kamera bölgesine giriyordu.
    return RenkliDurumCubugu(
      child: RefreshIndicator(
        onRefresh: onYenile,
        child: SayfaSonuDinleyici(
          onSonaYaklasti: onDahaFazla,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _baslikBari(context),
              ..._govde(context),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baslikBari(BuildContext context) {
    final cs = context.cs;

    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      leading: kabukMenuLeading(context),
      title: const Text('Üyeler'),
      actions: [
        if (!yukleniyor && hata == null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.l),
            child: Center(
              child: BaslikKapsulu('${toplam ?? uyeler.length} kayıt'),
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
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.m),
              child: SizedBox(
                height: BaslikSecici.yukseklik(context),
                child: BaslikSecici<String>(
                  secenekler: _filtreler,
                  secili: filtre,
                  onSec: onFiltre,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama kutusu + süzgeç şeridinin toplam yüksekliği. Yazı ölçeği 1.3'e
  /// çıkabildiği için sabit değer taşma üretiyordu.
  double _aramaSeridiYuksekligi(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    final arama = olcek.scale(16) * 1.4 + Bosluk.m * 2 + 2;
    return arama + Bosluk.s + BaslikSecici.yukseklik(context) + Bosluk.m;
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

    // Aktif/pasif grupları sayfalı listede tutarsızdı (pasifler her yeni
    // sayfada araya girerdi); pasif üye satırdaki rozetle ayrılıyor.
    return [
      ...harfGrubuSliverlari<OfisUyeListeItem>(
        context,
        ogeler: uyeler,
        ad: (u) => u.adSoyad,
        satir: _satir,
      ),
      ...sayfaSonuSliverlari(
        context,
        dahaYukleniyor: dahaYukleniyor,
        dahaHatasi: dahaHatasi,
        onTekrarDene: onDahaTekrarDene,
      ),
    ];
  }

  Widget _satir(BuildContext context, OfisUyeListeItem uye) {
    final telVar = uye.telefon != null && uye.telefon!.isNotEmpty;

    return ListeSatiri(
      onGorsel: ListeAvatari(
        basHarfler: ListeAvatari.harfler(uye.adSoyad),
        fotoUrl: uye.profilFotografi,
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
