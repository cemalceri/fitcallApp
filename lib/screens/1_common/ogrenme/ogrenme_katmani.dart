// lib/screens/1_common/ogrenme/ogrenme_katmani.dart
//
// Rehberin çizildiği katman. MaterialApp.builder'da Navigator'un üstüne
// kurulur; böylece sayfaları, alt sayfaları ve diyalogları birlikte örter.
// Overlay'in dışında olduğu için burada Tooltip ve TextField kullanılmaz.
//
// Karartma parlayan deliği açık bırakır: delikten geçen dokunuş uygulamaya
// gider (son adımda gitmez), dışına dokunuş durdurulur.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedef_bulucu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/1_common/ogrenme/rehber_metni.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class OgrenmeKatmani extends StatefulWidget {
  final Widget child;

  const OgrenmeKatmani({super.key, required this.child});

  @override
  State<OgrenmeKatmani> createState() => _OgrenmeKatmaniState();
}

class _OgrenmeKatmaniState extends State<OgrenmeKatmani>
    with SingleTickerProviderStateMixin {
  final _uygulama = GlobalKey();
  final _katman = GlobalKey();
  final _modu = OgrenmeModu.ornek;
  late final HedefBulucu _bulucu;
  late final AnimationController _nabiz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  double _klavye = 0;

  /// Delik, hedefin çevresine bu kadar taşar.
  static const _pay = 6.0;

  @override
  void initState() {
    super.initState();
    _bulucu = HedefBulucu(
      uygulama: _uygulama,
      katman: _katman,
      klavye: () => _klavye,
    );
    _modu.bulucu = _bulucu;
    _modu.addListener(_degisti);
  }

  @override
  void dispose() {
    _modu.removeListener(_degisti);
    if (identical(_modu.bulucu, _bulucu)) _modu.bulucu = null;
    _nabiz.dispose();
    super.dispose();
  }

  void _degisti() {
    if (_modu.acik && !_nabiz.isAnimating) {
      _nabiz.repeat();
    } else if (!_modu.acik && _nabiz.isAnimating) {
      _nabiz.stop();
    }
    setState(() {});
  }

  void _uygulamayaDokunus(PointerUpEvent e) {
    if (!_modu.acik) return;
    final delik = _modu.delik;
    if (delik != null && delik.inflate(_pay).contains(e.localPosition)) {
      _modu.delikDokunusu();
    }
  }

  @override
  Widget build(BuildContext context) {
    _klavye = MediaQuery.viewInsetsOf(context).bottom;
    final delik = _modu.delik?.inflate(_pay);
    final adim = _modu.adim;
    final durum = _modu.durum;
    final bitis = durum == RehberDurumu.bitis;
    final donus = durum == RehberDurumu.donus;
    return Stack(
      key: _katman,
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: _uygulama,
          child: Listener(onPointerUp: _uygulamayaDokunus, child: widget.child),
        ),
        if (bitis || donus || (adim != null && delik != null))
          AnimatedBuilder(
            animation: _nabiz,
            builder: (context, _) => _Perde(
              delik: bitis || donus ? null : delik,
              gecir: adim != null && !adim.kalici,
              // Dönüşte ekran görünür ama dokunuş, kapı kalkana kadar yutulur.
              renk: donus
                  ? Colors.transparent
                  : context.cs.scrim.withValues(alpha: 0.55),
              halka: context.cs.primary,
              nabiz: Curves.easeOut.transform(_nabiz.value),
              onDokunus: (delikte) => delikte && adim != null && adim.kalici
                  ? _modu.delikDokunusu()
                  : _modu.yanlisDokunus(),
            ),
          ),
        if (adim != null || bitis) _panelYeri(context, delik),
      ],
    );
  }

  /// Panel, delik alttaysa üste, üstteyse alta yerleşir.
  Widget _panelYeri(BuildContext context, Rect? delik) {
    final mq = MediaQuery.of(context);
    final ustte = delik != null && delik.center.dy > mq.size.height / 2;
    final alt = mq.viewInsets.bottom > mq.padding.bottom
        ? mq.viewInsets.bottom
        : mq.padding.bottom;
    final panel = Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _modu.durum == RehberDurumu.bitis
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
                yanlis: _modu.yanlis,
                onKapat: () => _modu.kapat(geriDon: true),
                onAnladim: _modu.anladim,
              ),
      ),
    );
    return Positioned(
      left: Bosluk.l,
      right: Bosluk.l,
      top: ustte ? mq.padding.top + Bosluk.s : null,
      bottom: ustte ? null : alt + Bosluk.s,
      child: panel,
    );
  }
}

/// Panel ve kart için ortak yüzey.
class _Kart extends StatelessWidget {
  final Widget child;

  const _Kart({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cs.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(Yaricap.l),
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.xs, Bosluk.xs, Bosluk.l),
        child: child,
      ),
    );
  }
}

