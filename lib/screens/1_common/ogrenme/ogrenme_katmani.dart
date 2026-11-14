// lib/screens/1_common/ogrenme/ogrenme_katmani.dart
//
// Rehberin çizildiği katman. MaterialApp.builder'da Navigator'un üstüne
// kurulur; böylece sayfaları, alt sayfaları ve diyalogları birlikte örter.
// Overlay'in dışında olduğu için burada Tooltip ve TextField kullanılmaz.
//
// Karartma parlayan deliği açık bırakır: delikten geçen dokunuş uygulamaya
// gider (son adımda ve yazı alanı olmayan okuma adımında gitmez), dışına
// dokunuş durdurulur. Açıklama, parlayan yerin hemen altında (yer yoksa
// üstünde) okla ona bağlı bir balondur; bitiş kartı da son parlayan yere
// bağlanır. Yerleşim ve renkler rehber_balonu.dart'ta.

import 'dart:math' as math;

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedef_bulucu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_balonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_metni.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';

class OgrenmeKatmani extends StatefulWidget {
  final Widget child;

  const OgrenmeKatmani({super.key, required this.child});

  @override
  State<OgrenmeKatmani> createState() => _OgrenmeKatmaniState();
}

class _OgrenmeKatmaniState extends State<OgrenmeKatmani>
    with TickerProviderStateMixin {
  final _uygulama = GlobalKey();
  final _katman = GlobalKey();
  final _modu = OgrenmeModu.ornek;
  late final HedefBulucu _bulucu;

  /// Halkanın nabzı: döngünün ilk üçte ikisi dalga, kalanı bekleme.
  late final AnimationController _nabiz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Balonun ve halkanın girişi; her adımda ve bitişte yeniden.
  late final AnimationController _giris = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Yanlış dokunuşta balonun sallanması.
  late final AnimationController _sallanma = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Listenable _hareket =
      Listenable.merge([_nabiz, _giris, _sallanma]);

  double _klavye = 0;
  Rect _guvenli = Rect.zero;
  bool _hareketAzalt = false;

  /// Ekrandaki balon (durum, adım); değişince balon yeniden girer.
  (RehberDurumu, int)? _gosterilen;
  int _yanlisSayaci = 0;

  @override
  void initState() {
    super.initState();
    _bulucu = HedefBulucu(
      uygulama: _uygulama,
      katman: _katman,
      klavye: () => _klavye,
    );
    _modu.bulucu = _bulucu;
    _yanlisSayaci = _modu.yanlisSayaci;
    _modu.addListener(_degisti);
  }

  @override
  void dispose() {
    _modu.removeListener(_degisti);
    if (identical(_modu.bulucu, _bulucu)) _modu.bulucu = null;
    _nabiz.dispose();
    _giris.dispose();
    _sallanma.dispose();
    super.dispose();
  }

  /// Balon çizilir mi: bitişte her zaman; adımda hedef parlarken ya da hedef
  /// yokken ("Önceki ekrana dön"). Hedef bir an kaybolunca (alt sayfa
  /// açılıyor) ve menü açıkken çizilmez.
  bool get _balonGorunur {
    if (_modu.durum == RehberDurumu.bitis) return true;
    return _modu.adim != null &&
        !_modu.menuAcik &&
        (_modu.delik != null || _modu.hedefYok);
  }

  void _degisti() {
    final nabiz = _modu.acik && !_hareketAzalt;
    if (nabiz && !_nabiz.isAnimating) {
      _nabiz.repeat();
    } else if (!nabiz && _nabiz.isAnimating) {
      _nabiz.stop();
    }
    final balon = _balonGorunur ? (_modu.durum, _modu.adimNo) : null;
    if (balon != null && balon != _gosterilen) {
      if (_hareketAzalt) {
        _giris.value = 1;
      } else {
        _giris.forward(from: 0);
      }
    }
    _gosterilen = balon;
    if (_modu.yanlisSayaci != _yanlisSayaci) {
      _yanlisSayaci = _modu.yanlisSayaci;
      if (!_hareketAzalt) _sallanma.forward(from: 0);
    }
    setState(() {});
  }

  void _uygulamayaDokunus(PointerUpEvent e) {
    if (!_modu.acik) return;
    final delik = delikHesapla(_modu.delik, _guvenli);
    if (delik != null && delik.contains(e.localPosition)) {
      _modu.delikDokunusu();
    }
  }

  /// Balonun ve deliğin sığacağı alan: durum çubuğu, çentik ve klavye
  /// (klavye yoksa alttaki sistem çubuğu) hariç.
  static Rect _guvenliAlan(MediaQueryData mq) {
    final alt = math.max(mq.viewInsets.bottom, mq.padding.bottom);
    return Rect.fromLTRB(mq.padding.left, mq.padding.top,
        mq.size.width - mq.padding.right, mq.size.height - alt);
  }

  /// Sallanma: 0, −6, 6, −4, 4, 0 px.
  static double _sallanmaKaydi(double t) {
    if (t <= 0 || t >= 1) return 0;
    const noktalar = [0.0, -6.0, 6.0, -4.0, 4.0, 0.0];
    final konum = t * (noktalar.length - 1);
    final i = konum.floor();
    final a = noktalar[i];
    return a + (noktalar[i + 1] - a) * (konum - i);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    _klavye = mq.viewInsets.bottom;
    _hareketAzalt = mq.disableAnimations;
    _guvenli = _guvenliAlan(mq);
    final adim = _modu.adim;
    final durum = _modu.durum;
    final bitis = durum == RehberDurumu.bitis;
    final donus = durum == RehberDurumu.donus;
    final delik = donus ? null : _modu.delik;
    return Stack(
      key: _katman,
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: _uygulama,
          child: Listener(onPointerUp: _uygulamayaDokunus, child: widget.child),
        ),
        if (_modu.acik)
          AnimatedBuilder(
            animation: _hareket,
            builder: (context, _) {
              final giris = Curves.easeOutCubic.transform(_giris.value);
              final sallanma = _sallanmaKaydi(_sallanma.value);
              return RehberSahnesi(
                hedef: delik,
                konum: bitis ? _modu.sonDelik : null,
                guvenli: _guvenli,
                renkler: RehberRenkleri.baglamdan(context),
                // Hedef yokken ("Önceki ekrana dön", menü açık) ekran serbest.
                perde: bitis || donus || delik != null,
                // Dönüşte ekran görünür ama dokunuş, kapı kalkana kadar yutulur.
                saydam: donus,
                gecir: adim != null &&
                    !adim.kalici &&
                    (!adim.bilgi || adim.dokunulur),
                nabiz: bitis || _hareketAzalt ? null : _nabiz.value,
                giris: giris,
                sallanma: sallanma,
                onDokunus: (delikte) {
                  if (!delikte) return _modu.yanlisDokunus();
                  // Okuma adımında parlayan yer yalnız okunur.
                  if (adim != null && adim.kalici) _modu.delikDokunusu();
                },
                child: _balonGorunur ? _balon(giris, sallanma) : null,
              );
            },
          ),
      ],
    );
  }

  /// Balonun içeriği; giriş (solma + küçükten büyüme) ve sallanma burada,
  /// zemini ve oku aynı dönüşümle [RehberSahnesi] çizer.
  Widget _balon(double giris, double sallanma) {
    final icerik = _modu.durum == RehberDurumu.bitis
        ? RehberBitisKarti(
            kural: _modu.gorev!.kural,
            denendi: _modu.denendi,
            donusEtiketi: _modu.gorev!.sayfa.donusEtiketi,
            onDon: () => _modu.kapat(geriDon: true),
          )
        : RehberAdimPaneli(
            adim: _modu.adim!,
            no: _modu.adimNo + 1,
            toplam: _modu.gorev!.adimlar.length,
            hedefYok: _modu.hedefYok,
            sonrakiYok: _modu.sonrakiYok,
            yanlis: _modu.yanlis,
            onKapat: () => _modu.kapat(geriDon: true),
            onAnladim: _modu.anladim,
          );
    final olcek = RehberSahnesi.olcek(giris);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.translationValues(sallanma, 0, 0)
        ..multiply(Matrix4.diagonal3Values(olcek, olcek, 1)),
      child: Opacity(opacity: giris, child: icerik),
    );
  }
}

