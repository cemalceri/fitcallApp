// lib/screens/1_common/acilis_popup/widgets/konfeti_patlamasi.dart

import 'dart:math' as math;

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Tek seferlik konfeti patlaması (~2,4 sn, döngü yok).
///
/// Paket yerine küçük bir CustomPainter: tek kullanım için bağımlılık eklemeye
/// değmez. Parçacık konumu her karede kapalı formülle hesaplanır (hava
/// sürtünmeli atış), durum tutulmaz. Cihazda "hareketi azalt" açıksa hiç
/// çizilmez. Dokunmaları engellemez.
class KonfetiPatlamasi extends StatefulWidget {
  /// Patlama noktasının ekran yüksekliğine oranı (0 = üst, 1 = alt).
  final double kaynakYuksekligi;
  final int parcaSayisi;
  final Duration sure;

  const KonfetiPatlamasi({
    super.key,
    this.kaynakYuksekligi = 0.35,
    this.parcaSayisi = 110,
    this.sure = const Duration(milliseconds: 2400),
  });

  @override
  State<KonfetiPatlamasi> createState() => _KonfetiPatlamasiState();
}

class _KonfetiPatlamasiState extends State<KonfetiPatlamasi>
    with SingleTickerProviderStateMixin {
  // initState'te kurulur: tembel (late) olsaydı "hareketi azalt" açıkken ilk
  // kez dispose'da oluşur, ölü context'ten ticker isterdi.
  late final AnimationController _kontrol;
  late final List<_Parca> _parcalar;
  bool _basladi = false;

  // Kobalt zemin üzerinde okunan marka tonları; kobaltın kendisi kaybolurdu.
  static const List<Color> _renkler = [
    Marka.turuncu,
    Marka.turuncuAcik,
    Colors.white,
    Marka.maviAcik,
  ];

  List<_Parca> _parcalariUret() {
    final r = math.Random();
    return List.generate(widget.parcaSayisi, (i) {
      // Yukarı açılan yelpaze: yataydan 15° ile 165° arası.
      final aci = -math.pi * (0.08 + r.nextDouble() * 0.84);
      final hiz = 0.9 + r.nextDouble() * 1.5; // ekran genişliği / sn
      return _Parca(
        vx: math.cos(aci) * hiz,
        vy: math.sin(aci) * hiz - 0.3,
        donus: r.nextDouble() * math.pi,
        donusHizi: (r.nextDouble() - 0.5) * 12,
        salinim: r.nextDouble() * math.pi * 2,
        en: 5 + r.nextDouble() * 5,
        boy: 3 + r.nextDouble() * 4,
        yuvarlak: r.nextDouble() < 0.25,
        renk: _renkler[i % _renkler.length],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _kontrol = AnimationController(vsync: this, duration: widget.sure);
    _parcalar = _parcalariUret();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_basladi && !MediaQuery.of(context).disableAnimations) {
      _basladi = true;
      _kontrol.forward();
    }
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_basladi) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _KonfetiBoyaci(
            animasyon: _kontrol,
            parcalar: _parcalar,
            kaynakYuksekligi: widget.kaynakYuksekligi,
            sureSn: widget.sure.inMilliseconds / 1000,
          ),
        ),
      ),
    );
  }
}

class _Parca {
  final double vx, vy; // başlangıç hızı, ekran genişliği / sn
  final double donus, donusHizi, salinim;
  final double en, boy;
  final bool yuvarlak;
  final Color renk;

  const _Parca({
    required this.vx,
    required this.vy,
    required this.donus,
    required this.donusHizi,
    required this.salinim,
    required this.en,
    required this.boy,
    required this.yuvarlak,
    required this.renk,
  });
}

class _KonfetiBoyaci extends CustomPainter {
  final Animation<double> animasyon;
  final List<_Parca> parcalar;
  final double kaynakYuksekligi;
  final double sureSn;

  _KonfetiBoyaci({
    required this.animasyon,
    required this.parcalar,
    required this.kaynakYuksekligi,
    required this.sureSn,
  }) : super(repaint: animasyon);

  static const double _surtunme = 1.8; // 1/sn
  static const double _yercekimi = 1.6; // ekran genişliği / sn²

  @override
  void paint(Canvas canvas, Size size) {
    final ilerleme = animasyon.value;
    if (ilerleme <= 0 || ilerleme >= 1) return;

    final t = ilerleme * sureSn;
    final birim = size.width;
    final ox = size.width / 2;
    final oy = size.height * kaynakYuksekligi;

    // Hava sürtünmeli atış: v' = g - k·v  →  kapalı form.
    final azalma = (1 - math.exp(-_surtunme * t)) / _surtunme;
    final sonHiz = _yercekimi / _surtunme;

    // Son %25'te sönerek kaybolur.
    final opaklik = ilerleme < 0.75 ? 1.0 : (1 - ilerleme) / 0.25;
    final boya = Paint();

    for (final p in parcalar) {
      final x = ox +
          p.vx * birim * azalma +
          math.sin(t * 6 + p.salinim) * 6 * ilerleme;
      final y = oy + (sonHiz * t + (p.vy - sonHiz) * azalma) * birim;
      if (y > size.height + 20) continue;

      boya.color = p.renk.withValues(alpha: opaklik);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.donus + p.donusHizi * t);
      if (p.yuvarlak) {
        canvas.drawCircle(Offset.zero, p.boy / 2 + 1, boya);
      } else {
        // Dönerken incelip kalınlaşan şerit — kâğıt hissi.
        final kalinlik = p.boy * (0.35 + 0.65 * math.cos(t * 8 + p.salinim).abs());
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.en, height: kalinlik),
          boya,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _KonfetiBoyaci eski) =>
      eski.parcalar != parcalar || eski.kaynakYuksekligi != kaynakYuksekligi;
}
