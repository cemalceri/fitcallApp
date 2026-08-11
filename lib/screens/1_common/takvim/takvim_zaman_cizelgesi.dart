// lib/screens/1_common/takvim/takvim_zaman_cizelgesi.dart
//
// Günlük saat ızgarası (timeline) — üye ve antrenör takviminin ortak gövdesi.
//
// İki rolde iki ayrı kopya vardı (437 ve 354 satır); zamanla ayrıştılar,
// üyedeki "şu ana kaydır" davranışı antrenöre hiç gelmedi. Tek fark ders
// bloğunun görünümüydü: o da [blokYapici] ile dışarıdan veriliyor.

import 'dart:async';

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/takvim/position_calculator.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_renkleri.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:flutter/material.dart';

class TakvimZamanCizelgesi extends StatefulWidget {
  final List<EtkinlikModel> dersler;
  final DateTime selectedDay;
  final ValueChanged<EtkinlikModel> onLessonTap;

  /// Ders bloğunu üreten yapıcı — rolün kendi `LessonBlock`'u.
  final Widget Function(EtkinlikModel ders, VoidCallback onTap) blokYapici;

  /// Bloğa uzun basınca açılan bağlam menüsü (antrenörde onay/iptal/devir).
  final void Function(EtkinlikModel ders)? onLessonLongPress;

  const TakvimZamanCizelgesi({
    super.key,
    required this.dersler,
    required this.selectedDay,
    required this.onLessonTap,
    required this.blokYapici,
    this.onLessonLongPress,
  });

  @override
  State<TakvimZamanCizelgesi> createState() => _TakvimZamanCizelgesiState();
}