/// Adım paneli: üst satır, adım cümlesi ve duruma göre kısa ek satır.
class RehberAdimPaneli extends StatelessWidget {
  final OgrenmeAdimi adim;
  final int no;
  final int toplam;
  final bool hedefYok;
  final bool yanlis;
  final VoidCallback onKapat;
  final VoidCallback onAnladim;

  const RehberAdimPaneli({
    super.key,
    required this.adim,
    required this.no,
    required this.toplam,
    this.hedefYok = false,
    this.yanlis = false,
    required this.onKapat,
    required this.onAnladim,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = Theme.of(context).textTheme;
    final ikincil = metin.bodyMedium?.copyWith(color: cs.onSurfaceVariant);
    return _Kart(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Deneme · Hiçbir şey değişmez · $no/$toplam',
                  style:
                      metin.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(onPressed: onKapat, child: const Text('Kapat')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.m),
            child: Text.rich(
              rehberMetni(adim.metin, stil: metin.titleMedium),
            ),
          ),
          if (adim.kalici && adim.sonuc != null) ...[
            const SizedBox(height: Bosluk.xs),
            Text(sonucCumlesi(adim.sonuc!), style: ikincil),
          ],
          if (hedefYok) ...[
            const SizedBox(height: Bosluk.xs),
            Text('Önceki ekrana dön, oradan sürdürelim.', style: ikincil),
          ],
          if (yanlis) ...[
            const SizedBox(height: Bosluk.xs),
            Text(
              'Parlayan yere dokun.',
              style: metin.bodyMedium
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ],
          if (adim.bilgi)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: Bosluk.s, right: Bosluk.m),
                child: FilledButton(
                  onPressed: onAnladim,
                  child: const Text('Anladım'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bitiş kartı: kural ve tek çıkış. Denemeden gerçeğe aynı ekranda
/// geçilmez; kullanıcı rehberin başladığı sayfaya döner, ne yapacaksa orada
/// kendisi başlatır.
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
    final metin = Theme.of(context).textTheme;
    return _Kart(
      child: Padding(
        padding: const EdgeInsets.only(top: Bosluk.m, right: Bosluk.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (denendi)
              Padding(
                padding: const EdgeInsets.only(bottom: Bosluk.xs),
                child: Text(
                  'Denemeydi, bir şey olmadı.',
                  style: metin.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            Text(
              'Hepsi bu kadar',
              style: metin.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (kural != null) ...[
              const SizedBox(height: Bosluk.s),
              Text(kural!, style: metin.bodyMedium),
            ],
            const SizedBox(height: Bosluk.l),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: onDon, child: Text(donusEtiketi)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karartma: deliği açık bırakır, dışına dokunuşu durdurur.
class _Perde extends LeafRenderObjectWidget {
  final Rect? delik;

  /// Delikten geçen dokunuş uygulamaya gitsin mi (son adımda gitmez).
  final bool gecir;
  final Color renk;
  final Color halka;
  final double nabiz;
  final ValueChanged<bool> onDokunus;

  const _Perde({
    required this.delik,
    required this.gecir,
    required this.renk,
    required this.halka,
    required this.nabiz,
    required this.onDokunus,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _PerdeKutusu()
    ..delik = delik
    ..gecir = gecir
    ..renk = renk
    ..halka = halka
    ..nabiz = nabiz
    ..onDokunus = onDokunus;

  @override
  void updateRenderObject(BuildContext context, _PerdeKutusu kutu) => kutu
    ..delik = delik
    ..gecir = gecir
    ..renk = renk
    ..halka = halka
    ..nabiz = nabiz
    ..onDokunus = onDokunus;
}

class _PerdeKutusu extends RenderBox {
  Rect? _delik;
  bool gecir = true;
  Color _renk = Colors.transparent;
  Color _halka = Colors.transparent;
  double _nabiz = 0;
  ValueChanged<bool>? onDokunus;

  set delik(Rect? v) {
    if (v == _delik) return;
    _delik = v;
    markNeedsPaint();
  }

  set renk(Color v) {
    if (v == _renk) return;
    _renk = v;
    markNeedsPaint();
  }

  set halka(Color v) {
    if (v == _halka) return;
    _halka = v;
    markNeedsPaint();
  }

  set nabiz(double v) {
    if (v == _nabiz) return;
    _nabiz = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (gecir && (_delik?.contains(position) ?? false)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerUpEvent) {
      onDokunus?.call(_delik?.contains(event.localPosition) ?? false);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final delik = _delik?.shift(offset);
    const yaricap = Radius.circular(Yaricap.m);
    final yol = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(offset & size);
    if (delik != null) yol.addRRect(RRect.fromRectAndRadius(delik, yaricap));
    canvas.drawPath(yol, Paint()..color = _renk);
    if (delik == null) return;
    final tasma = 2 + _nabiz * 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          delik.inflate(tasma), Radius.circular(Yaricap.m + tasma)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _halka.withValues(alpha: 1 - _nabiz * 0.8),
    );
  }
}
