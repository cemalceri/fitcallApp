// lib/screens/7_yonetici/widgets/pano_parcalari.dart
//
// Yönetici ekranlarının (Ana Sayfa, Raporlar, Ekip) ortak yapı taşları:
// kart çerçevesi, trend rozeti, durum hapı, halka ve çizgi gösterge.
// Renkler temadan; durum renkleri ListeTonu üzerinden (kontrast testli).

import 'dart:math' as math;

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _tamSayi = NumberFormat('#,##0', 'tr_TR');

/// Kuruşsuz tutar: `12.400`. Birim ayrı yazılır ([TutarYazisi]).
String tutarYaz(num tutar) => _tamSayi.format(tutar.round());

/// `12.400 TL`
String tlYaz(num tutar) => '${tutarYaz(tutar)} TL';

/// `14:20`
String saatYaz(DateTime zaman) => DateFormat('HH:mm').format(zaman);

/// Bugünse `14:20`, değilse `12 Kas 14:20`.
String sonGirisYaz(DateTime zaman, {DateTime? bugun}) {
  final b = bugun ?? simdiKulup();
  final ayniGun =
      zaman.year == b.year && zaman.month == b.month && zaman.day == b.day;
  return ayniGun
      ? saatYaz(zaman)
      : DateFormat('d MMM HH:mm', 'tr_TR').format(zaman);
}

/// Sunucudan gelen ton adını ([DikkatMaddesi.ton] vb.) tema tonuna çevirir.
ListeTonu tonCoz(String? ton) => switch (ton) {
      'uyari' => ListeTonu.uyari,
      'olumsuz' => ListeTonu.hata,
      'olumlu' => ListeTonu.basari,
      'bilgi' => ListeTonu.vurgu,
      _ => ListeTonu.notr,
    };

/// Yönetici ekranlarının kartı: düz yüzey, yumuşak köşe, ince çizgi.
class PanoKarti extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const PanoKarti({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Bosluk.l),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final kenar = BorderRadius.circular(Yaricap.xl);
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: kenar,
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Kart içi küçük etiket ("Bugünkü ders", "Doluluk").
class PanoEtiketi extends StatelessWidget {
  final String metin;
  const PanoEtiketi(this.metin, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        metin,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.cs.onSurfaceVariant,
        ),
      );
}

/// Kart başlığı: solda ad, sağda isteğe bağlı ek (hap, tarih).
class PanoBasligi extends StatelessWidget {
  final String baslik;
  final Widget? sag;
  const PanoBasligi(this.baslik, {super.key, this.sag});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.cs.onSurface,
              ),
            ),
          ),
          if (sag != null) ...[const SizedBox(width: Bosluk.s), sag!],
        ],
      );
}

/// Büyük rakam + küçük birim (`86.500 TL`, `11 / 18`). Dar kartta küçülür,
/// kırılmaz.
class TutarYazisi extends StatelessWidget {
  final String deger;
  final String? birim;
  final double boyut;
  final Color? renk;

