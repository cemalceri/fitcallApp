// lib/screens/1_common/widgets/liste_satiri.dart
//
// Liste ekranlarının ortak satır kalıbı.
//
// Neden var: sekiz liste ekranı satırlarını ayrı ayrı "kart" olarak çiziyordu —
// kenarlık + gölge + 10 px aralık. Bir ekrana 6 satır sığıyordu ve her ekran
// kendi ölçüsünü tutturuyordu. Yaygın uygulamalarda (WhatsApp, Instagram DM,
// sipariş listeleri) liste satırı karta konmaz: dairesel avatar, iki metin
// satırı, sağda tek değer ve satırlar arası saç teli ayraç. Aynı alanda 10
// satır görünür ve göz tek dikey hat boyunca tarar.
//
// Kart yalnız gerçek bir "nesne" için kalır (istatistik başlığı, özet kartı).

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Satır öğesinin anlam tonu — avatar zeminini ve değer rengini belirler.
enum ListeTonu { notr, vurgu, basari, uyari, hata, bilgi }

extension ListeTonuRenkleri on ListeTonu {
  /// Ön plan (metin/ikon) rengi.
  Color on(BuildContext context) {
    final r = context.renkler;
    return switch (this) {
      ListeTonu.notr => context.cs.onSurfaceVariant,
      ListeTonu.vurgu => context.cs.primary,
      ListeTonu.basari => r.basari,
      ListeTonu.uyari => r.uyari,
      ListeTonu.hata => r.hata,
      ListeTonu.bilgi => r.bilgi,
    };
  }

  /// Zemin rengi.
  Color zemin(BuildContext context) {
    final r = context.renkler;
    return switch (this) {
      ListeTonu.notr => r.notrZemin,
      ListeTonu.vurgu => r.vurguZemin,
      ListeTonu.basari => r.basariZemin,
      ListeTonu.uyari => r.uyariZemin,
      ListeTonu.hata => r.hataZemin,
      ListeTonu.bilgi => r.bilgiZemin,
    };
  }
}

/// Liste satırının dairesel baş harf avatarı.
///
/// Kare değil daire: yaygın liste kalıbında kişi her zaman dairede durur.
/// Seviye/kategori rengi avatara değil metne taşınır — beş ayrı avatar rengi
/// listeyi alacalı gösteriyordu; burada yalnız "dikkat gerektiren" satır
/// (ör. borçlu) tondan ayrılır.
class ListeAvatari extends StatelessWidget {
  final String basHarfler;
  final ListeTonu ton;

  /// Avatar yerine ikon gösterilecekse.
  final IconData? ikon;
  final double cap;

  const ListeAvatari({
    super.key,
    this.basHarfler = '',
    this.ton = ListeTonu.bilgi,
    this.ikon,
    this.cap = 44,
  });

  /// Ad soyaddan baş harfleri çıkarır ("Elif Yıldırım" → "EY").
  static String harfler(String adSoyad) {
    final parcalar =
        adSoyad.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parcalar.isEmpty) return '';
    if (parcalar.length == 1) {
      return parcalar.first.characters.first.toUpperCase();
    }
    return (parcalar.first.characters.first + parcalar.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cap,
      height: cap,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ton.zemin(context),
        shape: BoxShape.circle,
      ),
      child: ikon != null
          ? Icon(ikon, size: cap * 0.46, color: ton.on(context))
          : Text(
              basHarfler,
              maxLines: 1,
              style: TextStyle(
                fontSize: cap * 0.32,
                fontWeight: FontWeight.w700,
                color: ton.on(context),
              ),
            ),
    );
  }
}

/// Satırı sola kaydırınca çıkan eylem.
class ListeEylemi {
  final String etiket;
  final IconData ikon;
  final ListeTonu ton;
  final VoidCallback onSec;

  const ListeEylemi({
    required this.etiket,
    required this.ikon,
    required this.onSec,
    this.ton = ListeTonu.notr,
  });
}

/// Liste ekranlarının ortak satırı.
///
/// Kart değil satır: zemin şeffaf, ayraç [ListeAyraci] ile üstten çizilir.
class ListeSatiri extends StatelessWidget {
  /// Sol taraftaki görsel — genelde [ListeAvatari].
  final Widget? onGorsel;

  final String baslik;

