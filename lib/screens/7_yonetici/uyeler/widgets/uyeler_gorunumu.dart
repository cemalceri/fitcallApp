// lib/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/sayfali_liste_parcalari.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_filtre_seridi.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Yönetici üye listesinin sunum gövdesi.
///
/// Liste sayfalı gelir (aşağı kaydırdıkça 20'şer, bkz. SayfaliListe); filtre
/// ve sıralama sunucuda. Başlıkta arama, **Filtrele** / **Sırala** düğmeleri
/// ve hızlı ön ayar olan sayılı kartlar ([UyeIstatistikKartlar]) durur;
/// listenin üstünde etkin filtre çipleri ve süzülen kümenin özeti. Ada göre
/// sıralıyken baş harf gruplarına bölünür, başka sıralamada düz liste.
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

  final UyeFiltreleri filtreler;
  final UyeSiralama siralama;

  /// Filtrelerin tam eşit olduğu kart (vurgulu); yoksa null.
  final UyeOnAyari? seciliOnAyar;

  /// Süzülen kümenin özeti; ilk sayfa gelene kadar null.
  final UyeFiltreOzeti? filtreOzeti;

  final TextEditingController aramaDenetleyicisi;

  final ValueChanged<UyeOnAyari> onOnAyar;
  final VoidCallback onFiltrele;
  final VoidCallback onSirala;

  /// Çipten tek filtre kaldırıldı ya da hepsi temizlendi.
  final ValueChanged<UyeFiltreleri> onFiltreDegistir;
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
    required this.filtreler,
    required this.siralama,
    required this.seciliOnAyar,
    this.filtreOzeti,
    required this.aramaDenetleyicisi,
    required this.onOnAyar,
    required this.onFiltrele,
    required this.onSirala,
    required this.onFiltreDegistir,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onUyeSec,
    required this.onAra,
    required this.onWhatsapp,
  });

  static final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  static final _gun = DateFormat('dd.MM.yyyy', 'tr_TR');

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

  /// Başlık + arama + Filtrele/Sırala + ön ayar kartları.
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
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.s),
              child: UyeFiltreDugmeleri(
                filtreler: filtreler,
                siralama: siralama,
                onFiltrele: onFiltrele,
                onSirala: onSirala,
              ),
            ),
            // Sayılı kartlar hızlı ön ayar; başlıkta durdukları için liste
            // boşken / yüklenirken de seçilebilir.
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.m),
              child: UyeIstatistikKartlar(
                data: istatistik,
                secili: seciliOnAyar,
                onSec: onOnAyar,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Arama + düğmeler + kartların toplam yüksekliği. Yazı ölçeği 1.3'e
  /// çıkabildiği için sabit değer taşma üretiyordu.
  double _aramaSeridiYuksekligi(BuildContext context) {
    final olcek = MediaQuery.textScalerOf(context);
    final arama = olcek.scale(16) * 1.4 + Bosluk.m * 2 + 2;
    return arama +
        Bosluk.s +
        UyeFiltreDugmeleri.yukseklik(context) +
        Bosluk.s +
        UyeIstatistikKartlar.yukseklik(context) +
        Bosluk.m;
  }

  List<Widget> _govde(BuildContext context) {
    // Çipler yüklenirken de durur (yanlış filtre hemen kaldırılabilsin);
    // özet yalnız liste gelince.
    final etkinFiltreler = SliverToBoxAdapter(
      child: UyeEtkinFiltreler(
        filtreler: filtreler,
        ozet: yukleniyor || hata != null ? null : filtreOzeti,
        onDegistir: onFiltreDegistir,
      ),
    );

    if (yukleniyor) {
      return [
        etkinFiltreler,
        const SliverToBoxAdapter(child: IskeletListe(kaydirilabilir: false)),
      ];
    }

    if (hata != null) {
      return [
        etkinFiltreler,
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
      final filtreVar = !filtreler.bosMu;
      return [
        etkinFiltreler,
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
                : 'Bu filtrelere uyan üye bulunmuyor.',
            eylemEtiketi: aramaVar
                ? 'Aramayı temizle'
                : filtreVar
                    ? 'Filtreleri temizle'
                    : null,
            eylemIkonu: Icons.clear_rounded,
            onEylem: aramaVar
                ? aramaDenetleyicisi.clear
                : filtreVar
                    ? () => onFiltreDegistir(UyeFiltreleri.bos)
                    : null,
          ),
        ),
      ];
    }

    // Ada göre (iki yönde de) rehberdeki gibi harf grupları; başka
    // sıralamada gruplar anlamsız (borç, tarih), düz liste.
    return [
      etkinFiltreler,
      if (siralama.alan == UyeSiralamaAlani.ad)
        ...harfGrubuSliverlari<UyeListeItem>(
          context,
          ogeler: uyeler,
          ad: (u) => u.adSoyad,
          satir: _satir,
        )
      else
        SliverPadding(
          padding: const EdgeInsets.only(top: Bosluk.s),
          sliver: SliverList.builder(
            itemCount: uyeler.length,
            itemBuilder: (context, index) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0) const ListeAyraci(),
                _satir(context, uyeler[index]),
              ],
            ),
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
      rozet: _rozetler(uye),
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

  /// Pasif ve "Kesin" (borcu ön muhasebece kesinleşmiş) işaretleri.
  Widget? _rozetler(UyeListeItem uye) {
    final pasif = !uye.aktifMi;
    final kesin = uye.borcKesinlesti;
    if (!pasif && !kesin) return null;
    if (pasif && !kesin) return const _Rozet.pasif();
    if (!pasif) return const _Rozet.kesin();
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Rozet.pasif(),
        SizedBox(width: Bosluk.xs),
        _Rozet.kesin(),
      ],
    );
  }

  /// İkinci satır: tarihe göre sıralarken o tarih (sıranın nedeni görünsün),
  /// yoksa üyeyi hatırlatan bilgi. Telefon ve üye no aramada zaten eşleşiyor.
  String _altBaslik(UyeListeItem uye) {
    String tarih(String ad, DateTime? t, String yok) =>
        t == null ? yok : '$ad: ${_gun.format(t)}';
    switch (siralama.alan) {
      case UyeSiralamaAlani.sonKontrol:
        return tarih('Son kontrol', uye.sonKontrolTarihi, 'Hiç kontrol edilmedi');
      case UyeSiralamaAlani.sonOdeme:
        return tarih('Son ödeme', uye.sonOdemeTarihi, 'Hiç ödeme yok');
      case UyeSiralamaAlani.sonDers:
        return tarih('Son ders', uye.sonDersTarihi, 'Hiç ders yok');
      default:
        break;
    }
    final parcalar = <String>[
      if (uye.seviyeRengi.isNotEmpty) '${uye.seviyeRengi} seviye',
      uye.uyeTuru,
      if (uye.yas != null) '${uye.yas} yaş',
    ];
    return parcalar.join(' · ');
  }
}

class _Rozet extends StatelessWidget {
  final String etiket;
  final ListeTonu ton;

  const _Rozet.pasif()
      : etiket = 'Pasif',
        ton = ListeTonu.uyari;

  /// Borcu web'de "kesinleşti" işaretlenmiş üye.
  const _Rozet.kesin()
      : etiket = 'Kesin',
        ton = ListeTonu.basari;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(Yaricap.s),
      ),
      child: Text(
        etiket,
        style: context.metin.labelSmall?.copyWith(color: ton.on(context)),
      ),
    );
  }
}
