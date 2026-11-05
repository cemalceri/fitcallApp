// lib/screens/1_common/ogrenme/rehber_balonu.dart
//
// Rehber balonunun renkleri ve yerleşimi. Balon parlayan yerin hemen altında
// (yer yoksa üstünde) durur, okuyla ona bağlanır. Yerleşim saf hesaptır:
// katman (ogrenme_katmani.dart) balonu ölçer, yerini ve gerekirse kırpılmış
// deliği buradan alır; test/ogrenme/balon_yeri_test.dart doğrudan sınar.

import 'dart:math' as math;

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Karartma, halka ve balon renkleri. Yeni renk yok, şemadan türer; her
/// palette test/tema_kontrast_test.dart ölçer.
@immutable
class RehberRenkleri {
  /// Karartmanın opaklığı. Açık modda parlayan yüzey karartılmış yüzeyden
  /// 9.3:1 ayrışır. Koyu modda yüzeyler zaten koyu; ayrışmayı içerik ve halka
  /// yapar, dışarıdaki yazı seçilir ama okunmaz (~1.8:1).
  static const double karartmaAcik = 0.72;
  static const double karartmaKoyu = 0.76;

  final Color karartma;

  /// Parlayan yerin çevresindeki çizgi: karartma üstünde her temada beyaz
  /// (başlık yazısı rengi). Takım rengi açık modda karartılmış zeminle
  /// neredeyse aynı parlaklıkta.
  final Color halka;
  final Color balon;
  final Color onBalon;

  /// Koyu modda takım kabı karartmadan ayrışmıyor (1.5–2.2:1); balonun ve
  /// okun kenarını ana renk çizer. Açık modda yok.
  final Color? balonKenari;
  final Color golge;

  const RehberRenkleri({
    required this.karartma,
    required this.halka,
    required this.balon,
    required this.onBalon,
    required this.balonKenari,
    required this.golge,
  });

  factory RehberRenkleri.of(ColorScheme cs, TemaGecisleri g) {
    final koyu = cs.brightness == Brightness.dark;
    return RehberRenkleri(
      karartma: cs.scrim.withValues(alpha: koyu ? karartmaKoyu : karartmaAcik),
      halka: g.onBaslik,
      balon: cs.primaryContainer,
      onBalon: cs.onPrimaryContainer,
      balonKenari: koyu ? cs.primary : null,
      golge: cs.shadow,
    );
  }

  static RehberRenkleri baglamdan(BuildContext context) =>
      RehberRenkleri.of(context.cs, context.gecis);
}

/// Balon ve delik ölçüleri (mantıksal piksel).
abstract final class BalonOlcu {
  /// Delik, hedefin çevresine bu kadar taşar.
  static const double pay = 6;

  /// Delik en az bu kadar (küçük ikon ortalanarak büyür).
  static const double enKucukDelik = 44;

  /// Halka delikten bu kadar dışarıda, bu kalınlıkta.
  static const double halkaAraligi = 4;
  static const double halkaKalinligi = 2.5;

  /// Halka ile okun ucu arası; ok boyu ve genişliği.
  static const double okAraligi = 4;
  static const double okBoyu = 9;
  static const double okGenisligi = 18;

  /// Delik, güvenli alanın en az bu kadar içinde: halka hep ekranda kalır.
  static const double delikKenari = 8;

  /// Balona yer açmak için kırpılan delikten en az bu kadarı kalır.
  static const double enAzDelik = 72;

  /// Balon ile ekranın yanları; balon ile güvenli alanın üstü/altı.
  static const double yan = Bosluk.l;
  static const double dikey = Bosluk.s;
  static const double enGenis = 360;
  static const double kose = Yaricap.l;

  /// Delik kenarından balon gövdesine.
  static const double dis = halkaAraligi + halkaKalinligi + okAraligi + okBoyu;
}

/// Okun yönü: balon hedefin altındaysa ok yukarı bakar.
enum OkYonu { yukari, asagi, yok }

@immutable
class BalonYeri {
  /// Balon gövdesinin sol üstü.
  final Offset sol;
  final OkYonu ok;

  /// Okun ucunun yatay konumu.
  final double okX;

  /// Çizilecek delik: balona yer açmak için kırpılmış olabilir; null ise yok.
  final Rect? delik;

  const BalonYeri({
    required this.sol,
    required this.ok,
    required this.okX,
    required this.delik,
  });
}

/// [guvenli] alana sığan balon genişliği.
double balonGenisligi(Rect guvenli) =>
    math.max(0, math.min(guvenli.width - 2 * BalonOlcu.yan, BalonOlcu.enGenis));

/// Hedefin görünen alanından çizilecek delik: pay kadar büyür, en az
/// [BalonOlcu.enKucukDelik], güvenli alanın [BalonOlcu.delikKenari] içine
/// kırpılır (ekran genişliğindeki listede halka ekran dışına taşmasın).
Rect? delikHesapla(Rect? hedef, Rect guvenli) {
  if (hedef == null) return null;
  var d = hedef.inflate(BalonOlcu.pay);
  if (d.width < BalonOlcu.enKucukDelik) {
    d = Rect.fromCenter(
        center: d.center, width: BalonOlcu.enKucukDelik, height: d.height);
  }
  if (d.height < BalonOlcu.enKucukDelik) {
    d = Rect.fromCenter(
        center: d.center, width: d.width, height: BalonOlcu.enKucukDelik);
  }
  final sinir = guvenli.deflate(BalonOlcu.delikKenari);
  if (sinir.width < 1 || sinir.height < 1) return d;
  final k = d.intersect(sinir);
  return k.width < 1 || k.height < 1 ? null : k;
}