class _TakvimZamanCizelgesiState extends State<TakvimZamanCizelgesi> {
  Timer? _timer;
  DateTime _currentTime = simdiKulup();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _currentTime = simdiKulup());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _suAnaKaydir());
  }

  @override
  void didUpdateWidget(TakvimZamanCizelgesi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!TimeUtils.isSameDay(oldWidget.selectedDay, widget.selectedDay)) {
      if (TimeUtils.isSameDay(widget.selectedDay, simdiKulup())) {
        _suAnaKaydir();
      } else {
        _ilkDerseKaydir();
      }
    }
  }

  void _suAnaKaydir() {
    if (!TimeUtils.isSameDay(widget.selectedDay, simdiKulup())) return;
    _kaydir(TimeUtils.timeToPixel(simdiKulup()) - 150);
  }

  void _ilkDerseKaydir() {
    if (widget.dersler.isEmpty) return;
    final ilk = widget.dersler.reduce(
        (a, b) => a.baslangicTarihSaat.isBefore(b.baslangicTarihSaat) ? a : b);
    _kaydir(TimeUtils.timeToPixel(ilk.baslangicTarihSaat) - 50);
  }

  void _kaydir(double hedef) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      hedef.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = PositionCalculator.calculate(widget.dersler);
    final isToday = TimeUtils.isSameDay(widget.selectedDay, simdiKulup());

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth -
            TakvimSizes.timeColumnWidth -
            TakvimSizes.timelineRightPadding;

        return SingleChildScrollView(
          controller: _scrollController,
          // Yatay kaydırmayla hafta değişimi üstteki PageView'e ait; dikey
          // kaydırma burada kalır.
          child: SizedBox(
            height: TakvimSizes.totalTimelineHeight + 40,
            child: Stack(
              children: [
                ..._saatCizgileri(),
                ...result.positionedLessons.map(
                  (pl) => Positioned(
                    top: pl.top,
                    left: TakvimSizes.timeColumnWidth +
                        pl.getLeft(availableWidth),
                    width: pl.getWidth(availableWidth) - 4,
                    height: pl.height,
                    child: GestureDetector(
                      onLongPress: widget.onLessonLongPress == null
                          ? null
                          : () => widget.onLessonLongPress!(pl.ders),
                      child: widget.blokYapici(
                        pl.ders,
                        () => widget.onLessonTap(pl.ders),
                      ),
                    ),
                  ),
                ),
                ...result.overflows.map(
                  (overflow) => Positioned(
                    top: overflow.top + overflow.height - 24,
                    right: TakvimSizes.timelineRightPadding,
                    child: _FazlaDersRozeti(
                      count: overflow.extraLessons.length,
                      onTap: () => _fazlaDersleriAc(context, overflow),
                    ),
                  ),
                ),
                if (isToday) _suAnCizgisi(),
                if (widget.dersler.isEmpty) _bosGun(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _saatCizgileri() {
    final lines = <Widget>[];
    for (int hour = TakvimSizes.dayStartHour;
        hour <= TakvimSizes.dayEndHour;
        hour++) {
      final top = (hour - TakvimSizes.dayStartHour) * TakvimSizes.hourHeight;
      lines.add(_SaatCizgisi(top: top, hour: hour, yarimSaat: false));
      if (hour < TakvimSizes.dayEndHour) {
        lines.add(_SaatCizgisi(
          top: top + TakvimSizes.hourHeight / 2,
          hour: hour,
          yarimSaat: true,
        ));
      }
    }
    return lines;
  }

  Widget _suAnCizgisi() {
    final top = TimeUtils.timeToPixel(_currentTime);
    if (top < 0 || top > TakvimSizes.totalTimelineHeight) {
      return const SizedBox.shrink();
    }

    final renk = context.takvim.currentTimeLine;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              TimeUtils.formatTime(_currentTime),
              style: TextStyle(
                color: uzerineYazi(renk),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: TakvimSizes.currentTimeLineThickness,
              color: renk,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
          ),
          const SizedBox(width: TakvimSizes.timelineRightPadding),
        ],
      ),
    );
  }

  Widget _bosGun() {
    return const Positioned.fill(
      child: BosDurum(
        ikon: Icons.event_available_rounded,
        baslik: 'Bu gün ders yok',
        aciklama: 'Seçili günde planlanmış ders bulunmuyor. '
            'Diğer günlere bakmak için şeridi yana kaydır.',
      ),
    );
  }

  /// Çakışan derslerin fazlası — ortadaki diyalog yerine alt sayfa.
  void _fazlaDersleriAc(BuildContext context, OverflowInfo overflow) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.sports_tennis_rounded,
                      color: sheetContext.takvim.pending),
                  const SizedBox(width: 12),
                  Text(
                    '+${overflow.extraLessons.length} ders daha',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            ...overflow.extraLessons.map(
              (ders) => ListTile(
                leading: Icon(Icons.schedule_rounded,
                    color: sheetContext.takvim.primary),
                title: Text(ders.kortAdi),
                subtitle: Text(
                  '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - '
                  '${TimeUtils.formatTime(ders.bitisTarihSaat)}',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onLessonTap(ders);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SaatCizgisi extends StatelessWidget {
  final double top;
  final int hour;
  final bool yarimSaat;

  const _SaatCizgisi({
    required this.top,
    required this.hour,
    required this.yarimSaat,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.takvim;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: TakvimSizes.timeColumnWidth - 8,
            child: yarimSaat
                ? const SizedBox.shrink()
                : Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: t.textMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: yarimSaat
                  ? TakvimSizes.halfHourLineThickness
                  : TakvimSizes.hourLineThickness,
              color: yarimSaat ? t.halfHourLine : t.hourLine,
            ),
          ),
          const SizedBox(width: TakvimSizes.timelineRightPadding),
        ],
      ),
    );
  }
}

class _FazlaDersRozeti extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FazlaDersRozeti({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final zemin = context.takvim.pending;
    return Semantics(
      button: true,
      label: '$count ders daha',
      child: Material(
        color: zemin,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              '+$count',
              style: TextStyle(
                color: uzerineYazi(zemin),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
