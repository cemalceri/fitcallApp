// lib/screens/1_common/widgets/iskelet.dart
//
// Yükleme sırasında gösterilen iskelet (skeleton) placeholder'ları.
//
// Neden var: ekranların çoğu yüklenirken ortada dönen bir halka gösteriyordu.
// Halka "bir şey oluyor" der ama ne geleceğini söylemez; iskelet gelecek
// içeriğin biçimini önden çizdiği için bekleme daha kısa hissettirir ve veri
// gelince sayfa zıplamaz.
//
// Kurallar (tasarım kararı, 2026-08-12):
//  - İskelet, gerçek içerikle aynı yükseklikte olur.
//  - 300 ms'den kısa yüklemelerde hiç gösterilmez ([IskeletGecikmeli]).
//  - Aşağı çekip yenilemede iskelet çıkmaz, mevcut liste durur.
//  - Dönen halka yalnız buton içi işlemlerde ve tam ekran giriş akışında kalır.
//
// Harici paket bağımlılığı yok: parıltı `ShaderMask` ile üretilir.

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

class _KayanGradyan extends GradientTransform {
  final double kayma;
  const _KayanGradyan(this.kayma);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * kayma, 0.0, 0.0);
  }
}

/// Alt ağaçtaki [IskeletKutu]'ların üzerinden kayan bir parıltı geçirir.
///
/// Renkler temadan okunur: koyu temada zemin açılır, parıltı da öyle — sabit
/// gri kullanmak koyu temada beyaz bir şerit bırakıyordu.
class Parilti extends StatefulWidget {
  final Widget child;

  const Parilti({super.key, required this.child});

  @override
  State<Parilti> createState() => _PariltiState();
}

class _PariltiState extends State<Parilti> with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol;

  @override
  void initState() {
    super.initState();
    _kontrol = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Hareketi azalt" açıkken sonsuz döngü çalıştırmayız; iskelet sabit durur.
    final hareketKapali = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (hareketKapali) {
      _kontrol.stop();
    } else if (!_kontrol.isAnimating) {
      _kontrol.repeat();
    }
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final zemin = cs.surfaceContainerHigh;
    final parlak = context.koyuTema
        ? cs.surfaceContainerHighest
        : cs.surfaceContainerLowest;

    return AnimatedBuilder(
      animation: _kontrol,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [zemin, parlak, zemin],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              transform: _KayanGradyan(_kontrol.value * 3 - 1.5),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// [Parilti] içinde kullanılacak opak placeholder kutu.
class IskeletKutu extends StatelessWidget {
  final double? genislik;
  final double yukseklik;
  final double yaricap;

  /// Daire (avatar) placeholder'ı.
  final bool daire;

  const IskeletKutu({
    super.key,
    this.genislik,
    required this.yukseklik,
    this.yaricap = Yaricap.s,
    this.daire = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: genislik,
      height: yukseklik,
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHigh,
        shape: daire ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: daire ? null : BorderRadius.circular(yaricap),
      ),
    );
  }
}

/// İskeleti kısa yüklemelerde göstermez.
///
/// 300 ms'den kısa süren isteklerde iskelet bir kare görünüp kaybolur; bu
/// yanıp sönme beklemekten daha rahatsız edici. [gecikme] dolmadan hiçbir şey
/// çizilmez.
class IskeletGecikmeli extends StatefulWidget {
  final Widget child;
  final Duration gecikme;

  const IskeletGecikmeli({
    super.key,
    required this.child,
    this.gecikme = const Duration(milliseconds: 300),
  });

  @override
  State<IskeletGecikmeli> createState() => _IskeletGecikmeliState();
}

class _IskeletGecikmeliState extends State<IskeletGecikmeli> {
  bool _goster = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.gecikme, () {
      if (mounted) setState(() => _goster = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _goster ? widget.child : const SizedBox.shrink();
  }
}

/* ============================== Liste ============================== */

/// Liste ekranlarının iskeleti — [ListeSatiri] geometrisiyle birebir aynı:
/// 44 px dairesel avatar, iki metin satırı, sağda tek değer.
class IskeletListe extends StatelessWidget {
  final int satirSayisi;

  /// Liste ekranın tamamını kaplıyorsa true; bir sliver/kolon içindeyse false.
  final bool kaydirilabilir;

  const IskeletListe({
    super.key,
    this.satirSayisi = 8,
    this.kaydirilabilir = true,
  });

  @override
  Widget build(BuildContext context) {
    final satirlar = Column(
      children: List.generate(satirSayisi, (i) => _IskeletSatir(ilk: i == 0)),
    );

    return IskeletGecikmeli(
      child: Parilti(
        child: kaydirilabilir
            ? SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: satirlar,
              )
            : satirlar,
      ),
    );
  }
}

class _IskeletSatir extends StatelessWidget {
  final bool ilk;

  const _IskeletSatir({required this.ilk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Bosluk.l,
        vertical: Bosluk.m,
      ),
      decoration: ilk
          ? null
          : BoxDecoration(
              border: Border(top: BorderSide(color: context.cs.outlineVariant)),
            ),
      child: const Row(
        children: [
          IskeletKutu(genislik: 44, yukseklik: 44, daire: true),
          SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IskeletKutu(genislik: 150, yukseklik: 13),
                SizedBox(height: Bosluk.s),
                IskeletKutu(genislik: 96, yukseklik: 10),
              ],
            ),
          ),
          SizedBox(width: Bosluk.m),
          IskeletKutu(genislik: 56, yukseklik: 13),
        ],
      ),
    );
  }
}

