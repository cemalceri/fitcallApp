// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UyelerPage extends StatefulWidget {
  const UyelerPage({super.key});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();
  final _currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  // Tüm liste tek seferde çekilir; arama/filtre client-side yapılır (API dövülmez).
  UyeIstatistik? _istatistik;
  List<UyeListeItem> _tumUyeler = [];
  bool _loading = true;
  String? _errorMessage;

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif' | 'borclu'

  @override
  void initState() {
    super.initState();
    _loadData();
    _aramaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getUyeler(hepsi: true);
      if (mounted) {
        setState(() {
          _istatistik = result.data?.istatistikler;
          _tumUyeler = result.data?.uyeler ?? [];
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  /// Client-side arama + filtre.
  List<UyeListeItem> get _filtrelenmis {
    var list = _tumUyeler;

    if (_filtre == 'aktif') {
      list = list.where((u) => u.aktifMi).toList();
    } else if (_filtre == 'pasif') {
      list = list.where((u) => !u.aktifMi).toList();
    } else if (_filtre == 'borclu') {
      list = list.where((u) => u.bakiye < 0).toList();
    }

    final q = _aramaController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((u) =>
              u.adSoyad.toLowerCase().contains(q) ||
              (u.telefon ?? '').contains(q) ||
              u.uyeNo.toString().contains(q))
          .toList();
    }

    if (_filtre == 'borclu') {
      // En borçlu (en negatif bakiye) önce
      list = [...list]..sort((a, b) => a.bakiye.compareTo(b.bakiye));
    }

    return list;
  }

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
  }

  void _acUyeDetay(UyeListeItem uye) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UyeDetayPage(
          uyeId: uye.id,
          baslangicAdSoyad: uye.adSoyad,
        ),
      ),
    );
  }

  Future<void> _ara(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('tel:0$telefon'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('https://wa.me/90$telefon'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        // Yenilemede iskelet çıkmaz; mevcut liste durur, üstte çubuk döner.
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _baslikBari(context),
            ..._govde(context),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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
        if (_istatistik != null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.l),
            child: Center(
              child: Text(
                '${_istatistik!.toplamUye} kayıt',
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
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, 0, Bosluk.l, Bosluk.s),
              child: TextField(
                controller: _aramaController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'İsim, telefon veya üye no',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _aramaController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Temizle',
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _aramaController.clear(),
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
                  for (final (deger, etiket) in const [
                    ('tumu', 'Tümü'),
                    ('aktif', 'Aktif'),
                    ('pasif', 'Pasif'),
                    ('borclu', 'Borçlular'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: Bosluk.s),
                      child: _FilterChip(
                        label: etiket,
                        selected: _filtre == deger,
                        onSelected: () => _onFiltreChanged(deger),
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
    if (_loading) {
      return const [
        SliverToBoxAdapter(child: IskeletListe(kaydirilabilir: false)),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: BosDurum(
            ikon: Icons.error_outline_rounded,
            baslik: 'Liste alınamadı',
            aciklama: _errorMessage!,
            ikonRengi: context.renkler.hata,
            eylemEtiketi: 'Tekrar dene',
            eylemIkonu: Icons.refresh_rounded,
            onEylem: _loadData,
          ),
        ),
      ];
    }

    final uyeler = _filtrelenmis;

    if (uyeler.isEmpty) {
      final aramaVar = _aramaController.text.trim().isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: BosDurum(
            ikon: aramaVar
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            baslik: aramaVar ? 'Sonuç yok' : 'Üye yok',
            aciklama: aramaVar
                ? '"${_aramaController.text.trim()}" için eşleşen üye '
                    'bulunamadı. Farklı bir arama deneyin.'
                : 'Bu filtreye uyan üye bulunmuyor.',
            eylemEtiketi: aramaVar ? 'Aramayı temizle' : null,
            eylemIkonu: Icons.clear_rounded,
            onEylem: aramaVar ? _aramaController.clear : null,
          ),
        ),
      ];
    }

    // Yöneticinin listede aradığı ilk şey borç durumu; gruplar ona göre.
    final borclular = uyeler.where((u) => u.bakiye < 0).toList();
    final guncel = uyeler.where((u) => u.bakiye >= 0).toList();

    return [
      if (_istatistik != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.l),
            child: UyeIstatistikKartlar(data: _istatistik!),
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
    List<UyeListeItem> uyeler,
  ) {
    if (uyeler.isEmpty) return const [];

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: ListeGrupBasligiDelegate(
          baslik: baslik,
          sayi: uyeler.length,
          yukseklik: listeGrupBasligiYuksekligi(context),
        ),
      ),
      SliverList.builder(
        itemCount: uyeler.length,
        itemBuilder: (context, index) {
          final uye = uyeler[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) const ListeAyraci(),
              _satir(context, uye),
            ],
          );
        },
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
      onTap: () => _acUyeDetay(uye),
      eylemler: [
        if (telVar)
          ListeEylemi(
            etiket: 'Ara',
            ikon: Icons.phone_rounded,
            ton: ListeTonu.basari,
            onSec: () => _ara(uye.telefon),
          ),
        if (telVar)
          ListeEylemi(
            etiket: 'WhatsApp',
            ikon: Icons.chat_rounded,
            ton: ListeTonu.bilgi,
            onSec: () => _whatsapp(uye.telefon),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onSelected();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainer,
            borderRadius: BorderRadius.circular(Yaricap.xl),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