  /// Başlığın altındaki ikincil satır. Telefon/kayıt no gibi aramada zaten
  /// eşleşen alanlar yerine kullanıcının hatırladığı bilgi konur.
  final String? altBaslik;

  /// Başlığın yanındaki küçük rozet (ör. "Pasif").
  final Widget? rozet;

  /// Sağdaki tek değer (tutar, saat, sayı).
  final String? deger;
  final Color? degerRengi;

  /// Değerin altındaki küçük ikinci satır.
  final String? altDeger;

  /// Değer yerine tamamen özel bir sağ blok.
  final Widget? sonEk;

  /// Okunmamış işareti (bildirim listesi).
  final bool okunmadi;

  /// Sağda ">" oku. Detaya giden satırlarda açılır.
  final bool okGoster;

  final VoidCallback? onTap;

  /// Sola kaydırınca çıkan eylemler. Uzun basınca aynı eylemler alt sayfada
  /// listelenir — kaydırma jesti ekran okuyucuyla kullanılamıyor.
  final List<ListeEylemi> eylemler;

  const ListeSatiri({
    super.key,
    this.onGorsel,
    required this.baslik,
    this.altBaslik,
    this.rozet,
    this.deger,
    this.degerRengi,
    this.altDeger,
    this.sonEk,
    this.okunmadi = false,
    this.okGoster = false,
    this.onTap,
    this.eylemler = const [],
  });

  @override
  Widget build(BuildContext context) {
    final satir = _icerik(context);
    if (eylemler.isEmpty) return satir;
    return _KaydirilabilirSatir(eylemler: eylemler, child: satir);
  }

  Widget _icerik(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;

    return Semantics(
      button: onTap != null,
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          onLongPress: eylemler.isEmpty
              ? null
              : () => _eylemleriGoster(context, eylemler, baslik),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.l,
              vertical: Bosluk.m,
            ),
            child: Row(
              children: [
                if (onGorsel != null) ...[
                  onGorsel!,
                  const SizedBox(width: Bosluk.m),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              baslik,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: metin.titleSmall?.copyWith(
                                fontWeight:
                                    okunmadi ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (rozet != null) ...[
                            const SizedBox(width: Bosluk.s),
                            rozet!,
                          ],
                        ],
                      ),
                      if (altBaslik != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          altBaslik!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: metin.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (sonEk != null) ...[
                  const SizedBox(width: Bosluk.s),
                  sonEk!,
                ] else if (deger != null) ...[
                  const SizedBox(width: Bosluk.s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deger!,
                        maxLines: 1,
                        style: metin.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: degerRengi ?? cs.onSurface,
                        ),
                      ),
                      if (altDeger != null)
                        Text(
                          altDeger!,
                          maxLines: 1,
                          style: metin.labelSmall,
                        ),
                    ],
                  ),
                ],
                if (okunmadi) ...[
                  const SizedBox(width: Bosluk.s),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (okGoster)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satırlar arası saç teli ayraç. İlk satırın üstüne çizilmez.
class ListeAyraci extends StatelessWidget {
  /// Avatarın hizasından başlasın diye sol boşluk.
  final double solBosluk;

  const ListeAyraci({super.key, this.solBosluk = 70});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: solBosluk),
      child: Divider(height: 1, thickness: 1, color: context.cs.outlineVariant),
    );
  }
}

/// Liste içi grup başlığı — "Borçlu · 23", "Bugün", "Ağustos 2026".
///
/// Sliver içinde [ListeGrupBasligiDelegate] ile yapışkan kullanılır; düz
/// `ListView` içinde doğrudan bu widget konur.
class ListeGrupBasligi extends StatelessWidget {
  final String baslik;

  /// Başlığın sağındaki sayaç. null ise gösterilmez.
  final int? sayi;