/// Balon içeriğinin ortak zemini. Zemini ve oku [RehberSahnesi] çizer;
/// burada yazı ve ikon balonun yazı renginde, butonların mürekkebi için
/// saydam Material.
class _BalonIcerigi extends StatelessWidget {
  final Widget child;

  const _BalonIcerigi({required this.child});

  @override
  Widget build(BuildContext context) {
    final on = RehberRenkleri.baglamdan(context).onBalon;
    return Material(
      type: MaterialType.transparency,
      child: IconTheme.merge(
        data: IconThemeData(color: on, size: 18),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: on),
          // Klavye açıkken ya da yatay ekranda balon güvenli alana sığmazsa
          // taşmak yerine kayar.
          child: Semantics(
            container: true,
            liveRegion: true,
            child: SingleChildScrollView(primary: false, child: child),
          ),
        ),
      ),
    );
  }
}

/// Balonda ikonlu kısa ek satır (son adımın sonucu, "Önceki ekrana dön").
class _EkSatir extends StatelessWidget {
  final IconData ikon;
  final String metin;
  final bool kalin;

  const _EkSatir({required this.ikon, required this.metin, this.kalin = false});

  @override
  Widget build(BuildContext context) {
    final on = RehberRenkleri.baglamdan(context).onBalon;
    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.s, right: Bosluk.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(ikon, size: 18, color: on),
          ),
          const SizedBox(width: Bosluk.s),
          Expanded(
            child: Text(
              metin,
              style: context.metin.bodyMedium?.copyWith(
                color: on,
                fontWeight: kalin ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yanlış dokunuş uyarısı: balonun ters renginde, balonda en çok göze
/// çarpan satır.
class _Ipucu extends StatelessWidget {
  const _Ipucu();

  @override
  Widget build(BuildContext context) {
    final r = RehberRenkleri.baglamdan(context);
    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.s, right: Bosluk.m),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: r.onBalon,
          borderRadius: BorderRadius.circular(Yaricap.s),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.s, Bosluk.xs, Bosluk.m, Bosluk.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: r.balon),
              const SizedBox(width: Bosluk.xs),
              Flexible(
                child: Text(
                  'Parlayan yere dokun.',
                  style: context.metin.labelLarge?.copyWith(color: r.balon),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adım balonunun içeriği: sayaç ve «Kapat», adım cümlesi, duruma göre kısa
/// ek satır, okuma adımında «Anladım».
class RehberAdimPaneli extends StatelessWidget {
  final OgrenmeAdimi adim;
  final int no;
  final int toplam;
  final bool hedefYok;

  /// «Anladım»a basıldı, sonraki adımın hedefi ekranda yok.
  final bool sonrakiYok;
  final bool yanlis;
  final VoidCallback onKapat;
  final VoidCallback onAnladim;

  const RehberAdimPaneli({
    super.key,
    required this.adim,
    required this.no,
    required this.toplam,
    this.hedefYok = false,
    this.sonrakiYok = false,
    this.yanlis = false,
    required this.onKapat,
    required this.onAnladim,
  });

  @override
  Widget build(BuildContext context) {
    final on = RehberRenkleri.baglamdan(context).onBalon;
    final metin = context.metin;
    return _BalonIcerigi(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.xs, Bosluk.xs, Bosluk.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (toplam > 1)
                  Text(
                    '$no/$toplam',
                    style: metin.labelLarge?.copyWith(color: on),
                  ),
                const Spacer(),
                // Varsayılan ana renk balon zemininde metin eşiğinin altında.
                TextButton(
                  onPressed: onKapat,
                  style: TextButton.styleFrom(foregroundColor: on),
                  child: const Text('Kapat'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Bosluk.m),
              child: Text.rich(
                rehberMetni(adim.metin,
                    stil: metin.titleMedium?.copyWith(color: on)),
              ),
            ),
            if (yanlis) const _Ipucu(),
            if (adim.kalici && adim.sonuc != null)
              _EkSatir(
                ikon: Icons.info_outline_rounded,
                metin: sonucCumlesi(adim.sonuc!),
              ),
            if (sonrakiYok && !hedefYok)
              _EkSatir(
                ikon: Icons.info_outline_rounded,
                metin: adim.yoksaMetni,
                kalin: true,
              ),
            if (hedefYok)
              const _EkSatir(
                ikon: Icons.arrow_back_rounded,
                metin: 'Önceki ekrana dön, oradan sürdürelim.',
                kalin: true,
              ),
            if (adim.bilgi)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: Bosluk.s, right: Bosluk.m),
                  child: FilledButton(
                    onPressed: onAnladim,
                    child: const Text('Anladım'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bitiş kartı: kural ve tek çıkış, son parlayan yere bağlı. Denemeden
/// gerçeğe aynı ekranda geçilmez; kullanıcı rehberin başladığı sayfaya döner,
/// ne yapacaksa orada kendisi başlatır.
class RehberBitisKarti extends StatelessWidget {
  final String? kural;

  /// Son butona dokunuldu.
  final bool denendi;

  /// Dönüş butonunun adı ("Takvime dön").
  final String donusEtiketi;
  final VoidCallback onDon;

  const RehberBitisKarti({
    super.key,
    required this.kural,
    required this.denendi,
    required this.donusEtiketi,
    required this.onDon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final on = RehberRenkleri.baglamdan(context).onBalon;
    final metin = context.metin;
    return _BalonIcerigi(
      child: Padding(
        padding: const EdgeInsets.all(Bosluk.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(Bosluk.s),
                child: Icon(Icons.check_rounded, size: 24, color: cs.onPrimary),
              ),
            ),
            const SizedBox(height: Bosluk.m),
            Text(
              'Hepsi bu kadar',
              style: metin.titleLarge?.copyWith(color: on),
            ),
            if (denendi)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Denemeydi, herhangi bir işlem yapılmadı.',
                  style: metin.bodyMedium
                      ?.copyWith(color: on, fontWeight: FontWeight.w600),
                ),
              ),
            if (kural != null) ...[
              const SizedBox(height: Bosluk.s),
              Text(kural!, style: metin.bodyMedium?.copyWith(color: on)),
            ],
            const SizedBox(height: Bosluk.l),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onDon, child: Text(donusEtiketi)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karartma, delik, halka ve balon tek çizimde: balon ölçülür, yeri ve
/// gerekirse balona yer açmak için kırpılan delik aynı yerleşimde bulunur
/// (bkz. [balonYeri]). Deliğin dışına dokunuş durdurulur, balona dokunuş
/// balona gider.
class RehberSahnesi extends SingleChildRenderObjectWidget {
  /// Parlayan yerin görünen alanı (katman koordinatı); null ise delik yok.
  final Rect? hedef;

  /// Delik yokken balonun bağlanacağı yer (bitişte son parlayan yer).
  final Rect? konum;

  /// Durum çubuğu, çentik ve klavye hariç alan.
  final Rect guvenli;
  final RehberRenkleri renkler;

  /// Karartma çizilsin ve dışarıdaki dokunuşu durdursun mu? Kapalıyken
  /// yalnız balon dokunuş alır, ekran serbesttir.
  final bool perde;

  /// Karartma görünmez ama dokunuşu yine durdurur (rehber kapanırken).
  final bool saydam;

  /// Delikten geçen dokunuş uygulamaya gitsin mi (son adımda gitmez).
  final bool gecir;

  /// Nabız döngüsü 0–1; null ise nabız yok (bitiş, hareketi azalt).
  final double? nabiz;

  /// Balonun ve halkanın girişi 0–1.
  final double giris;

  /// Balonun yatay sallanması (px).
  final double sallanma;
  final ValueChanged<bool>? onDokunus;

  const RehberSahnesi({
    super.key,
    required this.hedef,
    this.konum,
    required this.guvenli,
    required this.renkler,
    this.perde = true,
    this.saydam = false,
    this.gecir = false,
    this.nabiz,
    this.giris = 1,
    this.sallanma = 0,
    this.onDokunus,
    super.child,
  });

  /// Girişte balon %96'dan büyür; içerik ve zemin aynı ölçeği kullanır.
  static double olcek(double giris) => 0.96 + 0.04 * giris;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _SahneKutusu()..ayarla(this);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _SahneKutusu).ayarla(this);
}

class _SahneKutusu extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  Rect? _hedef;
  Rect? _konum;
  Rect _guvenli = Rect.zero;
  RehberRenkleri? _renkler;
  bool _perde = true;
  bool _saydam = false;
  bool _gecir = false;
  double? _nabiz;
  double _giris = 1;
  double _sallanma = 0;
  ValueChanged<bool>? _onDokunus;

  /// Son yerleşimin sonucu: çizilen delik ve balonun yeri.
  Rect? _delik;
  BalonYeri? _yer;

  void ayarla(RehberSahnesi w) {
    if (w.hedef != _hedef || w.konum != _konum || w.guvenli != _guvenli) {
      _hedef = w.hedef;
      _konum = w.konum;
      _guvenli = w.guvenli;
      markNeedsLayout();
    }
    _renkler = w.renkler;
    _perde = w.perde;
    _saydam = w.saydam;
    _gecir = w.gecir;
    _nabiz = w.nabiz;
    _giris = w.giris;
    _sallanma = w.sallanma;
    _onDokunus = w.onDokunus;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final kesisim = _guvenli.intersect(Offset.zero & size);
    final guvenli = kesisim.width > 0 && kesisim.height > 0
        ? kesisim
        : Offset.zero & size;
    final delik = delikHesapla(_hedef, guvenli);
    final c = child;
    if (c == null) {
      _delik = delik;
      _yer = null;
      return;
    }
    final w = balonGenisligi(guvenli);
    c.layout(
      BoxConstraints(
        minWidth: w,
        maxWidth: w,
        maxHeight: math.max(0.0, guvenli.height - 2 * BalonOlcu.dikey),
      ),
      parentUsesSize: true,
    );
    final yer = balonYeri(
        delik: delik, konum: _konum, guvenli: guvenli, balon: c.size);
    (c.parentData! as BoxParentData).offset = yer.sol;
    _yer = yer;
    _delik = yer.delik;
  }

  /// Balonun dokunuş alanı: gövde ve ok payı. Pay deliğe taşarsa delikteki
  /// dokunuş uygulamaya gider; yalnız gövde deliğin önünde kalır.
  bool _balondaMi(Offset p) {
    final c = child;
    final yer = _yer;
    if (c == null || yer == null) return false;
    final govde = yer.sol & c.size;
    if (govde.contains(p)) return true;
    return govde.inflate(BalonOlcu.okBoyu).contains(p) &&
        !(_delik?.contains(p) ?? false);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (_balondaMi(position)) {
      final c = child!;
      result.addWithPaintOffset(
        offset: (c.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (sonuc, yerel) => c.hitTest(sonuc, position: yerel),
      );
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    if (!_perde) return false;
    if (_gecir && (_delik?.contains(position) ?? false)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerUpEvent) return;
    if (_balondaMi(entry.localPosition)) return;
    _onDokunus?.call(_delik?.contains(entry.localPosition) ?? false);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final renkler = _renkler;
    if (renkler == null || _saydam) return;
    final canvas = context.canvas;
    final delik = _delik?.shift(offset);
    final sekil = delik == null ? null : delikSekli(delik);
    if (_perde) {
      final yol = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(offset & size);
      if (sekil != null) yol.addRRect(sekil);
      canvas.drawPath(yol, Paint()..color = renkler.karartma);
    }
    if (sekil != null) _halkayiCiz(canvas, sekil, renkler.halka);
    final c = child;
    final yer = _yer;
    if (c == null || yer == null || _giris <= 0) return;
    _balonuCiz(canvas, (yer.sol + offset) & c.size, yer, offset, renkler);
    context.paintChild(c, yer.sol + offset);
  }

  /// Halka delikten boşlukla ayrı durur (beyaz içerik | koyu boşluk | beyaz
  /// çizgi); girişte dışarıdan deliğe "odaklanır". Nabız ikinci bir çizgi
  /// olarak dışa yayılıp söner.
  void _halkayiCiz(Canvas canvas, RRect sekil, Color renk) {
    const kalinlik = BalonOlcu.halkaKalinligi;
    const ic = BalonOlcu.halkaAraligi + kalinlik / 2;
    canvas.drawRRect(
      sekil.inflate(ic + (1 - _giris) * 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kalinlik
        ..color = renk.withValues(alpha: renk.a * _giris),
    );
    final nabiz = _nabiz;
    if (nabiz == null || _giris < 1) return;
    final t = nabiz * 1.5;
    if (t >= 1) return;
    final dalga = Curves.easeOut.transform(t);
    canvas.drawRRect(
      sekil.inflate(ic + 12 * dalga),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kalinlik - 1.5 * dalga
        ..color = renk.withValues(alpha: renk.a * 0.85 * (1 - dalga)),
    );
  }

  /// Balon zemini ve oku: içerikle aynı dönüşüm (giriş ölçeği, sallanma).
  void _balonuCiz(Canvas canvas, Rect govde, BalonYeri yer, Offset offset,
      RehberRenkleri renkler) {
    final yol = balonYolu(govde, yer.ok, yer.okX + offset.dx);
    final olcek = RehberSahnesi.olcek(_giris);
    final merkez = govde.center;
    canvas.save();
    canvas.translate(merkez.dx + _sallanma, merkez.dy);
    canvas.scale(olcek);
    canvas.translate(-merkez.dx, -merkez.dy);
    final kenar = renkler.balonKenari;
    if (kenar == null) {
      canvas.drawShadow(
          yol, renkler.golge.withValues(alpha: _giris), 8, _giris < 1);
    }
    canvas.drawPath(
      yol,
      Paint()..color = renkler.balon.withValues(alpha: renkler.balon.a * _giris),
    );
    if (kenar != null) {
      canvas.drawPath(
        yol,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = kenar.withValues(alpha: kenar.a * _giris),
      );
    }
    canvas.restore();
  }
}
