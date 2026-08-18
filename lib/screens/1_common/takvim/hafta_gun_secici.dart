// lib/screens/1_common/takvim/hafta_gun_secici.dart
//
// Hafta şeridi — üye ve antrenör takviminin ortak gün seçicisi.
//
// Eskiden hafta değiştirmenin tek yolu küçük chevron butonlarıydı; hiçbir
// takvim uygulaması böyle çalışmıyor. Şerit artık `PageView` üzerinde:
// yana kaydırınca hafta değişir, chevron'lar da yerinde kalır.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_renkleri.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HaftaGunSecici extends StatefulWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;

  /// Gün -> o gündeki ders sayısı (şeritteki noktalar).
  final Map<DateTime, int> lessonCounts;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const HaftaGunSecici({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.lessonCounts,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  State<HaftaGunSecici> createState() => _HaftaGunSeciciState();
}

class _HaftaGunSeciciState extends State<HaftaGunSecici> {
  /// PageView sonsuz gibi davransın diye ortadan başlıyoruz; her sayfa
  /// merkezden kaç hafta uzakta olduğunu temsil eder.
  static const int _merkez = 1000;

  late final PageController _controller = PageController(initialPage: _merkez);
  late DateTime _merkezHafta = TimeUtils.getWeekStart(widget.focusedDay);
  int _aktifSayfa = _merkez;

  @override
  void didUpdateWidget(HaftaGunSecici oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan hafta değiştiyse (ör. "Bugün" butonu) şeridi hizala.
    final yeniHafta = TimeUtils.getWeekStart(widget.focusedDay);
    final beklenen = _sayfaninHaftasi(_aktifSayfa);
    if (yeniHafta != beklenen) {
      _merkezHafta = yeniHafta;
      _aktifSayfa = _merkez;
      if (_controller.hasClients) _controller.jumpToPage(_merkez);
    }
  }

  DateTime _sayfaninHaftasi(int sayfa) =>
      _merkezHafta.add(Duration(days: 7 * (sayfa - _merkez)));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _haftaAtla(int yon) {
    HapticFeedback.selectionClick();
    widget.onPageChanged(widget.focusedDay.add(Duration(days: 7 * yon)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          _AyGezinme(
            focusedDay: widget.focusedDay,
            onGeri: () => _haftaAtla(-1),
            onIleri: () => _haftaAtla(1),
            onBugun: () {
              HapticFeedback.selectionClick();
              final bugun = simdiKulup();
              widget.onPageChanged(bugun);
              widget.onDaySelected(bugun);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            // Gün hücresinin içeriği (ad + numara + noktalar) 1.3x yazı
            // ölçeğinde bu yüksekliğe sığar.
            height: 68 * MediaQuery.textScalerOf(context).scale(1.0),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (sayfa) {
                _aktifSayfa = sayfa;
                HapticFeedback.selectionClick();
                // Kaydırılan haftanın, seçili günle aynı gün indeksi seçilir.
                final hafta = _sayfaninHaftasi(sayfa);
                widget.onPageChanged(
                    hafta.add(Duration(days: widget.selectedDay.weekday - 1)));
              },
              itemBuilder: (context, sayfa) {
                final hafta = _sayfaninHaftasi(sayfa);
                return Row(
                  children: List.generate(
                    7,
                    (i) => _GunHucresi(
                      gun: hafta.add(Duration(days: i)),
                      selectedDay: widget.selectedDay,
                      dersSayisi: widget.lessonCounts[TimeUtils.normalizeDate(
                              hafta.add(Duration(days: i)))] ??
                          0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onDaySelected(hafta.add(Duration(days: i)));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AyGezinme extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onGeri;
  final VoidCallback onIleri;
  final VoidCallback onBugun;

  const _AyGezinme({
    required this.focusedDay,
    required this.onGeri,
    required this.onIleri,
    required this.onBugun,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _OkButonu(
          ikon: Icons.chevron_left_rounded,
          etiket: 'Önceki hafta',
          onTap: onGeri,
        ),
        Flexible(
          child: Semantics(
            button: true,
            label: 'Bugüne git',
            child: GestureDetector(
              onTap: onBugun,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.takvim.primaryLight,
                  borderRadius: BorderRadius.circular(Yaricap.m),
                ),
                child: Text(
                  '${TimeUtils.getMonthName(focusedDay.month)} ${focusedDay.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleMedium,
                ),
              ),
            ),
          ),
        ),
        _OkButonu(
          ikon: Icons.chevron_right_rounded,
          etiket: 'Sonraki hafta',
          onTap: onIleri,
        ),
        const SizedBox(width: Bosluk.s),
        // Yazılı buton: bugüne dönüş eskiden yalnız ay etiketine dokunmakla ya
        // da başlıktaki takvim ikonuyla oluyordu; ikisi de ne yaptığını
        // söylemiyordu.
        _BugunButonu(onTap: onBugun),
      ],
    );
  }
}

/// "Bugün" — ikon + yazı, çünkü tek başına ikon bu işi anlatmıyor.
class _BugunButonu extends StatelessWidget {
  final VoidCallback onTap;

  const _BugunButonu({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.takvim;

    return Semantics(
      button: true,
      label: 'Bugüne git',
      child: Material(
        color: t.primaryLight,
        borderRadius: BorderRadius.circular(Yaricap.s),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Yaricap.s),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Bosluk.s, vertical: Bosluk.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.today_rounded, size: 18, color: t.primary),
                const SizedBox(width: 4),
                Text(
                  'Bugün',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OkButonu extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final VoidCallback onTap;

  const _OkButonu({
    required this.ikon,
    required this.etiket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiket,
      child: Material(
        color: context.takvim.primaryLight,
        borderRadius: BorderRadius.circular(Yaricap.s),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Yaricap.s),
          child: Padding(
            padding: const EdgeInsets.all(Bosluk.s),
            child: Icon(ikon, size: 20, color: context.takvim.primary),
          ),
        ),
      ),
    );
  }
}

class _GunHucresi extends StatelessWidget {
  final DateTime gun;
  final DateTime selectedDay;
  final int dersSayisi;
  final VoidCallback onTap;

  const _GunHucresi({
    required this.gun,
    required this.selectedDay,
    required this.dersSayisi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.takvim;
    final secili = TimeUtils.isSameDay(gun, selectedDay);
    final bugun = TimeUtils.isSameDay(gun, simdiKulup());

    return Expanded(
      child: Semantics(
        button: true,
        selected: secili,
        label: '${TimeUtils.formatDateFull(gun)}, $dersSayisi ders',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: secili
                  ? t.primary
                  : bugun
                      ? t.primaryLight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(TakvimSizes.dayItemRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeUtils.shortDayName(gun.weekday),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secili
                        ? context.cs.onPrimary.withValues(alpha: 0.85)
                        : t.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${gun.day}',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: secili
                        ? context.cs.onPrimary
                        : bugun
                            ? t.primary
                            : t.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      dersSayisi.clamp(0, 4),
                      (i) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: secili
                              ? context.cs.onPrimary.withValues(alpha: 0.85)
                              : t.pending,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
