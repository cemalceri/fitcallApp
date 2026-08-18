// lib/screens/1_common/takvim/takvim_ajanda.dart
//
// Ajanda görünümü — "sıradaki derslerim ne zaman" sorusunun cevabı.
//
// Izgara (timeline) bir günü saat saat gösterir; boş saatler ekranın çoğunu
// kaplar. Üye çoğunlukla haftasına liste olarak bakmak ister: gün başlıkları
// yapışkan, yalnız dolu saatler var. Antrenör günü ızgarada görmek istediği
// için varsayılan görünüm rol bazında farklı seçilir.
//
// Üstteki hafta şeridiyle ilişki: liste haftanın tamamını gösterir ama şeritten
// bir güne basmak karşılıksız kalmaz — liste o günün başlığına kayar (Google /
// Apple takviminin ajanda kalıbı). Seçili gün başlığı ayrıca vurgulanır, o günde
// ders yoksa "ders yok" satırı gösterilir; böylece her dokunuş görünür bir
// karşılık üretir.
//
// Kaydırma hedefi ölçüyle değil hesapla bulunuyor: sliver'lar görüş alanı
// dışında layout edilmediğinden `ensureVisible` çalışmaz. Bu yüzden satır ve
// başlık yükseklikleri sabit (yazı ölçeğiyle birlikte büyür) — bölüm yüksekliği
// birebir hesaplanabiliyor.

import 'dart:collection';

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_renkleri.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:flutter/material.dart';

/// Gün başlığının yüksekliği — `SliverAppBar.toolbarHeight` ile aynı olmalı.
const double _baslikYuksekligi = 40;

/// Ders satırı yüksekliği. Sabit olması kaydırma hesabı için şart; yazı ölçeği
/// büyüdükçe (en fazla 1.3x) satır da büyür.
double _satirYuksekligi(BuildContext context) =>
    68 * MediaQuery.textScalerOf(context).scale(1.0);

/// Bir günün toplam yüksekliği: başlık + satırlar + aralar + alt boşluk.
double _bolumYuksekligi(int dersAdedi, double satir) {
  final adet =
      dersAdedi == 0 ? 1 : dersAdedi; // boş gün = tek "ders yok" satırı
  return _baslikYuksekligi + adet * satir + (adet - 1) * Bosluk.s + Bosluk.l;
}

class TakvimAjanda extends StatefulWidget {
  /// Görüntülenecek dersler (genelde içinde bulunulan hafta).
  final List<EtkinlikModel> dersler;
  final ValueChanged<EtkinlikModel> onLessonTap;
  final void Function(EtkinlikModel ders)? onLessonLongPress;

  /// Hafta şeridinde seçili gün. Verilirse liste bu güne kayar ve başlığı
  /// vurgulanır; verilmezse ajanda düz haftalık liste gibi davranır.
  final DateTime? secilenGun;

  /// Ders satırının sağında gösterilecek durum etiketi (role göre değişir).
  final String Function(EtkinlikModel ders)? durumEtiketi;
  final Color Function(BuildContext context, EtkinlikModel ders)? durumRengi;

  /// Kort adının altındaki satır. Verilmezse antrenörün adı yazılır (üyenin
  /// merak ettiği budur); antrenör kendi takviminde kendi adını görmek yerine
  /// katılımcıları görmek ister, o yüzden rol bazında besleniyor.
  final String Function(EtkinlikModel ders)? altSatir;

  const TakvimAjanda({
    super.key,
    required this.dersler,
    required this.onLessonTap,
    this.onLessonLongPress,
    this.secilenGun,
    this.durumEtiketi,
    this.durumRengi,
    this.altSatir,
  });

  @override
  State<TakvimAjanda> createState() => _TakvimAjandaState();
}

class _TakvimAjandaState extends State<TakvimAjanda> {
  final ScrollController _kaydirma = ScrollController();

  /// Gün -> o günün dersleri (kronolojik). `build` doldurur; kaydırma hesabı
  /// kare sonrası çalıştığı için hep güncel veriyi görür.
  SplayTreeMap<DateTime, List<EtkinlikModel>> _gunler = SplayTreeMap();

  @override
  void initState() {
    super.initState();
    if (widget.secilenGun != null) {
      _kaydirmayiPlanla(animasyonlu: false);
    }
  }

