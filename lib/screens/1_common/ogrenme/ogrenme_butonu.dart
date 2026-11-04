// lib/screens/1_common/ogrenme/ogrenme_butonu.dart
//
// Başlıktaki "?" ve açtığı "Bu sayfada ne öğrenmek istersin?" listesi.
// Ekranda gereken şey varsa (ör. takvimde ders) rehber gerçek ekranda adım
// adım başlar; yoksa aynı rehber numaralı adımlar olarak okunur.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_metni.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:flutter/material.dart';

class OgrenmeButonu extends StatelessWidget {
  final OgrenmeSayfasi sayfa;

  /// "Sık sorulanlar" bağlantısının rotası (role göre yardım sayfası).
  final String sssRotasi;

  const OgrenmeButonu({
    super.key,
    required this.sayfa,
    required this.sssRotasi,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Nasıl yapılır?',
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => _ac(context),
    );
  }

  Future<void> _ac(BuildContext context) async {
    final modu = OgrenmeModu.ornek;
    final gorevler = sayfaGorevleri(sayfa);
    // Hazır olma, liste açılmadan bakılır: liste ekranı örttükten sonra
    // hedefler görünmez olur.
    final bulucu = modu.bulucu;
    final yukleniyor = bulucu?.yukleniyorMu() ?? false;
    final hazir = <String>{
      if (bulucu != null && !yukleniyor)
        for (final g in gorevler)
          if (bulucu.baslatilabilir(g)) g.id,
    };
    final navigator = Navigator.of(context);
    final sayfaRotasi = ModalRoute.of(context);
    final secilen = await altSayfaGoster<OgrenmeGorevi>(
      context,
      cocuk: OgrenmeListesi(
        gorevler: gorevler,
        hazir: hazir,
        yukleniyor: yukleniyor,
        onSss: () {
          navigator.pop();
          navigator.pushNamed(sssRotasi);
        },
      ),
    );
    if (secilen == null || sayfaRotasi == null || !sayfaRotasi.isActive) {
      return;
    }
    modu.baslat(secilen, navigator: navigator, baslangic: sayfaRotasi);
  }
}

/// Listenin içeriği. Hazır rehbere dokununca liste o rehberle kapanır;
/// hazır olmayana dokununca aynı yerde okuma görünümü açılır.
class OgrenmeListesi extends StatefulWidget {
  final List<OgrenmeGorevi> gorevler;

  /// Ekranda hemen başlayabilecek rehberlerin kimlikleri.
  final Set<String> hazir;
  final bool yukleniyor;
  final VoidCallback onSss;

  const OgrenmeListesi({
    super.key,
    required this.gorevler,
    required this.hazir,
    required this.yukleniyor,
    required this.onSss,
  });

  @override
  State<OgrenmeListesi> createState() => _OgrenmeListesiState();
}

class _OgrenmeListesiState extends State<OgrenmeListesi> {
  OgrenmeGorevi? _okunan;

  String _altBaslik(OgrenmeGorevi g) {
    if (widget.hazir.contains(g.id)) return 'Ekranda adım adım gösterilir.';
    if (widget.yukleniyor) return 'Yükleniyor…';
    return '${g.kosulMetni} deneyebilirsin.';
  }

  @override
  Widget build(BuildContext context) {
    final okunan = _okunan;
    if (okunan != null) return OgrenmeOkuma(gorev: okunan);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Bosluk.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AltSayfaBasligi(
            ikon: Icons.help_outline_rounded,
            baslik: 'Bu sayfada ne öğrenmek istersin?',
          ),
          for (final g in widget.gorevler)
            ListeSatiri(
              baslik: g.baslik,
              altBaslik: _altBaslik(g),
              okGoster: true,
              onTap: () => widget.hazir.contains(g.id)
                  ? Navigator.pop(context, g)
                  : setState(() => _okunan = g),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Bosluk.s),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onSss,
                child: const Text('Aradığın yok mu? Sık sorulanlar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ekranda gereken şey yokken rehberin okunur hali: numaralı adımlar ve kural.
class OgrenmeOkuma extends StatelessWidget {
  final OgrenmeGorevi gorev;

  const OgrenmeOkuma({super.key, required this.gorev});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Bosluk.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AltSayfaBasligi(
            ikon: Icons.menu_book_rounded,
            baslik: gorev.baslik,
            altBaslik: '${gorev.kosulMetni} ekranda deneyebilirsin.',
          ),
          for (final (i, adim) in gorev.adimlar.indexed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: metin.labelLarge
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: Bosluk.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                            rehberMetni(adim.metin, stil: metin.bodyLarge)),
                        if (adim.kalici && adim.sonuc != null)
                          Text(
                            'Buna basınca ${adim.sonuc}.',
                            style: metin.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (gorev.kural != null)
            Container(
              margin:
                  const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, 0),
              padding: const EdgeInsets.all(Bosluk.m),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Yaricap.m),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: Bosluk.s),
                  Expanded(child: Text(gorev.kural!, style: metin.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
