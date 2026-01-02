// lib/screens/ders_listesi_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/5_etkinlik/ders_talep_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

/* -------------------------------------------------------------------------- */
/*                            Renk Sabitleri                                   */
/* -------------------------------------------------------------------------- */
const Color dersDoluRenk = Color(0xFF64748B); // Slate gray - dolu ders
const Color uygunSaatRenk = Colors.white; // Rezervasyon yapılabilir saat
const Color uygunOlmayanRenk = Color(0xFFF1F5F9); // Slate 100 - Uygun olmayan
const Color uiPrimaryBlue = Color(0xFF2563EB); // Modern blue
const Color uiPrimaryLight = Color(0xFFDBEAFE); // Blue 100
const Color uiAccentGreen = Color(0xFF10B981); // Emerald
const Color uiAccentOrange = Color(0xFFF59E0B); // Amber
const Color uiSurfaceLight = Color(0xFFFAFAFA);

/* -------------------------------------------------------------------------- */
/*                                Sayfa                                        */
/* -------------------------------------------------------------------------- */
class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});
  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage>
    with SingleTickerProviderStateMixin {
  final List<Appointment> _tumRandevular = [];
  bool _isLoading = false;

  UyeModel? currentUye;
  final Map<String, List<Map<String, dynamic>>> _slotAlternatifleri = {};
  final Set<DateTime> _yuklenenHaftalar = {};
  int userId = 0;

  // ---- Filtre state ----
  final Map<int, String> _hocaAdlari = {};
  final Map<int, String> _kortAdlari = {};
  int? _seciliHocaId;
  int? _seciliKortId;
  RangeValues _saatAralik = const RangeValues(7, 23);

  // ---- UI state ----
  late DateTime _visibleWeekStart;
  late DateTime _selectedDate;
  DateTime? _selectedSlotStart;

  // UI cache
  Map<DateTime, int> _weekUygunSayilari = {};
  List<DateTime> _selectedDayUygunSlotlar = [];
  List<Appointment> _selectedDayDersler = [];

  // Table Calendar state
  DateTime _focusedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.week;

  // Animation controller
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _visibleWeekStart = _haftaBaslangic(DateTime.now());
    _selectedDate = _normalizeDate(DateTime.now());
    _focusedDay = DateTime.now();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _prepare();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    try {
      currentUye = await StorageService.uyeBilgileriniGetir();
      userId = await SecureStorageService.getValue('user_id');

      await _loadWeek(_visibleWeekStart);
      _yenileFiltreOpsiyonlari();
      _recomputeUiCaches();

      setState(() => _isLoading = false);
      _animController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ShowMessage.error(context, 'Takvim yüklenirken hata oluştu');
      }
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                API çağrısı                                 */
  /* -------------------------------------------------------------------------- */
  Future<void> _loadWeek(DateTime weekStart) async {
    if (_yuklenenHaftalar.contains(weekStart)) return;
    _yuklenenHaftalar.add(weekStart);

    final weekEnd = weekStart.add(const Duration(days: 7));
    final nowPlus3h = DateTime.now().add(const Duration(hours: 3));

    try {
      final r = await TakvimService.loadWeek(start: weekStart, end: weekEnd);
      final WeekTakvimDataDto data =
          r.data ?? WeekTakvimDataDto(dersler: [], mesgul: [], uygun: []);

      // --- DERSLER (duplicate kontrolü ile) ---
      final existingDersIds = _tumRandevular
          .where((a) => _safeNotes(a)['tip'] == 'ders')
          .map((a) => a.id)
          .toSet();

      final dersAppts = data.dersler
          .where((d) => !existingDersIds.contains(d.id))
          .map(_dersToAppt)
          .toList();

      // --- AVAILABLE (tekilleştirilmiş) ---
      final Set<String> availKeys = {};
      final List<Appointment> availableAppts = [];
      for (final s in data.uygun.where((x) => x.baslangic.isAfter(nowPlus3h))) {
        final key = s.baslangic.toUtc().toIso8601String();
        final alt = {
          'baslangic_tarih_saat': s.baslangic.toUtc().toIso8601String(),
          'bitis_tarih_saat': s.bitis.toUtc().toIso8601String(),
          'antrenor_id': s.antrenorId,
          'antrenor_adi': s.antrenorAdi,
          'kort_id': s.kortId,
          'kort_adi': s.kortAdi,
        };
        _slotAlternatifleri.putIfAbsent(key, () => []);
        _slotAlternatifleri[key]!.add(alt);

        if (availKeys.add(key)) {
          final existsAvail =
              _tumRandevular.any((a) => a.id == 'available-$key');
          if (!existsAvail) {
            availableAppts.add(Appointment(
              id: 'available-$key',
              startTime: s.baslangic,
              endTime: s.bitis,
              subject: '',
              notes: jsonEncode({
                'tip': 'available',
                'baslangic': key,
                'bitis': s.bitis.toUtc().toIso8601String(),
              }),
              color: uygunSaatRenk.withValues(alpha: 0.3),
            ));
          }
        }
      }

      _tumRandevular.addAll(dersAppts);
      _tumRandevular.addAll(availableAppts);
    } on ApiException catch (e) {
      debugPrint('API Hatası: ${e.message}');
    } catch (e) {
      debugPrint('Takvim yükleme hatası: $e');
    }
  }

  Future<void> _forceReloadVisibleWeek() async {
    setState(() => _isLoading = true);
    _removeWeekFromCaches(_visibleWeekStart);
    await _loadWeek(_visibleWeekStart);
    _yenileFiltreOpsiyonlari();
    _recomputeUiCaches();
    setState(() => _isLoading = false);
  }

  void _removeWeekFromCaches(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));

    _tumRandevular.removeWhere((a) =>
        !a.startTime.isBefore(weekStart) && a.startTime.isBefore(weekEnd));

    final wsUtc = weekStart.toUtc();
    final weUtc = weekEnd.toUtc();
    final keysToRemove = <String>[];
    for (final k in _slotAlternatifleri.keys) {
      final dt = DateTime.tryParse(k);
      if (dt == null) continue;
      if (!dt.isBefore(wsUtc) && dt.isBefore(weUtc)) keysToRemove.add(k);
    }
    for (final k in keysToRemove) {
      _slotAlternatifleri.remove(k);
    }

    _yuklenenHaftalar.remove(weekStart);
  }

  /* -------------------------------------------------------------------------- */
  /*                               Helpers                                      */
  /* -------------------------------------------------------------------------- */
  DateTime _haftaBaslangic(DateTime d) => d
      .subtract(Duration(days: d.weekday - 1))
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _visibleWeekDays() {
    final ws = _normalizeDate(_visibleWeekStart);
    return List.generate(7, (i) => ws.add(Duration(days: i)));
  }

  Appointment _dersToAppt(EtkinlikModel d) {
    final m = d.toJson();
    final antrenorId = m['antrenor_id'] ?? m['antrenorId'] ?? m['coach_id'];
    final kortId = m['kort_id'] ?? m['kortId'] ?? m['court_id'];
    final antrenorAdi =
        m['antrenor_adi'] ?? m['antrenorAdi'] ?? m['coach_name'];
    final kortAdi =
        m['kort_adi'] ?? m['kortAdi'] ?? m['court_name'] ?? d.kortAdi;

    return Appointment(
      id: d.id,
      startTime: d.baslangicTarihSaat,
      endTime: d.bitisTarihSaat,
      subject: kortAdi?.toString() ?? d.kortAdi,
      notes: jsonEncode({
        ...m,
        'tip': 'ders',
        'antrenor_id': (antrenorId is int)
            ? antrenorId
            : int.tryParse('${antrenorId ?? ''}'),
        'antrenor_adi': antrenorAdi,
        'kort_id': (kortId is int) ? kortId : int.tryParse('${kortId ?? ''}'),
        'kort_adi': kortAdi,
      }),
      color: d.iptalMi ? uygunOlmayanRenk : dersDoluRenk,
    );
  }

  void _yenileFiltreOpsiyonlari() {
    _hocaAdlari.clear();
    _kortAdlari.clear();

    for (final a in _tumRandevular) {
      final n = _safeNotes(a);
      final tip = n['tip'];

      if (tip == 'available') {
        final key = (n['baslangic'] ?? '').toString();
        final altlar = _slotAlternatifleri[key] ?? const [];
        for (final m in altlar) {
          final hId = _toInt(m['antrenor_id']);
          final hAd = (m['antrenor_adi']?.toString() ?? '').trim();
          final kId = _toInt(m['kort_id']);
          final kAd = (m['kort_adi']?.toString() ?? '').trim();
          if (hId != null && hAd.isNotEmpty) _hocaAdlari[hId] = hAd;
          if (kId != null && kAd.isNotEmpty) _kortAdlari[kId] = kAd;
        }
      } else if (tip == 'ders') {
        final hId = _toInt(n['antrenor_id']);
        final hAd = (n['antrenor_adi']?.toString() ?? '').trim();
        final kId = _toInt(n['kort_id']);
        final kAdRaw = (n['kort_adi']?.toString() ?? '').trim();
        final kAd = kAdRaw.isNotEmpty ? kAdRaw : (a.subject.toString());
        if (hId != null && hAd.isNotEmpty) _hocaAdlari[hId] = hAd;
        if (kId != null && kAd.isNotEmpty) _kortAdlari[kId] = kAd;
      }
    }

    if (_seciliHocaId != null && !_hocaAdlari.containsKey(_seciliHocaId!)) {
      _seciliHocaId = null;
    }
    if (_seciliKortId != null && !_kortAdlari.containsKey(_seciliKortId!)) {
      _seciliKortId = null;
    }
  }

  Map<String, dynamic> _safeNotes(Appointment a) {
    try {
      return (jsonDecode(a.notes ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {
      return const {};
    }
  }

  int? _toInt(dynamic v) => (v is int) ? v : int.tryParse('$v');

  bool _availableMatchesFilters(String key) {
    final alts = _slotAlternatifleri[key] ?? const [];
    if (alts.isEmpty) return false;
    return alts.any((m) {
      final hId = _toInt(m['antrenor_id']);
      final kId = _toInt(m['kort_id']);
      if (_seciliHocaId != null && hId != _seciliHocaId) return false;
      if (_seciliKortId != null && kId != _seciliKortId) return false;
      return true;
    });
  }

  bool _withinHourRange(DateTime dt) {
    final startH = _saatAralik.start.floor();
    final endH = _saatAralik.end.ceil(); // [startH, endH)
    final sh = dt.hour + dt.minute / 60.0;
    return (sh >= startH && sh < endH);
  }

  void _recomputeUiCaches() {
    final ws = _visibleWeekStart;
    final weekEnd = ws.add(const Duration(days: 7));
    final nowPlus3h = DateTime.now().add(const Duration(hours: 3));
    final selectedDay = _normalizeDate(_selectedDate);

    final counts = <DateTime, int>{};
    final slots = <DateTime>[];
    final dersler = <Appointment>[];

    final seenAvailKeys = <String>{};
    final seenDersIds = <dynamic>{}; // Duplicate kontrolü için

    for (final a in _tumRandevular) {
      if (a.startTime.isBefore(ws) || !a.startTime.isBefore(weekEnd)) continue;

      final note = _safeNotes(a);
      final tip = note['tip'];

      if (tip == 'available') {
        final key = (note['baslangic'] ?? '').toString();
        if (key.isEmpty) continue;
        if (!seenAvailKeys.add(key)) continue;

        final st = a.startTime;
        if (st.isBefore(nowPlus3h)) continue;
        if (!_withinHourRange(st)) continue;
        if (!_availableMatchesFilters(key)) continue;

        final day = _normalizeDate(st);
        counts[day] = (counts[day] ?? 0) + 1;

        if (day == selectedDay) slots.add(st);
      } else if (tip == 'ders') {
        // Duplicate kontrolü
        if (!seenDersIds.add(a.id)) continue;

        final day = _normalizeDate(a.startTime);
        if (day == selectedDay) dersler.add(a);
      }
    }

    slots.sort();
    dersler.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final d in _visibleWeekDays()) {
      final nd = _normalizeDate(d);
      counts.putIfAbsent(nd, () => 0);
    }

    setState(() {
      _weekUygunSayilari = counts;
      _selectedDayUygunSlotlar = slots;
      _selectedDayDersler = dersler;

      if (_selectedSlotStart != null &&
          !_selectedDayUygunSlotlar.any((x) =>
              x.isAtSameMomentAs(_selectedSlotStart!) ||
              x == _selectedSlotStart)) {
        _selectedSlotStart = null;
      }
    });
  }

  int _aktifFiltreSayisi() {
    int c = 0;
    if (_seciliHocaId != null) c++;
    if (_seciliKortId != null) c++;
    if (!(_saatAralik.start == 7 && _saatAralik.end == 23)) c++;
    return c;
  }

  Future<void> _changeWeek(int deltaWeeks) async {
    final newWs = _visibleWeekStart.add(Duration(days: 7 * deltaWeeks));
    setState(() => _isLoading = true);

    await _loadWeek(newWs);

    final prevWeekday = _selectedDate.weekday;
    final newSelected = _normalizeDate(
        _normalizeDate(newWs).add(Duration(days: prevWeekday - 1)));

    setState(() {
      _visibleWeekStart = newWs;
      _selectedDate = newSelected;
      _selectedSlotStart = null;
      _focusedDay = newSelected;
    });

    _yenileFiltreOpsiyonlari();
    _recomputeUiCaches();

    setState(() => _isLoading = false);
  }

  void _selectDay(DateTime day) {
    _selectedDate = _normalizeDate(day);
    _selectedSlotStart = null;
    _recomputeUiCaches();
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final filtreCount = _aktifFiltreSayisi();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : uiSurfaceLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Takvim',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          _BadgeIconButton(
            count: filtreCount,
            icon: Icons.tune_rounded,
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Table Calendar (Modern Card Style)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: TableCalendar(
                        locale: 'tr_TR',
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDate, day),
                        calendarFormat: _calendarFormat,
                        availableCalendarFormats: const {
                          CalendarFormat.week: 'Hafta',
                        },
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: uiPrimaryLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: uiPrimaryBlue,
                              size: 20,
                            ),
                          ),
                          rightChevronIcon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: uiPrimaryLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              color: uiPrimaryBlue,
                              size: 20,
                            ),
                          ),
                          titleTextStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          headerPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          weekendStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.all(6),
                          selectedDecoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [uiPrimaryBlue, Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: uiPrimaryBlue.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          todayDecoration: BoxDecoration(
                            color: uiPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          todayTextStyle: const TextStyle(
                            color: uiPrimaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                          defaultTextStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          weekendTextStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          outsideTextStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) async {
                          final newWeekStart = _haftaBaslangic(selectedDay);

                          if (newWeekStart != _visibleWeekStart) {
                            setState(() => _isLoading = true);
                            await _loadWeek(newWeekStart);
                            setState(() {
                              _visibleWeekStart = newWeekStart;
                              _selectedDate = _normalizeDate(selectedDay);
                              _focusedDay = focusedDay;
                              _selectedSlotStart = null;
                            });
                            _yenileFiltreOpsiyonlari();
                            _recomputeUiCaches();
                            setState(() => _isLoading = false);
                          } else {
                            _selectDay(selectedDay);
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) async {
                          final newWeekStart = _haftaBaslangic(focusedDay);
                          if (newWeekStart != _visibleWeekStart) {
                            await _changeWeek((newWeekStart
                                        .difference(_visibleWeekStart)
                                        .inDays /
                                    7)
                                .round());
                          }
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final dayKey = _normalizeDate(date);
                            final uygunCount = _weekUygunSayilari[dayKey] ?? 0;

                            // Ders sayısını duplicate'sız hesapla
                            final seenIds = <dynamic>{};
                            final dersCount = _tumRandevular.where((a) {
                              final note = _safeNotes(a);
                              if (note['tip'] != 'ders') return false;
                              if (_normalizeDate(a.startTime) != dayKey) {
                                return false;
                              }
                              return seenIds.add(a.id); // Duplicate kontrolü
                            }).length;

                            if (uygunCount == 0 && dersCount == 0) return null;

                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (dersCount > 0)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: uiAccentOrange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: uiAccentOrange.withValues(
                                                alpha: 0.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (uygunCount > 0)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: uiAccentGreen,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: uiAccentGreen.withValues(
                                                alpha: 0.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gün başlığı
                          GestureDetector(
                            onLongPress: _openSelectedDayDerslerSheet,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    uiPrimaryBlue.withValues(alpha: 0.08),
                                    uiPrimaryBlue.withValues(alpha: 0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: uiPrimaryBlue.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: uiPrimaryBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatGunBaslik(_selectedDate),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedDayDersler.isNotEmpty
                                              ? '${_selectedDayDersler.length} ders • ${_selectedDayUygunSlotlar.length} uygun saat'
                                              : '${_selectedDayUygunSlotlar.length} uygun saat mevcut',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedDayDersler.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: uiAccentOrange.withValues(
                                            alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.sports_tennis_rounded,
                                            size: 14,
                                            color: uiAccentOrange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_selectedDayDersler.length}',
                                            style: TextStyle(
                                              color: uiAccentOrange,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ======== SEÇİLİ GÜNÜN DERSLERİ ========
                          if (_selectedDayDersler.isNotEmpty) ...[
                            _buildDerslerSection(theme),
                            const SizedBox(height: 24),
                          ],

                          // Bilgilendirme kartı
                          _InfoCard(
                            icon: Icons.touch_app_rounded,
                            title: 'Ders Rezervasyonu',
                            message:
                                'Aşağıdaki uygun saatlerden birini seçerek, size en uygun antrenör ve kort kombinasyonu ile ders talebinde bulunabilirsiniz.',
                            accentColor: uiAccentGreen,
                          ),

                          const SizedBox(height: 24),

                          // Uygun Saatler başlığı
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: uiAccentGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: uiAccentGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Uygun Saatler',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedDayUygunSlotlar.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        uiAccentGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_selectedDayUygunSlotlar.length} saat',
                                    style: TextStyle(
                                      color: uiAccentGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (_selectedDayUygunSlotlar.isEmpty)
                            _EmptyStateCard(
                              icon: Icons.event_busy_rounded,
                              title: 'Uygun Saat Bulunamadı',
                              message:
                                  'Seçili gün için müsait saat bulunmuyor. Farklı bir gün seçebilir veya filtreleri değiştirebilirsiniz.',
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedDayUygunSlotlar.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.4,
                              ),
                              itemBuilder: (_, i) {
                                final slot = _selectedDayUygunSlotlar[i];
                                final selected = _selectedSlotStart != null &&
                                    (_selectedSlotStart!
                                            .isAtSameMomentAs(slot) ||
                                        _selectedSlotStart == slot);

                                return _TimeTile(
                                  timeText: _formatSaatTek(slot),
                                  selected: selected,
                                  onTap: () async {
                                    setState(() => _selectedSlotStart = slot);
                                    await _showBosSaatPopup(slot);
                                    if (!mounted) return;
                                    setState(() => _selectedSlotStart = null);
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _openFilterSheet,
          elevation: 4,
          backgroundColor: uiPrimaryBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.tune_rounded),
          label: Text(
            filtreCount > 0 ? 'Filtreler ($filtreCount)' : 'Filtreler',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                          Filtre Bottom Sheet (M3)                           */
  /* -------------------------------------------------------------------------- */
  Future<void> _openFilterSheet() async {
    int? tempHoca = _seciliHocaId;
    int? tempKort = _seciliKortId;
    RangeValues tempSaat = _saatAralik;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setMState) {
            final hocaItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem(value: null, child: Text('Tüm Hocalar')),
              ..._hocaAdlari.entries.map(
                (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis)),
              ),
            ];
            final kortItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem(value: null, child: Text('Tüm Kortlar')),
              ..._kortAdlari.entries.map(
                (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis)),
              ),
            ];

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: uiPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: uiPrimaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filtreleri Düzenle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setMState(() {
                              tempHoca = null;
                              tempKort = null;
                              tempSaat = const RangeValues(7, 23);
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Sıfırla'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: tempHoca,
                            isExpanded: true,
                            items: hocaItems,
                            onChanged: (v) => setMState(() => tempHoca = v),
                            decoration: InputDecoration(
                              labelText: 'Antrenör',
                              prefixIcon: const Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: tempKort,
                            isExpanded: true,
                            items: kortItems,
                            onChanged: (v) => setMState(() => tempKort = v),
                            decoration: InputDecoration(
                              labelText: 'Kort',
                              prefixIcon:
                                  const Icon(Icons.sports_tennis_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 20, color: uiPrimaryBlue),
                              const SizedBox(width: 8),
                              const Text(
                                'Saat Aralığı',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: uiPrimaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${tempSaat.start.round()}:00 - ${tempSaat.end.round()}:00',
                                  style: const TextStyle(
                                    color: uiPrimaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: uiPrimaryBlue,
                              inactiveTrackColor: Colors.grey.shade200,
                              thumbColor: uiPrimaryBlue,
                              overlayColor:
                                  uiPrimaryBlue.withValues(alpha: 0.15),
                              trackHeight: 6,
                            ),
                            child: RangeSlider(
                              values: tempSaat,
                              onChanged: (r) => setMState(() => tempSaat = r),
                              min: 7,
                              max: 23,
                              divisions: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Vazgeç',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _seciliHocaId = tempHoca;
                                _seciliKortId = tempKort;
                                _saatAralik = tempSaat;
                                _selectedSlotStart = null;
                              });
                              _recomputeUiCaches();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text(
                              'Uygula',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: uiPrimaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                       Seçili gün derslerini göster                          */
  /* -------------------------------------------------------------------------- */
  void _openSelectedDayDerslerSheet() {
    if (_selectedDayDersler.isEmpty) {
      ShowMessage.error(context, 'Seçili günde ders bulunamadı.');
      return;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: uiAccentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_tennis_rounded,
                        color: uiAccentOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Derslerim',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _formatGunBaslik(_selectedDate),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _selectedDayDersler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final appt = _selectedDayDersler[i];
                      final note = _safeNotes(appt);
                      final ders =
                          EtkinlikModel.fromMap(note.cast<String, dynamic>());

                      final bas = appt.startTime;
                      final bit = appt.endTime;

                      final kort =
                          (note['kort_adi']?.toString().trim().isNotEmpty ??
                                  false)
                              ? note['kort_adi'].toString()
                              : appt.subject.toString();

                      final hoca =
                          (note['antrenor_adi']?.toString() ?? '').toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: uiPrimaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatSaatTek(bas),
                              style: const TextStyle(
                                color: uiPrimaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            kort,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: hoca.trim().isNotEmpty
                              ? Text(hoca)
                              : Text(
                                  _formatSaat(bas, bit),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            Navigator.pop(context);
                            await _handleDersTap(ders);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                           BOŞ slot – rezervasyon                           */
  /* -------------------------------------------------------------------------- */
  Future<void> _showBosSaatPopup(DateTime slotStart) async {
    final nowPlus3h = DateTime.now().add(const Duration(hours: 3));
    if (slotStart.isBefore(nowPlus3h)) {
      ShowMessage.error(
          context, 'Rezervasyon en az 3 saat önceden yapılabilir.');
      return;
    }

    final sh = slotStart.hour + slotStart.minute / 60.0;
    final withinHours = (sh >= _saatAralik.start && sh < _saatAralik.end);
    if (!withinHours) {
      ShowMessage.error(context, 'Saat aralığı filtre dışında.');
      return;
    }

    // Loading göstermek için dialog aç
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final rr = await TakvimService.getAntrenorUygunSaatleriApi(
        start: slotStart,
        end: slotStart.add(const Duration(hours: 1)),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Loading dialog kapat

      final list = rr.data ?? [];

      // API'den gelen veriyi antrenör bazlı düzenle
      List<Map<String, dynamic>> antrenorListesi = [];
      for (final s in list.where((a) => a.baslangic.isAfter(nowPlus3h))) {
        antrenorListesi.add({
          'baslangic_tarih_saat': s.baslangic.toUtc().toIso8601String(),
          'bitis_tarih_saat': s.bitis.toUtc().toIso8601String(),
          'antrenor_id': s.antrenorId,
          'antrenor_adi': s.antrenorAdi,
          'kortlar': s.kortlar
              .map((k) => {
                    'id': k.id,
                    'adi': k.adi,
                  })
              .toList(),
        });
      }

      if (antrenorListesi.isEmpty) {
        if (mounted) {
          ShowMessage.error(context, 'Bu saatte uygun antrenör yok');
        }
        return;
      }

      if (!mounted) return;

      final secim = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AntrenorSecimSheet(
          slotStart: slotStart,
          antrenorListesi: antrenorListesi,
        ),
      );

      if (secim != null && mounted) {
        final bool? sonuc = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DersTalepPage(secimJson: secim, baslangic: slotStart),
          ),
        );
        if (sonuc == true) {
          ShowMessage.success(context, 'Talebiniz alındı');
          await _forceReloadVisibleWeek();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog kapat
        ShowMessage.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog kapat
        ShowMessage.error(context, 'Hata oluştu. Lütfen tekrar deneyin.');
      }
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                    SEÇİLİ GÜNÜN DERSLERİ                                    */
  /* -------------------------------------------------------------------------- */
  Widget _buildDerslerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: uiAccentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.sports_tennis_rounded,
                  color: uiAccentOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Derslerim',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: uiAccentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedDayDersler.length} ders',
                style: TextStyle(
                    color: uiAccentOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedDayDersler.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildDersKart(_selectedDayDersler[i]),
        ),
      ],
    );
  }

  Widget _buildDersKart(Appointment appt) {
    final theme = Theme.of(context);
    final note = _safeNotes(appt);
    final ders = EtkinlikModel.fromMap(note.cast<String, dynamic>());
    final isPast = appt.endTime.isBefore(DateTime.now());
    final isIptal = ders.iptalMi;

    Color cardColor;
    Color accentColor;
    IconData statusIcon;
    String statusText;

    if (isIptal) {
      cardColor = Colors.red.shade50;
      accentColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = 'İptal Edildi';
    } else if (isPast) {
      cardColor = uiAccentGreen.withValues(alpha: 0.08);
      accentColor = uiAccentGreen;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Tamamlandı';
    } else {
      cardColor = uiPrimaryLight.withValues(alpha: 0.5);
      accentColor = uiPrimaryBlue;
      statusIcon = Icons.schedule_rounded;
      statusText = 'Yaklaşan';
    }

    final kort = (note['kort_adi']?.toString().trim().isNotEmpty ?? false)
        ? note['kort_adi'].toString()
        : appt.subject.toString();
    final hoca = (note['antrenor_adi']?.toString() ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isIptal ? null : () => _handleDersTap(ders),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(_formatSaatTek(appt.startTime),
                        style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text(_formatSaatTek(appt.endTime),
                        style: TextStyle(
                            color: accentColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kort,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface)),
                    if (hoca.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.person_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(hoca,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 13)),
                      ]),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(statusText,
                              style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isIptal)
                Icon(Icons.chevron_right_rounded,
                    color: accentColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDersTap(EtkinlikModel ders) async {
    if (ders.iptalMi) {
      ShowMessage.error(context, 'Bu ders iptal edilmiş.');
      return;
    }
    final isPast = ders.bitisTarihSaat.isBefore(DateTime.now());
    if (isPast) {
      _showDersGeriBildirimSheet(ders);
    } else {
      _showIptalTalebiSheet(ders);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                    GEÇMİŞ DERS – ONAY VE DEĞERLENDİRME                     */
  /* -------------------------------------------------------------------------- */
  void _showDersGeriBildirimSheet(EtkinlikModel ders) {
    final theme = Theme.of(context);
    String? secilenDurum;
    String? secilenNeden;
    int puan = 0;
    final yorumCtrl = TextEditingController();
    bool isLoading = false;

    const yapilmadiNedenleri = [
      {'code': 'YMD_OGRENCI', 'label': 'Öğrenci gelmedi'},
      {'code': 'YMD_ANTRENOR', 'label': 'Antrenör mazeretli'},
      {'code': 'YMD_HAVA', 'label': 'Hava şartları'},
      {'code': 'YMD_KORT', 'label': 'Kort müsait değil'},
      {'code': 'YMD_DIGER', 'label': 'Diğer'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: uiAccentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.rate_review_rounded,
                            color: uiAccentGreen, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ders Geri Bildirimi',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  '${_formatGunBaslik(ders.baslangicTarihSaat)} • ${_formatSaatTek(ders.baslangicTarihSaat)}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ]),
                      ),
                    ]),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ders Durumu',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _buildDurumSecenegi(
                              isSelected: secilenDurum == 'yapildi',
                              icon: Icons.check_circle_rounded,
                              color: uiAccentGreen,
                              title: 'Ders yapıldı',
                              subtitle: 'Ders planlandığı gibi gerçekleşti',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  secilenDurum = 'yapildi';
                                  secilenNeden = 'YPL_PLAN';
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildDurumSecenegi(
                              isSelected: secilenDurum == 'yapilmadi',
                              icon: Icons.cancel_rounded,
                              color: Colors.red,
                              title: 'Ders yapılmadı',
                              subtitle: 'Ders gerçekleşmedi',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() {
                                  secilenDurum = 'yapilmadi';
                                  secilenNeden = null;
                                });
                              },
                            ),
                            if (secilenDurum == 'yapilmadi') ...[
                              const SizedBox(height: 16),
                              const Text('Neden yapılmadı?',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: yapilmadiNedenleri.map((n) {
                                  final isSelected = secilenNeden == n['code'];
                                  return ChoiceChip(
                                    label: Text(n['label']!),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      HapticFeedback.selectionClick();
                                      setSheetState(
                                          () => secilenNeden = n['code']);
                                    },
                                    selectedColor: Colors.red.shade100,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.red.shade700
                                          : null,
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (secilenDurum == 'yapildi') ...[
                              const SizedBox(height: 24),
                              const Text('Değerlendirme (İsteğe bağlı)',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  final starIndex = i + 1;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setSheetState(() {
                                        puan =
                                            puan == starIndex ? 0 : starIndex;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Icon(
                                        starIndex <= puan
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 40,
                                        color: starIndex <= puan
                                            ? uiAccentOrange
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: yorumCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Yorum ekleyin (isteğe bağlı)',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ],
                          ]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20,
                        20 + MediaQuery.of(context).viewInsets.bottom),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: secilenDurum == null || isLoading
                              ? null
                              : () async {
                                  if (secilenDurum == 'yapilmadi' &&
                                      secilenNeden == null) {
                                    ShowMessage.error(
                                        context, 'Lütfen bir neden seçin');
                                    return;
                                  }
                                  setSheetState(() => isLoading = true);
                                  try {
                                    await TakvimService.setDersOnayBilgisi(
                                      dersId: ders.id,
                                      userId: userId,
                                      rol: 'uye',
                                      tamamlandi: secilenDurum == 'yapildi',
                                      onayRedIptalNedeni: secilenNeden,
                                    );
                                    if (puan > 0) {
                                      await TakvimService.setDersDegerlendirme(
                                        dersId: ders.id,
                                        userId: userId,
                                        rol: 'uye',
                                        puan: puan,
                                        yorum: yorumCtrl.text.trim(),
                                      );
                                    }
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ShowMessage.success(
                                          context, 'Geri bildirim kaydedildi');
                                    }
                                  } on ApiException catch (e) {
                                    setSheetState(() => isLoading = false);
                                    if (mounted) {
                                      ShowMessage.error(context, e.message);
                                    }
                                  } catch (e) {
                                    setSheetState(() => isLoading = false);
                                    if (mounted) {
                                      ShowMessage.error(context, 'Hata: $e');
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: uiPrimaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Kaydet',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurumSecenegi({
    required bool isSelected,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? color : null)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ]),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                     GELECEK DERS – İPTAL TALEBİ                            */
  /* -------------------------------------------------------------------------- */
  void _showIptalTalebiSheet(EtkinlikModel ders) {
    final theme = Theme.of(context);
    String? secilenSebep;
    final aciklamaCtrl = TextEditingController();
    bool isLoading = false;

    const iptalSebepleri = [
      {'code': 'HASTALIK', 'label': 'Hastalık', 'icon': Icons.sick_rounded},
      {
        'code': 'KISISEL_MAZERET',
        'label': 'Kişisel mazeret',
        'icon': Icons.person_off_rounded
      },
      {
        'code': 'HAVA_KOSULLARI',
        'label': 'Hava koşulları',
        'icon': Icons.cloud_rounded
      },
      {'code': 'DIGER', 'label': 'Diğer', 'icon': Icons.more_horiz_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.event_busy_rounded,
                          color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('İptal Talebi',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(
                                '${_formatGunBaslik(ders.baslangicTarihSaat)} • ${_formatSaatTek(ders.baslangicTarihSaat)}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.amber.shade700),
                      const SizedBox(width: 10),
                      const Expanded(
                          child: Text(
                              'İptal talebiniz yönetici onayına gönderilecektir.',
                              style: TextStyle(fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('İptal Sebebi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iptalSebepleri.map((s) {
                      final isSelected = secilenSebep == s['code'];
                      return ChoiceChip(
                        avatar: Icon(s['icon'] as IconData,
                            size: 18,
                            color:
                                isSelected ? Colors.red.shade700 : Colors.grey),
                        label: Text(s['label'] as String),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setSheetState(
                              () => secilenSebep = s['code'] as String);
                        },
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.red.shade700 : null,
                            fontWeight: isSelected ? FontWeight.w600 : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: aciklamaCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Ek açıklama (isteğe bağlı)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: secilenSebep == null || isLoading
                            ? null
                            : () async {
                                setSheetState(() => isLoading = true);
                                try {
                                  final r =
                                      await TakvimService.createIptalTalebi(
                                    dersId: ders.id,
                                    userId: userId,
                                    rol: 'uye',
                                    sebep: secilenSebep!,
                                    aciklama: aciklamaCtrl.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ShowMessage.success(context, r.mesaj);
                                  }
                                } on ApiException catch (e) {
                                  setSheetState(() => isLoading = false);
                                  if (mounted) {
                                    ShowMessage.error(context, e.message);
                                  }
                                } catch (e) {
                                  setSheetState(() => isLoading = false);
                                  if (mounted) {
                                    ShowMessage.error(context, 'Hata: $e');
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('İptal Talebi Gönder',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Bilgi Kartı Widget                                 */
/* -------------------------------------------------------------------------- */
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: accentColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Boş Durum Kartı                                    */
/* -------------------------------------------------------------------------- */
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Saat kutucuğu                                      */
/* -------------------------------------------------------------------------- */
class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.timeText,
    required this.selected,
    required this.onTap,
  });

  final String timeText;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async => onTap(),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [uiPrimaryBlue, Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: uiPrimaryBlue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         AppBar filtre ikonu badge                           */
/* -------------------------------------------------------------------------- */
class _BadgeIconButton extends StatelessWidget {
  const _BadgeIconButton({
    required this.count,
    required this.icon,
    required this.onPressed,
  });

  final int count;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final show = count > 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: uiPrimaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: uiPrimaryBlue),
            ),
          ),
          if (show)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [uiPrimaryBlue, Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: uiPrimaryBlue.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                  Antrenör Seçimi – Modern ve Sade Sheet                     */
/* -------------------------------------------------------------------------- */
class _AntrenorSecimSheet extends StatefulWidget {
  const _AntrenorSecimSheet({
    required this.slotStart,
    required this.antrenorListesi,
  });

  final DateTime slotStart;
  final List<Map<String, dynamic>> antrenorListesi;

  @override
  State<_AntrenorSecimSheet> createState() => _AntrenorSecimSheetState();
}

class _AntrenorSecimSheetState extends State<_AntrenorSecimSheet> {
  int? _selectedAntrenorId;
  int? _selectedKortId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        uiAccentGreen,
                        uiAccentGreen.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: uiAccentGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Antrenör Seçin',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatSaatTek(widget.slotStart),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: uiAccentGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.antrenorListesi.length} antrenör',
                              style: TextStyle(
                                color: uiAccentGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Antrenör listesi
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              shrinkWrap: true,
              itemCount: widget.antrenorListesi.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final antrenor = widget.antrenorListesi[index];
                final antrenorId = antrenor['antrenor_id'] as int?;
                final antrenorAdi =
                    antrenor['antrenor_adi']?.toString() ?? 'Antrenör';
                final kortlar = (antrenor['kortlar'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];
                final isExpanded = _selectedAntrenorId == antrenorId;

                return _AntrenorKart(
                  antrenorAdi: antrenorAdi,
                  kortlar: kortlar,
                  isExpanded: isExpanded,
                  selectedKortId: _selectedKortId,
                  onTap: () {
                    setState(() {
                      if (_selectedAntrenorId == antrenorId) {
                        _selectedAntrenorId = null;
                        _selectedKortId = null;
                      } else {
                        _selectedAntrenorId = antrenorId;
                        _selectedKortId = null;
                      }
                    });
                  },
                  onKortSelected: (kortId, kortAdi) {
                    // Seçimi döndür
                    Navigator.pop(context, {
                      'baslangic_tarih_saat': antrenor['baslangic_tarih_saat'],
                      'bitis_tarih_saat': antrenor['bitis_tarih_saat'],
                      'antrenor_id': antrenorId,
                      'antrenor_adi': antrenorAdi,
                      'kort_id': kortId,
                      'kort_adi': kortAdi,
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Antrenör Kartı                                     */
/* -------------------------------------------------------------------------- */
class _AntrenorKart extends StatelessWidget {
  const _AntrenorKart({
    required this.antrenorAdi,
    required this.kortlar,
    required this.isExpanded,
    required this.selectedKortId,
    required this.onTap,
    required this.onKortSelected,
  });

  final String antrenorAdi;
  final List<Map<String, dynamic>> kortlar;
  final bool isExpanded;
  final int? selectedKortId;
  final VoidCallback onTap;
  final void Function(int kortId, String kortAdi) onKortSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color:
            isExpanded ? uiPrimaryLight.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? uiPrimaryBlue.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? uiPrimaryBlue.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isExpanded ? 16 : 8,
            offset: Offset(0, isExpanded ? 6 : 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Antrenör header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isExpanded
                              ? [uiPrimaryBlue, const Color(0xFF3B82F6)]
                              : [Colors.grey.shade200, Colors.grey.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isExpanded
                            ? [
                                BoxShadow(
                                  color: uiPrimaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: isExpanded ? Colors.white : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // İsim ve kort sayısı
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            antrenorAdi,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isExpanded
                                  ? uiPrimaryBlue
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.sports_tennis_rounded,
                                size: 14,
                                color: uiAccentGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${kortlar.length} kort müsait',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Expand icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? uiPrimaryBlue.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color:
                              isExpanded ? uiPrimaryBlue : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Kort listesi (expanded)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Text(
                    'Kort seçin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kortlar.map((kort) {
                      final kortId = kort['id'] as int;
                      final kortAdi = kort['adi']?.toString() ?? 'Kort';

                      return _KortChip(
                        kortAdi: kortAdi,
                        onTap: () => onKortSelected(kortId, kortAdi),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Kort Chip                                      */
/* -------------------------------------------------------------------------- */
class _KortChip extends StatelessWidget {
  const _KortChip({
    required this.kortAdi,
    required this.onTap,
  });

  final String kortAdi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uiAccentGreen.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: uiAccentGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: uiAccentGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                kortAdi,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Format helpers                                 */
/* -------------------------------------------------------------------------- */
String _formatSaat(DateTime bas, DateTime bit) {
  String f(int v) => v.toString().padLeft(2, '0');
  return '${f(bas.hour)}:${f(bas.minute)} – ${f(bit.hour)}:${f(bit.minute)}';
}

String _formatSaatTek(DateTime t) {
  String f(int v) => v.toString().padLeft(2, '0');
  return '${f(t.hour)}:${f(t.minute)}';
}

String _formatGunBaslik(DateTime d) {
  const aylar = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];
  const gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  final ay = aylar[d.month - 1];
  final gun = gunler[d.weekday - 1];
  return '${d.day} $ay $gun';
}

// Syncfusion Appointment sınıfı (mevcut kodda kullanıldığı için korundu)
class Appointment {
  final dynamic id;
  final DateTime startTime;
  final DateTime endTime;
  final String subject;
  final String? notes;
  Color color;

  Appointment({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.notes,
    required this.color,
  });
}