  @override
  void didUpdateWidget(TakvimAjanda oldWidget) {
    super.didUpdateWidget(oldWidget);

    final gunDegisti = !_ayniGun(oldWidget.secilenGun, widget.secilenGun);
    // Hafta değişince (ör. şerit kaydırıldı) liste yeni veriyle gelir; seçili
    // güne yeniden konumlanmak gerekir.
    final veriDegisti = oldWidget.dersler.length != widget.dersler.length ||
        (oldWidget.dersler.isNotEmpty &&
            widget.dersler.isNotEmpty &&
            oldWidget.dersler.first.id != widget.dersler.first.id);

    if (widget.secilenGun != null && (gunDegisti || veriDegisti)) {
      _kaydirmayiPlanla(animasyonlu: gunDegisti && !veriDegisti);
    }
  }

  @override
  void dispose() {
    _kaydirma.dispose();
    super.dispose();
  }

  bool _ayniGun(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return TimeUtils.normalizeDate(a) == TimeUtils.normalizeDate(b);
  }

  void _kaydirmayiPlanla({required bool animasyonlu}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _secilenGuneKaydir(animasyonlu: animasyonlu);
    });
  }

  void _secilenGuneKaydir({required bool animasyonlu}) {
    final secilen = widget.secilenGun;
    if (secilen == null || _gunler.isEmpty || !_kaydirma.hasClients) return;

    final hedefGun = TimeUtils.normalizeDate(secilen);
    final gunler = _gunler.keys.toList();

    // Seçili gün listede yoksa (geçmiş bir gün seçildiyse) sonraki dolu güne,
    // o da yoksa haftanın son gününe konumlan.
    var hedefIndeks = gunler.indexWhere((g) => !g.isBefore(hedefGun));
    if (hedefIndeks < 0) hedefIndeks = gunler.length - 1;

    final satir = _satirYuksekligi(context);
    var ofset = 0.0;
    for (var i = 0; i < hedefIndeks; i++) {
      ofset += _bolumYuksekligi(_gunler[gunler[i]]!.length, satir);
    }

    final konum = _kaydirma.position;
    final hedef = ofset.clamp(0.0, konum.maxScrollExtent);
    if ((hedef - konum.pixels).abs() < 1) return;

    if (animasyonlu) {
      _kaydirma.animateTo(
        hedef,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _kaydirma.jumpTo(hedef);
    }
  }

  SplayTreeMap<DateTime, List<EtkinlikModel>> _gunleriGrupla() {
    final gunler = SplayTreeMap<DateTime, List<EtkinlikModel>>();

    final sirali = [...widget.dersler]
      ..sort((a, b) => a.baslangicTarihSaat.compareTo(b.baslangicTarihSaat));
    for (final ders in sirali) {
      final gun = TimeUtils.normalizeDate(ders.baslangicTarihSaat);
      gunler.putIfAbsent(gun, () => []).add(ders);
    }

    // Seçili günde ders yoksa bile bölümü aç: şeritteki dokunuş boşa düşmesin.
    if (widget.secilenGun != null) {
      gunler.putIfAbsent(TimeUtils.normalizeDate(widget.secilenGun!), () => []);
    }

    return gunler;
  }

  @override
  Widget build(BuildContext context) {
    _gunler = _gunleriGrupla();

    if (widget.dersler.isEmpty) {
      return const BosDurum(
        ikon: Icons.event_available_rounded,
        baslik: 'Bu haftada ders yok',
        aciklama: 'Seçili hafta için planlanmış ders bulunmuyor. '
            'Başka bir haftaya bakmak için şeridi yana kaydır.',
      );
    }

    final satir = _satirYuksekligi(context);
    final secilen = widget.secilenGun == null
        ? null
        : TimeUtils.normalizeDate(widget.secilenGun!);

    return CustomScrollView(
      controller: _kaydirma,
      slivers: [
        // Her gün kendi grubunda: yapışkan başlık yalnız kendi günü ekrandayken
        // asılı kalır, sonraki gün onu iter. Grupsuz halde başlıklar tepede üst
        // üste yığılıyordu.
        for (final giris in _gunler.entries)
          SliverMainAxisGroup(
            slivers: [
              SliverStickyBaslik(
                gun: giris.key,
                adet: giris.value.length,
                secili: giris.key == secilen,
              ),
              if (giris.value.isEmpty)
                SliverToBoxAdapter(child: _BosGunSatiri(yukseklik: satir))
              else
                SliverList.separated(
                  itemCount: giris.value.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Bosluk.s),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
                    child: _AjandaSatiri(
                      ders: giris.value[i],
                      yukseklik: satir,
                      onTap: () => widget.onLessonTap(giris.value[i]),
                      onLongPress: widget.onLessonLongPress == null
                          ? null
                          : () => widget.onLessonLongPress!(giris.value[i]),
                      etiket: widget.durumEtiketi?.call(giris.value[i]),
                      renk: widget.durumRengi?.call(context, giris.value[i]),
                      altSatir: widget.altSatir?.call(giris.value[i]) ??
                          (giris.value[i].antrenorAdi ?? ''),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: Bosluk.l)),
            ],
          ),
      ],
    );
  }
}