  const ListeGrupBasligi({super.key, required this.baslik, this.sayi});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: Bosluk.l,
        vertical: Bosluk.s,
      ),
      child: Text(
        sayi == null ? baslik : '$baslik · $sayi',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.metin.labelSmall?.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// [ListeGrupBasligi]'nı `SliverPersistentHeader` içinde yapışkan yapar.
class ListeGrupBasligiDelegate extends SliverPersistentHeaderDelegate {
  final String baslik;
  final int? sayi;

  /// Yazı ölçeği 1.3'e çıkınca başlık yüksekliği de artmalı; sabit değer
  /// taşmaya yol açıyordu.
  final double yukseklik;

  const ListeGrupBasligiDelegate({
    required this.baslik,
    this.sayi,
    required this.yukseklik,
  });

  @override
  double get minExtent => yukseklik;

  @override
  double get maxExtent => yukseklik;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ListeGrupBasligi(baslik: baslik, sayi: sayi);
  }

  @override
  bool shouldRebuild(ListeGrupBasligiDelegate eski) =>
      eski.baslik != baslik || eski.sayi != sayi || eski.yukseklik != yukseklik;
}

/// Grup başlığının verilen yazı ölçeğindeki yüksekliği.
///
/// `SliverPersistentHeader` sabit yükseklik ister; metin ölçeğiyle büyüyen
/// içeriğe tam oturan bir değer yuvarlama farkında taşar, bu yüzden 2 px pay
/// bırakılır.
double listeGrupBasligiYuksekligi(BuildContext context) {
  final olcek = MediaQuery.textScalerOf(context).scale(11);
  return olcek * 1.2 + Bosluk.s * 2 + 2;
}

/* ======================= Kaydırarak eylem ======================= */

/// Satırı sola kaydırınca arkasındaki eylemleri açar.
///
/// `Dismissible` kullanılmadı: o, öğeyi listeden atmak için; burada satır
/// yerinde kalıp eylem şeridini açıyor. Harici paket eklemek yerine tek
/// sürükleme denetleyicisiyle çözüldü.
class _KaydirilabilirSatir extends StatefulWidget {
  final List<ListeEylemi> eylemler;
  final Widget child;

  const _KaydirilabilirSatir({required this.eylemler, required this.child});

  @override
  State<_KaydirilabilirSatir> createState() => _KaydirilabilirSatirState();
}

class _KaydirilabilirSatirState extends State<_KaydirilabilirSatir>
    with SingleTickerProviderStateMixin {
  static const double _eylemGenisligi = 76;

  late final AnimationController _kontrol = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  double get _acikGenislik => widget.eylemler.length * _eylemGenisligi;

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  void _surukle(DragUpdateDetails d) {
    final yeni = _kontrol.value - d.primaryDelta! / _acikGenislik;
    _kontrol.value = yeni.clamp(0.0, 1.0);
  }

  void _birak(DragEndDetails d) {
    final hiz = d.primaryVelocity ?? 0;
    final acilsin = hiz < -250 || (hiz <= 250 && _kontrol.value > 0.5);
    if (acilsin) {
      HapticFeedback.selectionClick();
      _kontrol.forward();
    } else {
      _kontrol.reverse();
    }
  }

  void _kapat() => _kontrol.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _surukle,
      onHorizontalDragEnd: _birak,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final e in widget.eylemler)
                  _EylemDugmesi(
                    eylem: e,
                    genislik: _eylemGenisligi,
                    onSec: () {
                      _kapat();
                      e.onSec();
                    },
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _kontrol,
            child: widget.child,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_kontrol.value * _acikGenislik, 0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _EylemDugmesi extends StatelessWidget {
  final ListeEylemi eylem;
  final double genislik;
  final VoidCallback onSec;

  const _EylemDugmesi({
    required this.eylem,
    required this.genislik,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final zemin = eylem.ton.zemin(context);
    final on = eylem.ton.on(context);

    return SizedBox(
      width: genislik,
      child: Material(
        color: zemin,
        child: InkWell(
          onTap: onSec,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(eylem.ikon, size: 20, color: on),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Bosluk.xs),
                child: Text(
                  eylem.etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.metin.labelSmall?.copyWith(color: on),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uzun basınca açılan eylem listesi — kaydırma jestinin erişilebilir karşılığı.
void _eylemleriGoster(
  BuildContext context,
  List<ListeEylemi> eylemler,
  String baslik,
) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, 0, Bosluk.l, Bosluk.s),
            child: Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sheetContext.metin.titleMedium,
            ),
          ),
          for (final e in eylemler)
            ListTile(
              leading: Icon(e.ikon, color: e.ton.on(sheetContext)),
              title: Text(e.etiket),
              onTap: () {
                Navigator.pop(sheetContext);
                e.onSec();
              },
            ),
          const SizedBox(height: Bosluk.s),
        ],
      ),
    ),
  );
}