  const TutarYazisi(
    this.deger, {
    super.key,
    this.birim,
    this.boyut = 22,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final r = renk ?? context.cs.onSurface;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: deger,
          children: [
            if (birim != null)
              TextSpan(
                text: ' $birim',
                style: TextStyle(
                  fontSize: boyut * 0.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        maxLines: 1,
        style: TextStyle(
          fontSize: boyut,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.15,
          color: r,
        ),
      ),
    );
  }
}

/// Renkli durum hapı ("2 iptal", "4 konu").
class DurumHapi extends StatelessWidget {
  final String metin;
  final ListeTonu ton;
  final IconData? ikon;

  const DurumHapi(this.metin, {super.key, this.ton = ListeTonu.notr, this.ikon});

  @override
  Widget build(BuildContext context) {
    final on = ton.on(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: ton.zemin(context),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 12, color: on),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              metin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: on,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Önceki döneme göre değişim: `▲ %12`. [artisKotu] iptal ve alacak gibi
/// artması istenmeyen göstergelerde rengi ters çevirir. Yüzde yoksa çizilmez.
class TrendRozeti extends StatelessWidget {
  final double? yuzde;
  final bool artisKotu;

  /// Yüzde yerine puan farkı (doluluk): `▲ 3 puan`.
  final bool puan;

  const TrendRozeti(
    this.yuzde, {
    super.key,
    this.artisKotu = false,
    this.puan = false,
  });

  @override
  Widget build(BuildContext context) {
    final y = yuzde;
    if (y == null) return const SizedBox.shrink();
    final artti = y >= 0;
    final sifir = y.abs() < 0.05;
    final ton = sifir
        ? ListeTonu.notr
        : (artti != artisKotu ? ListeTonu.basari : ListeTonu.hata);
    final sayi = y.abs() >= 10 || puan
        ? y.abs().toStringAsFixed(0)
        : y.abs().toStringAsFixed(1).replaceAll('.', ',');
    return DurumHapi(
      puan ? '$sayi puan' : '%$sayi',
      ton: ton,
      ikon: sifir
          ? Icons.remove_rounded
          : (artti ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
    );
  }
}

/// İkonlu renkli karo (dikkat satırı, işlem akışı).
class TonKarosu extends StatelessWidget {
  final IconData ikon;
  final ListeTonu ton;
  final double boyut;

  const TonKarosu({
    super.key,
    required this.ikon,
    this.ton = ListeTonu.vurgu,
    this.boyut = 38,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(
          color: ton.zemin(context),
          borderRadius: BorderRadius.circular(Yaricap.m),
        ),
        child: Icon(ikon, size: boyut * 0.53, color: ton.on(context)),
      );
}

/// Yatay doluluk çizgisi (0–1).
class IlerlemeCizgisi extends StatelessWidget {
  final double oran;
  final Color? renk;
  final double kalinlik;

  const IlerlemeCizgisi(this.oran, {super.key, this.renk, this.kalinlik = 8});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: oran.isNaN ? 0 : oran.clamp(0.0, 1.0),
        minHeight: kalinlik,
        backgroundColor: cs.surfaceContainerHigh,
        valueColor: AlwaysStoppedAnimation(renk ?? cs.primary),
      ),
    );
  }
}

/// Halka gösterge (0–1); ortasına isteğe bağlı yazı.
class HalkaGosterge extends StatelessWidget {
  final double oran;
  final double boyut;
  final double kalinlik;
  final Color? renk;
  final Color? zemin;
  final Widget? child;

  const HalkaGosterge(
    this.oran, {
    super.key,
    this.boyut = 54,
    this.kalinlik = 6,
    this.renk,
    this.zemin,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: boyut,
      height: boyut,
      child: CustomPaint(
        painter: _HalkaBoyaci(
          oran: oran.isNaN ? 0 : oran.clamp(0.0, 1.0),
          kalinlik: kalinlik,
          renk: renk ?? cs.primary,
          zemin: zemin ?? cs.surfaceContainerHigh,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _HalkaBoyaci extends CustomPainter {
  final double oran;
  final double kalinlik;
  final Color renk;
  final Color zemin;

  _HalkaBoyaci({
    required this.oran,
    required this.kalinlik,
    required this.renk,
    required this.zemin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = size.center(Offset.zero);
    final yaricap = (math.min(size.width, size.height) - kalinlik) / 2;
    final kalem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kalinlik
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(merkez, yaricap, kalem..color = zemin);
    if (oran > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: merkez, radius: yaricap),
        -math.pi / 2,
        2 * math.pi * oran,
        false,
        kalem..color = renk,
      );
    }
  }

  @override
  bool shouldRepaint(_HalkaBoyaci eski) =>
      eski.oran != oran || eski.renk != renk || eski.zemin != zemin;
}