/* =============================== Kart =============================== */

/// Kart yığını olan ekranların (ana sayfa, detay, özet) iskeleti:
/// büyük bir kart + rakam şeridi + bölüm başlığı + ikinci kart.
class IskeletKart extends StatelessWidget {
  /// Üstteki büyük kartın yüksekliği.
  final double anaKartYuksekligi;

  /// Rakam şeridindeki kutu sayısı. 0 ise şerit çizilmez.
  final int seritKutusu;

  const IskeletKart({
    super.key,
    this.anaKartYuksekligi = 140,
    this.seritKutusu = 3,
  });

  @override
  Widget build(BuildContext context) {
    return IskeletGecikmeli(
      child: Parilti(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Bosluk.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IskeletKutu(
                genislik: double.infinity,
                yukseklik: anaKartYuksekligi,
                yaricap: Yaricap.xl,
              ),
              if (seritKutusu > 0) ...[
                const SizedBox(height: Bosluk.m),
                Row(
                  children: [
                    for (var i = 0; i < seritKutusu; i++) ...[
                      if (i > 0) const SizedBox(width: Bosluk.s),
                      const Expanded(
                        child: IskeletKutu(yukseklik: 62, yaricap: Yaricap.l),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: Bosluk.xl),
              const IskeletKutu(genislik: 120, yukseklik: 14),
              const SizedBox(height: Bosluk.m),
              const IskeletKutu(
                genislik: double.infinity,
                yukseklik: 76,
                yaricap: Yaricap.l,
              ),
              const SizedBox(height: Bosluk.m),
              const IskeletKutu(
                genislik: double.infinity,
                yukseklik: 76,
                yaricap: Yaricap.l,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== Takvim ============================== */

/// Takvim/program ekranlarının iskeleti: gün şeridi + saat sütunu + bloklar.
class IskeletTakvim extends StatelessWidget {
  const IskeletTakvim({super.key});

  @override
  Widget build(BuildContext context) {
    return IskeletGecikmeli(
      child: Parilti(
        child: Padding(
          padding: const EdgeInsets.all(Bosluk.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: Bosluk.xs),
                    const Expanded(
                      child: IskeletKutu(yukseklik: 54, yaricap: Yaricap.m),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Bosluk.l),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IskeletKutu(genislik: 34, yukseklik: 210),
                  const SizedBox(width: Bosluk.m),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: Bosluk.m),
                          IskeletKutu(
                            genislik: i.isEven ? double.infinity : null,
                            yukseklik: 42,
                            yaricap: Yaricap.m,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================= Dashboard ============================= */

/// Yönetici dashboard'u: başlık + dönem sekmeleri + kart ızgarası + grafik.
class IskeletDashboard extends StatelessWidget {
  const IskeletDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return IskeletGecikmeli(
      child: Parilti(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Bosluk.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IskeletKutu(genislik: 180, yukseklik: 22),
              const SizedBox(height: Bosluk.xl),
              const IskeletKutu(
                genislik: double.infinity,
                yukseklik: 42,
                yaricap: Yaricap.m,
              ),
              const SizedBox(height: Bosluk.xl),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Bosluk.m,
                crossAxisSpacing: Bosluk.m,
                childAspectRatio: 1.1,
                children: List.generate(
                  6,
                  (_) => const IskeletKutu(
                    genislik: double.infinity,
                    yukseklik: 120,
                    yaricap: Yaricap.l,
                  ),
                ),
              ),
              const SizedBox(height: Bosluk.l),
              const IskeletKutu(
                genislik: double.infinity,
                yukseklik: 200,
                yaricap: Yaricap.l,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
