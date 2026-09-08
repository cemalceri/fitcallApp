// lib/screens/1_common/widgets/sss_gorunumu.dart
//
// Yardım & SSS sayfalarının ortak gövdesi.
//
// Neden var: üye, antrenör ve yönetici/ofis yardım sayfaları aynı ekranı üç kez
// yazıyordu (başlık kartı, arama, açılır soru kartı, iletişim kartı). İkisinde
// de renkler gömülüydü — soru kartının zemini `Colors.white`, vurgusu
// `Colors.blue` — yani koyu tema geldiğinde kartlar beyaz kalıyor, üstündeki
// `onSurface` metin okunmuyordu. Burada tüm renkler tema token'larından geliyor.
//
// Sayfalar artık yalnız VERİ tutuyor: bölüm listesi verilir, ekranı bu widget
// çizer. Arama + bölüm çipi filtresi, açılır kart animasyonu ve iletişim kartı
// tek yerde.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/sss_arama.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tek bir soru-cevap.
class SssSoru {
  final IconData ikon;
  final String soru;
  final String cevap;

  const SssSoru({required this.ikon, required this.soru, required this.cevap});
}

/// Soruların konu başlığı. Tek bölümlü sayfalarda çip satırı çizilmez.
class SssBolum {
  final String baslik;
  final IconData ikon;
  final List<SssSoru> sorular;

  const SssBolum({
    required this.baslik,
    required this.ikon,
    required this.sorular,
  });
}

/// Yardım sayfası kabuğu: AppBar + arama + bölümler + iletişim kartı.
class SssGorunumu extends StatefulWidget {
  /// AppBar başlığı.
  final String baslik;

  /// Üst karttaki açıklama satırı ("Yoklama, devir ve hakediş...").
  final String ustAciklama;

  /// Üst karttaki simge — rolü bir bakışta ayırt ettirir.
  final IconData ustIkon;

  final List<SssBolum> bolumler;

  /// Bölüm çipleri: iki ve üzeri bölümde anlamlı.
  final bool cipGoster;

  const SssGorunumu({
    super.key,
    required this.baslik,
    required this.ustAciklama,
    required this.ustIkon,
    required this.bolumler,
    this.cipGoster = true,
  });

  @override
  State<SssGorunumu> createState() => _SssGorunumuState();
}

class _SssGorunumuState extends State<SssGorunumu> {
  final _aramaCtrl = TextEditingController();
  String _sorgu = '';
  String? _seciliBolum;

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  bool get _cipVar => widget.cipGoster && widget.bolumler.length > 1;

