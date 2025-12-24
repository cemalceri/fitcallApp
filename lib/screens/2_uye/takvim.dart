// lib/screens/ders_listesi_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_onay_model.dart';
import 'package:fitcall/screens/5_etkinlik/ders_talep_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
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
  final Map<int, EtkinlikOnayModel> _userOnaylari = {};
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
    currentUye = await StorageService.uyeBilgileriniGetir();
    userId = await SecureStorageService.getValue('user_id');

    await _loadWeek(_visibleWeekStart);
    _yenileFiltreOpsiyonlari();
    _recomputeUiCaches();

    setState(() => _isLoading = false);
    _animController.forward();
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

      // --- DERSLER ---
      final dersAppts = data.dersler.map(_dersToAppt).toList();

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

      _tumRandevular.addAll(dersAppts);
      _tumRandevular.addAll(availableAppts);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Takvim alınamadı: $e');
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
      .copyWith(hour: 7, minute: 0, second: 0, millisecond: 0);

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
    setState(() {
      _selectedDate = _normalizeDate(day);
      _selectedSlotStart = null;
    });
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
                            setState(() => _focusedDay = focusedDay);
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

                            final hasDers = _tumRandevular.any((a) {
                              final note = _safeNotes(a);
                              return note['tip'] == 'ders' &&
                                  _normalizeDate(a.startTime) == dayKey;
                            });

                            if (uygunCount == 0 && !hasDers) return null;

                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasDers)
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
                                            blurRadius: 4,
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
                                            blurRadius: 4,
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
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ];
            final kortItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem(value: null, child: Text('Tüm Kortlar')),
              ..._kortAdlari.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: tempKort,
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

  Future<void> _handleDersTap(EtkinlikModel ders) async {
    final isPast = ders.bitisTarihSaat.isBefore(DateTime.now());

    if (ders.iptalMi) {
      ShowMessage.error(context, 'Bu ders iptal edilmiş.');
      return;
    }

    if (isPast) {
      final onay = _userOnaylari[ders.id];
      _showTamamlamaPopup(
        ders,
        userCompleted: onay?.tamamlandi ?? false,
        userAciklama: onay?.aciklama ?? '',
        onSaved: (tam, acik) {
          _userOnaylari[ders.id] = EtkinlikOnayModel.empty()
            ..tamamlandi = tam
            ..aciklama = acik;
        },
      );
    } else {
      _showIptalPopup(
        ders,
        onCancelled: () async {
          await _forceReloadVisibleWeek();
        },
      );
    }
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

    final key = slotStart.toUtc().toIso8601String();
    List<Map<String, dynamic>> alternatifler = _slotAlternatifleri[key] ?? [];

    if (alternatifler.isEmpty) {
      try {
        final rr = await TakvimService.getUygunSaatlerAralik(
          start: slotStart,
          end: slotStart.add(const Duration(hours: 1)),
        );
        final list = rr.data ?? [];
        alternatifler = list
            .where((a) => a.baslangic.isAfter(nowPlus3h))
            .map((s) => {
                  'baslangic_tarih_saat': s.baslangic.toUtc().toIso8601String(),
                  'bitis_tarih_saat': s.bitis.toUtc().toIso8601String(),
                  'antrenor_id': s.antrenorId,
                  'antrenor_adi': s.antrenorAdi,
                  'kort_id': s.kortId,
                  'kort_adi': s.kortAdi,
                })
            .toList();
      } on ApiException catch (e) {
        ShowMessage.error(context, e.message);
        return;
      } catch (e) {
        ShowMessage.error(context, 'Hata: $e');
        return;
      }
    }

    if (alternatifler.isEmpty) {
      ShowMessage.error(context, 'Bu saatte uygun kort/antrenör yok');
      return;
    }

    final secim = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotSecimSheet(
        slotStart: slotStart,
        alternatifler: alternatifler,
      ),
    );

    if (secim != null) {
      final bool? sonuc = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DersTalepPage(secimJson: secim, baslangic: slotStart),
        ),
      );
      if (sonuc == true) {
        ShowMessage.success(context, 'Talebiniz alındı');
        await _forceReloadVisibleWeek();
      }
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                    Geçmiş ders – tamamlama popup                           */
  /* -------------------------------------------------------------------------- */
  void _showTamamlamaPopup(EtkinlikModel ders,
      {required bool userCompleted,
      required String userAciklama,
      required void Function(bool, String) onSaved}) {
    final ctrl = TextEditingController(text: userAciklama);
    bool tamamlandi = userCompleted;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: uiAccentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.rate_review_rounded,
                  color: uiAccentGreen, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ders Değerlendirme'),
          ],
        ),
        content: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text('Ders tamamlandı mı?'),
                  value: tamamlandi,
                  onChanged: (v) => setState(() => tamamlandi = v ?? false),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Not',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: uiPrimaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kaydet'),
            onPressed: () async {
              try {
                final r = await TakvimService.setDersYapildiBilgisiApi(
                    dersId: ders.id,
                    tamamlandi: tamamlandi,
                    aciklama: ctrl.text,
                    rol: 'UYE',
                    userId: userId);
                onSaved(tamamlandi, ctrl.text);
                ShowMessage.success(context, r.mesaj);
              } on ApiException catch (e) {
                ShowMessage.error(context, e.message);
              } catch (e) {
                ShowMessage.error(context, 'Hata: $e');
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                     Gelecek ders – iptal popup                             */
  /* -------------------------------------------------------------------------- */
  void _showIptalPopup(EtkinlikModel ders,
      {Future<void> Function()? onCancelled}) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ders İptal Et'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Neden iptal ediyorsunuz? (isteğe bağlı)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('İptal Et'),
            onPressed: () async {
              try {
                final res = await TakvimService.uyeDersIptal(
                  etkinlikId: ders.id,
                  aciklama: ctrl.text,
                );

                ShowMessage.success(context, res.mesaj);
                if (onCancelled != null) await onCancelled();
              } on ApiException catch (e) {
                ShowMessage.error(context, e.message);
              } catch (e) {
                ShowMessage.error(context, 'Hata: $e');
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
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
/*                    Uygun Slot Seçimi – Gruplanmış Sheet                     */
/* -------------------------------------------------------------------------- */
class _SlotSecimSheet extends StatefulWidget {
  const _SlotSecimSheet({
    required this.slotStart,
    required this.alternatifler,
  });

  final DateTime slotStart;
  final List<Map<String, dynamic>> alternatifler;

  @override
  State<_SlotSecimSheet> createState() => _SlotSecimSheetState();
}

enum _GrupTuru { hoca, kort }

class _SlotSecimSheetState extends State<_SlotSecimSheet> {
  _GrupTuru _grup = _GrupTuru.hoca;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> gruplu = _grup ==
            _GrupTuru.hoca
        ? _grupla(
            widget.alternatifler, (m) => (m['antrenor_adi'] ?? '—').toString())
        : _grupla(
            widget.alternatifler, (m) => (m['kort_adi'] ?? '—').toString());

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: uiAccentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: uiAccentGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seçenek Belirleyin',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _formatSaatTek(widget.slotStart),
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
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: 'Antrenör',
                        icon: Icons.person_rounded,
                        selected: _grup == _GrupTuru.hoca,
                        onTap: () => setState(() => _grup = _GrupTuru.hoca),
                      ),
                    ),
                    Expanded(
                      child: _SegmentButton(
                        label: 'Kort',
                        icon: Icons.sports_tennis_rounded,
                        selected: _grup == _GrupTuru.kort,
                        onTap: () => setState(() => _grup = _GrupTuru.kort),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: gruplu.length,
                itemBuilder: (_, i) {
                  final baslik = gruplu.keys.elementAt(i);
                  final liste = gruplu[baslik]!
                    ..sort((a, b) => a['baslangic_tarih_saat']
                        .compareTo(b['baslangic_tarih_saat']));

                  return _GrupKart(
                    baslik: baslik,
                    altBaslik: _grup == _GrupTuru.hoca
                        ? 'Uygun kortlar'
                        : 'Uygun antrenörler',
                    slotlar: liste,
                    onSelect: (secim) => Navigator.pop(context, secim),
                    slotStart: widget.slotStart,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _grupla(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) keySelector,
  ) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final m in items) {
      final k = keySelector(m);
      map.putIfAbsent(k, () => []).add(m);
    }
    return map;
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? uiPrimaryBlue : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? uiPrimaryBlue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrupKart extends StatelessWidget {
  const _GrupKart({
    required this.baslik,
    required this.altBaslik,
    required this.slotlar,
    required this.onSelect,
    required this.slotStart,
  });

  final String baslik;
  final String altBaslik;
  final List<Map<String, dynamic>> slotlar;
  final void Function(Map<String, dynamic>) onSelect;
  final DateTime slotStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: uiAccentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${slotlar.length} seçenek',
                    style: TextStyle(
                      color: uiAccentGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              altBaslik,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ...slotlar.map((a) {
              final bas = DateTime.parse(a['baslangic_tarih_saat']).toLocal();
              final bit = DateTime.parse(a['bitis_tarih_saat']).toLocal();
              final saatText = _formatSaat(bas, bit);
              final chipSol = a['kort_adi']?.toString() ?? '';
              final chipSag = a['antrenor_adi']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(a),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: uiPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              saatText,
                              style: const TextStyle(
                                color: uiPrimaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _chip(context, chipSol),
                                _chip(context, chipSag, outlined: true),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: uiPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: uiPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : uiAccentGreen.withValues(alpha: 0.12),
        border: outlined ? Border.all(color: Colors.grey.shade300) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: outlined ? Colors.grey.shade600 : uiAccentGreen,
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
