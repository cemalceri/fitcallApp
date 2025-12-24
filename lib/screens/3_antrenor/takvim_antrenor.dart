// lib/screens/antrenor_takvim_page.dart
// ignore_for_file: use_build_context_synchronously, constant_identifier_names

import 'package:fitcall/models/dtos/ders_onay_bilgisi_dto.dart';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
import 'package:fitcall/models/enums.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/* -------------------------------------------------------------------------- */
/*                               Renk Sabitleri                                */
/* -------------------------------------------------------------------------- */
const Color uiPrimaryBlue = Color(0xFF2563EB);
const Color uiPrimaryLight = Color(0xFFDBEAFE);
const Color uiAccentGreen = Color(0xFF10B981);
const Color uiAccentOrange = Color(0xFFF59E0B);
const Color uiAccentRed = Color(0xFFEF4444);
const Color uiSurfaceLight = Color(0xFFFAFAFA);
const Color uiSlateGray = Color(0xFF64748B);

/* -------------------------------- Sayfa ----------------------------------- */
class AntrenorTakvimPage extends StatefulWidget {
  const AntrenorTakvimPage({super.key});
  @override
  State<AntrenorTakvimPage> createState() => _AntrenorTakvimPageState();
}

class _AntrenorTakvimPageState extends State<AntrenorTakvimPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.week;

  final Set<DateTime> _yuklenenGunler = {};
  final Map<DateTime, List<_TimeSlotItem>> _gunlukSlotlar = {};
  final List<EtkinlikModel> _tumDersler = [];

  static const int _basSaat = 7, _bitSaat = 23;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
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
    final today = _normalizeDate(DateTime.now());
    await _loadDay(today);
    setState(() => _isLoading = false);
    _animController.forward();
  }

  /* ------------------------------- API ------------------------------------ */
  Future<void> _loadDay(DateTime day00) async {
    if (_yuklenenGunler.contains(day00)) return;
    _yuklenenGunler.add(day00);

    final start = day00;
    final end = start.add(const Duration(days: 1));

    try {
      final r = await TakvimService.antrenorLoadDay(start: start, end: end);
      final WeekTakvimDataDto data =
          r.data ?? WeekTakvimDataDto(dersler: [], mesgul: [], uygun: []);

      _tumDersler.addAll(data.dersler);
      _processGun(day00, data);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Takvim alınamadı: $e');
    }
  }

  void _processGun(DateTime gun00, WeekTakvimDataDto data) {
    final List<_TimeSlotItem> slotlar = [];
    final now = DateTime.now();

    for (int saat = _basSaat; saat < _bitSaat; saat++) {
      final slotStart = gun00.add(Duration(hours: saat));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final isPast = slotEnd.isBefore(now);

      // Bu slotta ders var mı?
      final dersler = data.dersler
          .where((d) =>
              d.baslangicTarihSaat.isAtSameMomentAs(slotStart) ||
              (d.baslangicTarihSaat.isBefore(slotEnd) &&
                  d.bitisTarihSaat.isAfter(slotStart)))
          .toList();

      if (dersler.isNotEmpty) {
        for (final ders in dersler) {
          slotlar.add(_TimeSlotItem(
            baslangic: ders.baslangicTarihSaat,
            bitis: ders.bitisTarihSaat,
            tip: ders.iptalMi ? _SlotTip.iptal : _SlotTip.ders,
            ders: ders,
            antrenorAdi: ders.antrenorAdi,
            kortAdi: ders.kortAdi,
          ));
        }
        continue;
      }

      // Meşgul mi?
      final mesgul = data.mesgul.any(
          (m) => m.baslangic.isBefore(slotEnd) && m.bitis.isAfter(slotStart));

      if (isPast || mesgul) {
        slotlar.add(_TimeSlotItem(
          baslangic: slotStart,
          bitis: slotEnd,
          tip: _SlotTip.uygunDegil,
        ));
        continue;
      }

      // Uygun saatler
      final uygunlar = data.uygun
          .where((u) =>
              u.baslangic.isAtSameMomentAs(slotStart) &&
              u.bitis.isAtSameMomentAs(slotEnd))
          .toList();

      if (uygunlar.isNotEmpty) {
        slotlar.add(_TimeSlotItem(
          baslangic: slotStart,
          bitis: slotEnd,
          tip: _SlotTip.uygun,
          antrenorAdi: uygunlar.first.antrenorAdi,
          kortAdi: uygunlar.first.kortAdi,
        ));
      } else {
        slotlar.add(_TimeSlotItem(
          baslangic: slotStart,
          bitis: slotEnd,
          tip: _SlotTip.uygunDegil,
        ));
      }
    }

    _gunlukSlotlar[gun00] = slotlar;
  }

  /* ------------------------------ Helpers --------------------------------- */
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<DersOnayBilgisi?> _getirDersOnay(int dersId,
      {required int userId}) async {
    try {
      final res = await TakvimService.getDersYapildiBilgisiApi(
          dersId: dersId, userId: userId);
      final Map<String, dynamic>? data =
          (res.data is Map<String, dynamic>) ? res.data : null;
      if (data == null) return null;
      return DersOnayBilgisi.fromMap(data);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Ders onay bilgisi alınamadı: $e');
    }
    return null;
  }

  /* --------------------------------- UI ----------------------------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedSlotlar = _gunlukSlotlar[_normalizeDate(_selectedDay)] ?? [];

    // İstatistikler
    final dersSayisi =
        selectedSlotlar.where((s) => s.tip == _SlotTip.ders).length;
    final uygunSayisi =
        selectedSlotlar.where((s) => s.tip == _SlotTip.uygun).length;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : uiSurfaceLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Antrenör Takvimi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: uiPrimaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _forceRefresh,
              icon: const Icon(Icons.refresh_rounded, color: uiPrimaryBlue),
              tooltip: 'Yenile',
            ),
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
                            isSameDay(_selectedDay, day),
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
                          final normalized = _normalizeDate(selectedDay);

                          if (!_yuklenenGunler.contains(normalized)) {
                            setState(() => _isLoading = true);
                            await _loadDay(normalized);
                            setState(() => _isLoading = false);
                          }

                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final dayKey = _normalizeDate(date);
                            final slotlar = _gunlukSlotlar[dayKey] ?? [];

                            final dersSayisi = slotlar
                                .where((s) => s.tip == _SlotTip.ders)
                                .length;

                            if (dersSayisi == 0) return null;

                            return Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: uiAccentOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          uiAccentOrange.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gün başlığı ve istatistikler
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatGunBaslik(_selectedDay),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dersSayisi ders • $uygunSayisi boş saat',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dersSayisi > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: uiAccentOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sports_tennis_rounded,
                                    size: 16,
                                    color: uiAccentOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$dersSayisi',
                                    style: TextStyle(
                                      color: uiAccentOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Slot listesi
                  Expanded(
                    child: selectedSlotlar.isEmpty
                        ? Center(
                            child: _EmptyStateCard(
                              icon: Icons.event_busy_rounded,
                              title: 'Veri Yok',
                              message: 'Bu gün için henüz veri yüklenmedi.',
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: selectedSlotlar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final slot = selectedSlotlar[i];
                              return _SlotCard(
                                slot: slot,
                                onTap: slot.tip == _SlotTip.ders
                                    ? () => _onSlotTap(slot)
                                    : null,
                              );
                            },
                          ),
                  ),

                  // Legend
                  const _LegendBar(),
                ],
              ),
            ),
    );
  }

  Future<void> _forceRefresh() async {
    final day = _normalizeDate(_selectedDay);
    _yuklenenGunler.remove(day);
    _gunlukSlotlar.remove(day);
    setState(() => _isLoading = true);
    await _loadDay(day);
    setState(() => _isLoading = false);
  }

  /* ------------------------------ Tap handler ------------------------------ */
  Future<void> _onSlotTap(_TimeSlotItem slot) async {
    if (slot.tip != _SlotTip.ders || slot.ders == null) return;

    final ders = slot.ders!;
    final now = DateTime.now();
    final isPast = ders.bitisTarihSaat.isBefore(now);

    if (ders.iptalMi) {
      ShowMessage.error(context, 'Bu ders iptal edilmiş.');
      return;
    }

    final int userId = await SecureStorageService.getValue('user_id');
    final mevcut = await _getirDersOnay(ders.id, userId: userId);

    if (isPast) {
      _showTamamlamaPopup(
        ders,
        initialTamamlandi: mevcut?.tamamlandi,
        initialReasonCode: mevcut?.nedenKodu,
        initialAciklama: mevcut?.aciklama,
        onSaved: (tamamlandi, reasonCode, notMetni, reasonLabel) async {
          try {
            final r = await TakvimService.setDersYapildiBilgisiApi(
              dersId: ders.id,
              userId: userId,
              rol: 'ANTRENOR',
              tamamlandi: tamamlandi,
              aciklama: notMetni ?? '',
              onayRedIptalNedeni: reasonCode,
            );
            ShowMessage.success(context, r.mesaj);
            await _forceRefresh();
          } on ApiException catch (e) {
            ShowMessage.error(context, e.message);
          } catch (e) {
            ShowMessage.error(context, 'Hata: $e');
          }
        },
      );
    } else {
      _showIptalPopup(
        ders,
        initialReasonCode: mevcut?.nedenKodu,
        initialAciklama: mevcut?.aciklama,
        onCancelled: (reasonCode, notMetni, reasonLabel) async {
          final aciklama =
              '${reasonLabel ?? ''}${(notMetni?.isNotEmpty ?? false) ? ' - ${notMetni!.trim()}' : ''}';
          try {
            final res = await TakvimService.antrenorDersIptal(
                dersId: ders.id, aciklama: aciklama);
            ShowMessage.success(context, res.mesaj);
            await _forceRefresh();
          } on ApiException catch (e) {
            ShowMessage.error(context, e.message);
          } catch (e) {
            ShowMessage.error(context, 'Hata: $e');
          }
        },
      );
    }
  }

  /* ---------------- Geçmiş ders – tamamlama popup ------------------------- */
  void _showTamamlamaPopup(
    EtkinlikModel ders, {
    bool? initialTamamlandi,
    String? initialReasonCode,
    String? initialAciklama,
    required void Function(bool tamamlandi, String reasonCode, String? notMetni,
            String? reasonLabel)
        onSaved,
  }) {
    bool tamamlandi = initialTamamlandi ?? true;
    List<ReasonOption> aktifListe = tamamlandi
        ? OnayRedIptalNedeniEnums.yapildi
        : OnayRedIptalNedeniEnums.yapilmadi;

    final initOpt = OnayRedIptalNedeniEnums.findByKod(initialReasonCode);
    if (initOpt != null) {
      if (OnayRedIptalNedeniEnums.yapildi.any((o) => o.kod == initOpt.kod)) {
        tamamlandi = true;
        aktifListe = OnayRedIptalNedeniEnums.yapildi;
      } else if (OnayRedIptalNedeniEnums.yapilmadi
          .any((o) => o.kod == initOpt.kod)) {
        tamamlandi = false;
        aktifListe = OnayRedIptalNedeniEnums.yapilmadi;
      }
    }
    String seciliKod = initOpt?.kod ?? aktifListe.first.kod;
    final ctrl = TextEditingController(text: initialAciklama ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Katılımcılar
                if (ders.uyeList.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: uiPrimaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_rounded,
                                size: 16, color: uiPrimaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Katılımcılar (${ders.uyeList.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: uiPrimaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ders.uyeList
                              .map((u) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: uiPrimaryBlue.withValues(
                                              alpha: 0.2)),
                                    ),
                                    child: Text(
                                      u.adSoyad,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Ders yapıldı mı?'),
                    value: tamamlandi,
                    onChanged: (v) {
                      setS(() {
                        tamamlandi = v;
                        aktifListe = v
                            ? OnayRedIptalNedeniEnums.yapildi
                            : OnayRedIptalNedeniEnums.yapilmadi;
                        seciliKod = aktifListe.first.kod;
                      });
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: seciliKod,
                  items: aktifListe
                      .map((o) =>
                          DropdownMenuItem(value: o.kod, child: Text(o.etiket)))
                      .toList(),
                  onChanged: (v) =>
                      setS(() => seciliKod = v ?? aktifListe.first.kod),
                  decoration: InputDecoration(
                    labelText: 'Sebep',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Not (isteğe bağlı)',
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: uiPrimaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Kaydet'),
              onPressed: () {
                final lbl =
                    OnayRedIptalNedeniEnums.findByKod(seciliKod)?.etiket;
                onSaved(tamamlandi, seciliKod, ctrl.text.trim(), lbl);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- Gelecek ders – iptal popup ---------------------------- */
  void _showIptalPopup(
    EtkinlikModel ders, {
    String? initialReasonCode,
    String? initialAciklama,
    required void Function(
            String reasonCode, String? notMetni, String? reasonLabel)
        onCancelled,
  }) {
    String seciliKod =
        initialReasonCode ?? OnayRedIptalNedeniEnums.iptal.first.kod;
    if (!OnayRedIptalNedeniEnums.iptal.any((o) => o.kod == seciliKod)) {
      seciliKod = OnayRedIptalNedeniEnums.iptal.first.kod;
    }
    final ctrl = TextEditingController(text: initialAciklama ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: uiAccentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cancel_rounded, color: uiAccentRed, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Dersi İptal Et'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Katılımcılar
                if (ders.uyeList.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: uiPrimaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_rounded,
                                size: 16, color: uiPrimaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Katılımcılar (${ders.uyeList.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: uiPrimaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: ders.uyeList
                              .map((u) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: uiPrimaryBlue.withValues(
                                              alpha: 0.2)),
                                    ),
                                    child: Text(
                                      u.adSoyad,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                DropdownButtonFormField<String>(
                  initialValue: seciliKod,
                  items: OnayRedIptalNedeniEnums.iptal
                      .map((o) =>
                          DropdownMenuItem(value: o.kod, child: Text(o.etiket)))
                      .toList(),
                  onChanged: (v) => setS(() =>
                      seciliKod = v ?? OnayRedIptalNedeniEnums.iptal.first.kod),
                  decoration: InputDecoration(
                    labelText: 'Sebep',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Not (isteğe bağlı)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: uiAccentRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('İptal Et'),
              onPressed: () {
                final lbl =
                    OnayRedIptalNedeniEnums.findByKod(seciliKod)?.etiket;
                onCancelled(seciliKod, ctrl.text.trim(), lbl);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Slot Card Widget                               */
/* -------------------------------------------------------------------------- */
class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    this.onTap,
  });

  final _TimeSlotItem slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final saatStr = _formatSaat(slot.baslangic, slot.bitis);

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String? subtitle;
    List<String> katilimcilar = [];

    switch (slot.tip) {
      case _SlotTip.uygun:
        bgColor = uiAccentGreen.withValues(alpha: 0.08);
        borderColor = uiAccentGreen.withValues(alpha: 0.3);
        textColor = uiAccentGreen;
        icon = Icons.check_circle_rounded;
        title = 'Boş Saat';
        subtitle = [slot.kortAdi, slot.antrenorAdi]
            .where((s) => s != null && s.isNotEmpty)
            .join(' • ');
        break;

      case _SlotTip.ders:
        bgColor = uiPrimaryBlue.withValues(alpha: 0.08);
        borderColor = uiPrimaryBlue.withValues(alpha: 0.3);
        textColor = uiPrimaryBlue;
        icon = Icons.sports_tennis_rounded;
        title = 'Ders';
        subtitle = [slot.kortAdi, slot.ders?.seviye]
            .where((s) => s != null && s.isNotEmpty)
            .join(' • ');
        katilimcilar = slot.ders?.uyeList.map((u) => u.adSoyad).toList() ?? [];
        break;

      case _SlotTip.iptal:
        bgColor = uiAccentRed.withValues(alpha: 0.08);
        borderColor = uiAccentRed.withValues(alpha: 0.3);
        textColor = uiAccentRed;
        icon = Icons.cancel_rounded;
        title = 'İptal Edildi';
        subtitle = null;
        break;

      case _SlotTip.uygunDegil:
        bgColor = uiSlateGray.withValues(alpha: 0.06);
        borderColor = uiSlateGray.withValues(alpha: 0.15);
        textColor = uiSlateGray;
        icon = Icons.block_rounded;
        title = 'Mesai Dışı';
        subtitle = null;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saat kutusu
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  saatStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (katilimcilar.isNotEmpty) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: textColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_rounded,
                                    size: 12, color: textColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${katilimcilar.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    // Katılımcı isimleri
                    if (katilimcilar.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: katilimcilar
                            .map((isim) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            textColor.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isim,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: textColor, size: 22),
              ],
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Legend Bar ---------------------------------- */
class _LegendBar extends StatelessWidget {
  const _LegendBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(context, uiPrimaryBlue, 'Ders'),
              _legendItem(context, uiAccentGreen, 'Boş'),
              _legendItem(context, uiAccentRed, 'İptal'),
              _legendItem(context, uiSlateGray, 'Mesai Dışı'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             Data Models                                     */
/* -------------------------------------------------------------------------- */
enum _SlotTip { uygun, ders, iptal, uygunDegil }

class _TimeSlotItem {
  final DateTime baslangic;
  final DateTime bitis;
  final _SlotTip tip;
  final EtkinlikModel? ders;
  final String? antrenorAdi;
  final String? kortAdi;

  _TimeSlotItem({
    required this.baslangic,
    required this.bitis,
    required this.tip,
    this.ders,
    this.antrenorAdi,
    this.kortAdi,
  });
}

/* -------------------------------------------------------------------------- */
/*                             Format Helpers                                  */
/* -------------------------------------------------------------------------- */
String _formatSaat(DateTime bas, DateTime bit) {
  String f(int v) => v.toString().padLeft(2, '0');
  return '${f(bas.hour)}:${f(bas.minute)}';
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