/// Delik küçük ve kareye yakınsa (ikon butonu) daire, değilse yuvarlak köşe.
RRect delikSekli(Rect d) {
  final daire = d.longestSide <= 64 && (d.width - d.height).abs() <= 12;
  return RRect.fromRectAndRadius(
      d, Radius.circular(daire ? d.shortestSide / 2 : Yaricap.m));
}

/// Balonun yeri. Sıra: hedefin altı (okuma sırası: önce hedef, sonra
/// açıklama), olmazsa üstü. İkisine de sığmazsa (hedef ekranın çoğunu
/// kaplıyor) balon altta durur, deliğin altı balona yer açacak kadar kırpılır;
/// hedefin başı (liste başı) görünür kalır. Kalan delik çok kısaysa balon,
/// oksuz, güvenli alanın hedefe uzak kenarına yaslanır.
///
/// [delik] yoksa [konum]a (bitişte son vurgulanan yer) oksuz bağlanır; ikisi
/// de yoksa güvenli alanın altına yaslanır.
BalonYeri balonYeri({
  required Rect? delik,
  Rect? konum,
  required Rect guvenli,
  required Size balon,
}) {
  final w = balon.width;
  final h = balon.height;
  final ust = guvenli.top + BalonOlcu.dikey;
  final alt = guvenli.bottom - BalonOlcu.dikey;

  double solX(double merkez) {
    final enSol = guvenli.left + BalonOlcu.yan;
    final enSag = math.max(enSol, guvenli.right - BalonOlcu.yan - w);
    return (merkez - w / 2).clamp(enSol, enSag).toDouble();
  }

  final bag = delik ?? delikHesapla(konum, guvenli);
  if (bag == null) {
    return BalonYeri(
      sol: Offset(solX(guvenli.center.dx), alt - h),
      ok: OkYonu.yok,
      okX: guvenli.center.dx,
      delik: null,
    );
  }

  final altBos = alt - (bag.bottom + BalonOlcu.dis);
  final ustBos = (bag.top - BalonOlcu.dis) - ust;
  var cizilen = delik;
  bool? altta;
  if (altBos >= h) {
    altta = true;
  } else if (ustBos >= h) {
    altta = false;
  } else if (delik != null) {
    final eksik = h - altBos;
    if (delik.height - eksik >= BalonOlcu.enAzDelik) {
      cizilen = Rect.fromLTRB(
          delik.left, delik.top, delik.right, delik.bottom - eksik);
      altta = true;
    }
  }

  if (altta == null) {
    final ustte = bag.center.dy > guvenli.center.dy;
    return BalonYeri(
      sol: Offset(solX(bag.center.dx), ustte ? ust : alt - h),
      ok: OkYonu.yok,
      okX: bag.center.dx,
      delik: delik,
    );
  }

  final yer = cizilen ?? bag;
  final x = solX(yer.center.dx);
  final y = altta ? yer.bottom + BalonOlcu.dis : yer.top - BalonOlcu.dis - h;
  const okPayi = BalonOlcu.kose + BalonOlcu.okGenisligi / 2;
  final okX = yer.center.dx
      .clamp(x + okPayi, math.max(x + okPayi, x + w - okPayi))
      .toDouble();
  return BalonYeri(
    sol: Offset(x, y),
    ok: cizilen == null
        ? OkYonu.yok
        : altta
            ? OkYonu.yukari
            : OkYonu.asagi,
    okX: okX,
    delik: cizilen,
  );
}

/// Balon gövdesi ve oku tek yol: kenar çizgisi okun iki yanını da çizer,
/// birleşim yerinde çizgi kalmaz.
Path balonYolu(Rect govde, OkYonu ok, double okX) {
  final yol = Path()
    ..addRRect(RRect.fromRectAndRadius(
        govde, const Radius.circular(BalonOlcu.kose)));
  if (ok == OkYonu.yok) return yol;
  // s: okun ucunun gövdeye göre yönü.
  final s = ok == OkYonu.yukari ? -1.0 : 1.0;
  final y = ok == OkYonu.yukari ? govde.top : govde.bottom;
  final uc = y + s * BalonOlcu.okBoyu;
  const yari = BalonOlcu.okGenisligi / 2;
  final okYolu = Path()
    ..moveTo(okX - yari, y - s)
    ..lineTo(okX - yari, y)
    ..lineTo(okX - 1.6, uc - s * 1.2)
    ..quadraticBezierTo(okX, uc, okX + 1.6, uc - s * 1.2)
    ..lineTo(okX + yari, y)
    ..lineTo(okX + yari, y - s)
    ..close();
  return Path.combine(PathOperation.union, yol, okYolu);
}
