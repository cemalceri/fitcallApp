// lib/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/sayfali_liste_parcalari.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yönetici üye listesinin sunum gövdesi.
///
/// Liste sayfalı gelir (aşağı kaydırdıkça 20'şer, bkz. SayfaliListe). Ada göre
/// sıralıyken baş harf gruplarına bölünür; "Borçlu" filtresinde en borçlu,
/// "Yeni"de en yeni üye önce gelir ve tek grup olarak çizilir. Filtre,
/// başlıktaki sayılı kartlardır ([UyeIstatistikKartlar]).
///
/// API çağrısı içermez; veri dışarıdan verilir. Böylece taşma testinde
/// doğrudan pump edilebilir (bkz. CLAUDE.md "Layout / overflow discipline").
class UyelerGorunumu extends StatelessWidget {
  final UyeIstatistik? istatistik;

  /// Şimdiye kadar yüklenen sayfalar (sunucuda süzülmüş ve sıralanmış).
  final List<UyeListeItem> uyeler;

  /// Filtre + aramaya uyan toplam kayıt; bilinmiyorsa yüklenen sayı yazılır.
  final int? toplam;

  final bool yukleniyor;
  final String? hata;

  /// Sonraki sayfa yükleniyor / alınamadı.
  final bool dahaYukleniyor;
  final String? dahaHatasi;

  /// 'tumu' | 'aktif' | 'pasif' | 'borclu' | 'yeni'
  final String filtre;
  final TextEditingController aramaDenetleyicisi;

  final ValueChanged<String> onFiltre;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final ValueChanged<UyeListeItem> onUyeSec;
  final ValueChanged<UyeListeItem> onAra;
  final ValueChanged<UyeListeItem> onWhatsapp;

  /// Liste sonuna yaklaşıldı; sonraki sayfa istenir.
  final VoidCallback? onDahaFazla;
  final VoidCallback? onDahaTekrarDene;

  const UyelerGorunumu({
    super.key,
    required this.istatistik,
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

  static final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    // Durum çubuğunun arkası sabit takım renginde; kayan başlık onun altından
    // geçer. Yoksa başlık kayarken yazısı saat/kamera bölgesine giriyordu.
    return RenkliDurumCubugu(
      child: RefreshIndicator(
        onRefresh: onYenile,
        // Yenilemede iskelet çıkmaz; mevcut liste durur, üstte çubuk döner.
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

  /// Başlık + arama + filtre kartları.
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
            // Sayılı kartlar filtrenin kendisi; başlıkta durdukları için
            // liste boşken / yüklenirken de seçilebilir.
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.m),
              child: UyeIstatistikKartlar(
                data: istatistik,
                secili: filtre,
                onSec: onFiltre,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama kutusu + filtre kartlarının toplam yüksekliği. Yazı ölçeği 1.3'e
  /// çıkabildiği için sabit değer taşma üretiyordu.
  double _aramaSeridiYuksekligi(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    final arama = olcek.scale(16) * 1.4 + Bosluk.m * 2 + 2;
    return arama +
        Bosluk.s +
        UyeIstatistikKartlar.yukseklik(context) +
        Bosluk.m;
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

    // Borçlu/Güncel grupları sayfalı listede tutarsızdı (her yeni sayfa iki
    // gruba da satır eklerdi). Borç satırın kırmızı bakiyesinden okunuyor;
    // borçluların hepsi "Borçlu" kartında, en borçlu önce.
    return [
      if (filtre == 'borclu')
        ..._grup(context, 'Borçlu', uyeler, toplam ?? uyeler.length)
      else if (filtre == 'yeni')
        ..._grup(context, 'Bu ay kaydolanlar', uyeler, toplam ?? uyeler.length)
      else
        ...harfGrubuSliverlari<UyeListeItem>(
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

  /// Yapışkan grup başlığı + satırlar. Grup boşsa hiç çizilmez.
  List<Widget> _grup(
    BuildContext context,
    String baslik,
    List<UyeListeItem> grup,
    int sayi,
  ) {
    if (grup.isEmpty) return const [];

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: ListeGrupBasligiDelegate(
          baslik: baslik,
          sayi: sayi,
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
        fotoUrl: uye.profilFotografi,
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