  /// Arama ve bölüm çipi birlikte uygulanır; sonuç bölüm bölüm döner.
  List<SssBolum> get _sonuclar {
    final q = _sorgu.trim().toLowerCase();
    final liste = <SssBolum>[];
    for (final bolum in widget.bolumler) {
      if (_seciliBolum != null && bolum.baslik != _seciliBolum) continue;
      final sorular = q.isEmpty
          ? bolum.sorular
          : bolum.sorular
              .where((s) =>
                  s.soru.toLowerCase().contains(q) ||
                  s.cevap.toLowerCase().contains(q))
              .toList();
      if (sorular.isNotEmpty) {
        liste.add(SssBolum(
            baslik: bolum.baslik, ikon: bolum.ikon, sorular: sorular));
      }
    }
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    final sonuclar = _sonuclar;
    // Tek bölümlü sayfada başlık satırı gereksiz gürültü.
    final basliklariGoster = widget.bolumler.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.baslik),
        bottom: SssArama(
          denetleyici: _aramaCtrl,
          onDegisti: (v) => setState(() => _sorgu = v),
          bolumler: _cipVar ? [for (final b in widget.bolumler) b.baslik] : const [],
          seciliBolum: _seciliBolum,
          onBolum: (b) => setState(() => _seciliBolum = b),
          yaziOlcegi: MediaQuery.textScalerOf(context).scale(1.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (_sorgu.isEmpty && _seciliBolum == null)
            SliverToBoxAdapter(child: _ustKart(context)),
          if (sonuclar.isEmpty)
            SliverToBoxAdapter(child: SssSonucYok(sorgu: _sorgu))
          else
            for (final bolum in sonuclar) ...[
              if (basliklariGoster)
                SliverToBoxAdapter(child: _bolumBasligi(context, bolum)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    Bosluk.l, basliklariGoster ? 0 : Bosluk.s, Bosluk.l, 0),
                sliver: SliverList.builder(
                  itemCount: bolum.sorular.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: Bosluk.m),
                    child: SssKarti(sss: bolum.sorular[i]),
                  ),
                ),
              ),
            ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Bosluk.l),
              child: _iletisimKarti(context),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Bosluk.xl)),
        ],
      ),
    );
  }

  Widget _ustKart(BuildContext context) {
    final cs = context.cs;
    return Container(
      margin: const EdgeInsets.all(Bosluk.l),
      padding: const EdgeInsets.all(Bosluk.xl),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(Yaricap.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Size nasıl yardımcı olabiliriz?',
                  style: context.metin.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: Bosluk.s),
                Text(
                  widget.ustAciklama,
                  style: context.metin.bodyMedium
                      ?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(width: Bosluk.l),
          Container(
            padding: const EdgeInsets.all(Bosluk.l),
            decoration: BoxDecoration(
              color: cs.onPrimaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Yaricap.l),
            ),
            child: Icon(widget.ustIkon, size: 36, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _bolumBasligi(BuildContext context, SssBolum bolum) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
      child: Row(
        children: [
          Icon(bolum.ikon, size: 18, color: cs.primary),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(
              bolum.baslik,
              style: context.metin.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iletisimKarti(BuildContext context) {
    final renkler = context.renkler;
    return Container(
      decoration: BoxDecoration(
        color: renkler.vurguZemin,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: renkler.vurgu.withValues(alpha: 0.24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Yaricap.l),
          onTap: _epostaAc,
          child: Padding(
            padding: const EdgeInsets.all(Bosluk.xl),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Bosluk.m),
                  decoration: BoxDecoration(
                    color: renkler.vurgu,
                    borderRadius: BorderRadius.circular(Yaricap.m),
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: context.cs.surface,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Bosluk.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cevabı bulamadınız mı?',
                        style: context.metin.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: Bosluk.xs),
                      Text(
                        'binayakademi@gmail.com adresine yazın.',
                        style: context.metin.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: context.cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _epostaAc() async {
    final uri = Uri(scheme: 'mailto', path: 'binayakademi@gmail.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                              AÇILIR SORU KARTI                             */
/* -------------------------------------------------------------------------- */

class SssKarti extends StatefulWidget {
  final SssSoru sss;

  const SssKarti({super.key, required this.sss});

  @override
  State<SssKarti> createState() => _SssKartiState();
}

class _SssKartiState extends State<SssKarti>
    with SingleTickerProviderStateMixin {
  bool _acik = false;
  late AnimationController _kontrolcu;
  late Animation<double> _okDonusu;
  late Animation<double> _acilma;

  @override
  void initState() {
    super.initState();
    _kontrolcu = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _okDonusu = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _kontrolcu, curve: Curves.easeInOut),
    );
    _acilma = CurvedAnimation(parent: _kontrolcu, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _kontrolcu.dispose();
    super.dispose();
  }

  void _degistir() {
    setState(() {
      _acik = !_acik;
      if (_acik) {
        _kontrolcu.forward();
      } else {
        _kontrolcu.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _acik ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(
          color: _acik ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Yaricap.l),
          onTap: _degistir,
          child: Padding(
            padding: const EdgeInsets.all(Bosluk.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(Bosluk.s),
                      decoration: BoxDecoration(
                        color: _acik
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(Yaricap.s),
                      ),
                      child: Icon(
                        widget.sss.ikon,
                        size: 20,
                        color: _acik ? cs.onPrimary : cs.primary,
                      ),
                    ),
                    const SizedBox(width: Bosluk.m),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Bosluk.xs),
                        child: Text(
                          widget.sss.soru,
                          style: context.metin.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _acik ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Bosluk.s),
                    Padding(
                      padding: const EdgeInsets.only(top: Bosluk.xs),
                      child: RotationTransition(
                        turns: _okDonusu,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: _acik ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _acilma,
                  child: Padding(
                    padding: const EdgeInsets.only(top: Bosluk.l),
                    child: Text(
                      widget.sss.cevap,
                      style: context.metin.bodyMedium?.copyWith(
                        height: 1.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
