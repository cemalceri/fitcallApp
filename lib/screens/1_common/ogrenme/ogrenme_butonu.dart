// lib/screens/1_common/ogrenme/ogrenme_butonu.dart
//
// Başlıktaki "?" ve açtığı "Bu sayfada ne öğrenmek istersin?" listesi.
// Ekranda gereken şey varsa (ör. takvimde ders) rehber gerçek ekranda adım
// adım başlar; yoksa aynı rehber numaralı adımlar olarak okunur. Rehberi
// olmayan sayfada "?" doğrudan Sık sorulanlar'ı açar. Yeri hep başlık
// satırının en sağı.

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_metni.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:material_ui/material_ui.dart';

class OgrenmeButonu extends StatelessWidget {
  /// Rehberi olan sayfa; null ise "?" doğrudan Sık sorulanlar'ı açar.
  final OgrenmeSayfasi? sayfa;

  /// "Sık sorulanlar" bağlantısının rotası. Verilmezse (rollerle ortak
  /// sayfa) açık profilin rolünden bulunur.
  final String? sssRotasi;

  /// Bu ekranda gösterilmeyecek rehberler (ör. tek profilli üyede
  /// "Çocuğumun derslerini nasıl görürüm?").
  final Set<String> haric;

  /// Komşuları kutulu başlık butonuysa ([BaslikIkonButonu]) aynı biçim;
  /// AppBar'da düz ikon.
  final bool kutulu;

  /// Komşuları sıkı yerleşimli ikonsa (program başlığı) aynı sıklık.
  final bool kompakt;

  const OgrenmeButonu({
    super.key,
    this.sayfa,
    this.sssRotasi,
    this.haric = const {},
    this.kutulu = false,
    this.kompakt = false,
  });

  List<OgrenmeGorevi> get _gorevler {
    final s = sayfa;
    if (s == null) return const [];
    return [
      for (final g in sayfaGorevleri(s))
        if (!haric.contains(g.id)) g,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ipucu = _gorevler.isEmpty ? 'Sık sorulanlar' : 'Nasıl yapılır?';
    final buton = kutulu
        ? BaslikIkonButonu(
            ikon: Icons.help_outline_rounded,
            ipucu: ipucu,
            onTap: () => _ac(context),
          )
        : IconButton(
            tooltip: ipucu,
            icon: const Icon(Icons.help_outline_rounded),
            visualDensity: kompakt ? VisualDensity.compact : null,
            onPressed: () => _ac(context),
          );
    return OgrenmeHedefi(id: Hedef.ogrenmeButonu, child: buton);
  }

  Future<String> _sss() async =>
      sssRotasi ??
      yardimRotasi((await StorageService.uyeProfilBilgileriniGetir())?.rol);

  Future<void> _ac(BuildContext context) async {
    var gorevler = _gorevler;
    final navigator = Navigator.of(context);
    // Ortak sayfada role özel rehber varsa açık profilin rolüne süz.
    if (gorevler.any((g) => g.roller.isNotEmpty)) {
      final rol = (await StorageService.uyeProfilBilgileriniGetir())?.rol;
      if (!context.mounted) return;
      gorevler = [
        for (final g in gorevler)
          if (g.rolde(rol)) g,
      ];
    }
    if (gorevler.isEmpty) {
      navigator.pushNamed(await _sss());
      return;
    }
    final modu = OgrenmeModu.ornek;
    // Hazır olma, liste açılmadan bakılır: liste ekranı örttükten sonra
    // hedefler görünmez olur.
    final bulucu = modu.bulucu;
    final yukleniyor = bulucu?.yukleniyorMu() ?? false;
    final hazir = <String>{
      if (bulucu != null && !yukleniyor)
        for (final g in gorevler)
          if (bulucu.baslatilabilir(g)) g.id,
    };
    final sayfaRotasi = ModalRoute.of(context);
    final sekme = rehberSekmesi(context);
    final secilen = await altSayfaGoster<OgrenmeGorevi>(
      context,
      cocuk: OgrenmeListesi(
        gorevler: gorevler,
        hazir: hazir,
        yukleniyor: yukleniyor,
        onSss: () async {
          navigator.pop();
          navigator.pushNamed(await _sss());
        },
      ),
    );
    if (secilen == null || sayfaRotasi == null || !sayfaRotasi.isActive) {
      return;
    }
    modu.baslat(
      secilen,
      navigator: navigator,
      baslangic: sayfaRotasi,
      sekme: sekme,
    );
  }
}

/// [context] bir kabuk sekmesindeyse hangisi olduğu; rehber bitince bu
/// sekmeye dönülür.
RehberSekmesi? rehberSekmesi(BuildContext context) {
  final kabuk = KabukMenusu.kabuk(context);
  final aktif = kabuk?.aktifSekme;
  final gec = kabuk?.sekmeyeGec;
  if (aktif == null || gec == null) return null;
  return RehberSekmesi(sekme: aktif(), aktif: aktif, gec: gec);
}

/// [gorev]'i [context]'in sayfasında açar: ekranda gereken şey varsa adım
/// adım başlar, yoksa numaralı okuma alt sayfası açılır.
Future<void> rehberiAc(BuildContext context, OgrenmeGorevi gorev) async {
  final modu = OgrenmeModu.ornek;
  final bulucu = modu.bulucu;
  final rota = ModalRoute.of(context);
  if (bulucu != null &&
      rota != null &&
      !bulucu.yukleniyorMu() &&
      bulucu.baslatilabilir(gorev)) {
    modu.baslat(
      gorev,
      navigator: Navigator.of(context),
      baslangic: rota,
      sekme: rehberSekmesi(context),
    );
    return;
  }
  await altSayfaGoster<void>(context, cocuk: OgrenmeOkuma(gorev: gorev));
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