/// Gün başlığı — listeyle birlikte kayar, günün üstünde asılı kalır.
class SliverStickyBaslik extends StatelessWidget {
  final DateTime gun;
  final int adet;

  /// Hafta şeridinde seçili gün mü — arka planla vurgulanır.
  final bool secili;

  const SliverStickyBaslik({
    super.key,
    required this.gun,
    required this.adet,
    this.secili = false,
  });

  @override
  Widget build(BuildContext context) {
    final bugun = TimeUtils.isSameDay(gun, simdiKulup());
    final cs = context.cs;

    return SliverAppBar(
      primary: false,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: _baslikYuksekligi,
      backgroundColor: secili ? cs.surfaceContainerHigh : cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: Bosluk.l,
      title: Row(
        children: [
          Flexible(
            child: Text(
              TimeUtils.formatDateFull(gun),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.titleSmall?.copyWith(
                color: bugun ? cs.primary : cs.onSurface,
              ),
            ),
          ),
          if (bugun) ...[
            const SizedBox(width: Bosluk.s),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Bosluk.s, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(Yaricap.s),
              ),
              child: Text(
                'Bugün',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: Bosluk.s),
          Text(
            adet == 0 ? 'Ders yok' : '$adet ders',
            maxLines: 1,
            style: context.metin.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Seçili günde ders olmadığında gösterilen satır — şeritteki dokunuşun
/// karşılığı: "bu güne baktım, boş".
class _BosGunSatiri extends StatelessWidget {
  final double yukseklik;

  const _BosGunSatiri({required this.yukseklik});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
      child: SizedBox(
        height: yukseklik,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Yaricap.l),
          ),
          child: Center(
            child: Text(
              'Bu gün için ders yok',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.bodySmall,
            ),
          ),
        ),
      ),
    );
  }
}

class _AjandaSatiri extends StatelessWidget {
  final EtkinlikModel ders;
  final double yukseklik;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? etiket;
  final Color? renk;

  /// Kort adının altındaki satır; boşsa hiç çizilmez.
  final String altSatir;

  const _AjandaSatiri({
    required this.ders,
    required this.yukseklik,
    required this.onTap,
    required this.altSatir,
    this.onLongPress,
    this.etiket,
    this.renk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final vurgu = renk ?? context.takvim.future;

    return Semantics(
      button: true,
      label: '${TimeUtils.formatTime(ders.baslangicTarihSaat)} '
          '${ders.kortAdi}${etiket == null ? '' : ', $etiket'}',
      child: SizedBox(
        height: yukseklik,
        child: Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Yaricap.l),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(Yaricap.l),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Bosluk.m),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: yukseklik - 2 * Bosluk.m,
                    decoration: BoxDecoration(
                      color: vurgu,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: Bosluk.m),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeUtils.formatTime(ders.baslangicTarihSaat),
                        maxLines: 1,
                        style: context.metin.titleSmall,
                      ),
                      Text(
                        TimeUtils.formatTime(ders.bitisTarihSaat),
                        maxLines: 1,
                        style: context.metin.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: Bosluk.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ders.kortAdi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.metin.titleSmall,
                        ),
                        if (altSatir.isNotEmpty)
                          Text(
                            altSatir,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.metin.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (etiket != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(left: Bosluk.s),
                        padding: const EdgeInsets.symmetric(
                            horizontal: Bosluk.s, vertical: 3),
                        decoration: BoxDecoration(
                          color: vurgu.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(Yaricap.s),
                        ),
                        child: Text(
                          etiket!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: vurgu,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
