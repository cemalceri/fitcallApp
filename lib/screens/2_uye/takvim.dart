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
const Color dersDoluRenk = Colors.grey; // Takvimdeki dolu ders
const Color uygunSaatRenk = Colors.white; // Rezervasyon yapılabilir saat
const Color uygunOlmayanRenk =
    Color.fromARGB(255, 233, 240, 255); // Uygun olmayan
const Color uiPrimaryBlue = Color(0xFF2F6FED); // İstenen mavi

/* -------------------------------------------------------------------------- */
/*                                Sayfa                                        */
/* -------------------------------------------------------------------------- */
class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});
  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
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

  @override
  void initState() {
    super.initState();
    _visibleWeekStart = _haftaBaslangic(DateTime.now());
    _selectedDate = _normalizeDate(DateTime.now());
    _focusedDay = DateTime.now();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    currentUye = await StorageService.uyeBilgileriniGetir();
    userId = await SecureStorageService.getValue('user_id');

    await _loadWeek(_visibleWeekStart);
    _yenileFiltreOpsiyonlari();
    _recomputeUiCaches();

    setState(() => _isLoading = false);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvim'),
        actions: [
          _BadgeIconButton(
            count: filtreCount,
            icon: Icons.filter_alt_rounded,
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.filter_alt_rounded),
              label: Text(
                filtreCount > 0 ? 'Filtreler ($filtreCount)' : 'Filtreler',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: uiPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : Column(
              children: [
                // Table Calendar (Kompakt)
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                      titleTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      weekendStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4),
                      selectedDecoration: BoxDecoration(
                        color: uiPrimaryBlue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: uiPrimaryBlue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(fontSize: 15),
                      weekendTextStyle: const TextStyle(fontSize: 15),
                      outsideTextStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) async {
                      final newWeekStart = _haftaBaslangic(selectedDay);

                      if (newWeekStart != _visibleWeekStart) {
                        // Yeni haftaya geçiş
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
                        // Aynı hafta içinde gün değişimi
                        _selectDay(selectedDay);
                        setState(() => _focusedDay = focusedDay);
                      }
                    },
                    onPageChanged: (focusedDay) async {
                      final newWeekStart = _haftaBaslangic(focusedDay);
                      if (newWeekStart != _visibleWeekStart) {
                        await _changeWeek(
                            (newWeekStart.difference(_visibleWeekStart).inDays /
                                    7)
                                .round());
                      }
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final dayKey = _normalizeDate(date);
                        final uygunCount = _weekUygunSayilari[dayKey] ?? 0;

                        // Bu günde ders var mı?
                        final hasDers = _tumRandevular.any((a) {
                          final note = _safeNotes(a);
                          return note['tip'] == 'ders' &&
                              _normalizeDate(a.startTime) == dayKey;
                        });

                        if (uygunCount == 0 && !hasDers) return null;

                        return Positioned(
                          bottom: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDers)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (uygunCount > 0)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: uiPrimaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onLongPress: _openSelectedDayDerslerSheet,
                          child: Column(
                            children: [
                              Text(
                                _formatGunBaslik(_selectedDate),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Uygun Saatler',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_selectedDayUygunSlotlar.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Seçili gün için uygun saat bulunamadı.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                              childAspectRatio: 2.7,
                            ),
                            itemBuilder: (_, i) {
                              final slot = _selectedDayUygunSlotlar[i];
                              final selected = _selectedSlotStart != null &&
                                  (_selectedSlotStart!.isAtSameMomentAs(slot) ||
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Filtreler',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setMState(() {
                            tempHoca = null;
                            tempKort = null;
                            tempSaat = const RangeValues(7, 23);
                          });
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Temizle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: tempHoca,
                          items: hocaItems,
                          onChanged: (v) => setMState(() => tempHoca = v),
                          decoration: const InputDecoration(
                            labelText: 'Hoca',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: tempKort,
                          items: kortItems,
                          onChanged: (v) => setMState(() => tempKort = v),
                          decoration: const InputDecoration(
                            labelText: 'Kort',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Saat Aralığı',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                  RangeSlider(
                    values: tempSaat,
                    onChanged: (r) => setMState(() => tempSaat = r),
                    min: 7,
                    max: 23,
                    divisions: 16,
                    labels: RangeLabels(
                      '${tempSaat.start.round()}:00',
                      '${tempSaat.end.round()}:00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
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
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dersler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    _formatGunBaslik(_selectedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _selectedDayDersler.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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

                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      title: Text(_formatSaat(bas, bit),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [kort, if (hoca.trim().isNotEmpty) hoca].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        await _handleDersTap(ders);
                      },
                    );
                  },
                ),
              ),
            ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        title: const Text('Ders Değerlendirme'),
        content: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                  title: const Text('Ders tamamlandı mı?'),
                  value: tamamlandi,
                  onChanged: (v) => setState(() => tamamlandi = v ?? false)),
              const SizedBox(height: 8),
              TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Not', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat')),
          ElevatedButton(
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
              })
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
        title: const Text('Ders İptal Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('*Bu işlem geri alınamaz.'),
            const SizedBox(height: 8),
            TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Neden iptal ediyorsunuz?(isteğe bağlı)',
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          ElevatedButton(
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
          )
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
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected ? uiPrimaryBlue : scheme.outlineVariant;

    return InkWell(
      onTap: () async => onTap(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Text(
          timeText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
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
      padding: const EdgeInsets.only(right: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(onPressed: onPressed, icon: Icon(icon)),
          if (show)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: uiPrimaryBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Uygun Saat Seçin',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<_GrupTuru>(
                  segments: const [
                    ButtonSegment(
                        value: _GrupTuru.hoca, label: Text('Antrenör')),
                    ButtonSegment(value: _GrupTuru.kort, label: Text('Kort')),
                  ],
                  selected: {_grup},
                  onSelectionChanged: (s) => setState(() => _grup = s.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: gruplu.length,
              itemBuilder: (_, i) {
                final baslik = gruplu.keys.elementAt(i);
                final liste = gruplu[baslik]!
                  ..sort((a, b) => a['baslangic_tarih_saat']
                      .compareTo(b['baslangic_tarih_saat']));

                return _GrupKart(
                  baslik: baslik,
                  altBaslik: _grup == _GrupTuru.hoca
                      ? 'Kortlara göre alternatifler'
                      : 'Antrenörlere göre alternatifler',
                  slotlar: liste,
                  onSelect: (secim) => Navigator.pop(context, secim),
                  slotStart: widget.slotStart,
                );
              },
            ),
          ),
        ],
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
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Text('${slotlar.length} seçenek',
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              altBaslik,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ...slotlar.map((a) {
              final bas = DateTime.parse(a['baslangic_tarih_saat']).toLocal();
              final bit = DateTime.parse(a['bitis_tarih_saat']).toLocal();
              final saatText = _formatSaat(bas, bit);
              final chipSol = a['kort_adi']?.toString() ?? '';
              final chipSag = a['antrenor_adi']?.toString() ?? '';

              return InkWell(
                onTap: () => onSelect(a),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 82,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          saatText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                      const Icon(Icons.chevron_right),
                    ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : scheme.secondaryContainer,
        border: outlined ? Border.all(color: scheme.outlineVariant) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: outlined
                  ? scheme.onSurfaceVariant
                  : scheme.onSecondaryContainer,
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
