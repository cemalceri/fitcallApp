// lib/screens/3_antrenor/takvim/antrenor_takvim_page.dart

import 'package:fitcall/models/dtos/takvim_dtos/week_takvim_data_dto.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/cancelled_lesson_info_dialog.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/future_lesson_detail_dialog.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/takvim_constants.dart';
import 'widgets/week_day_selector.dart';
import 'widgets/timeline_view.dart';
import 'widgets/lesson_approval_dialog.dart';

class AntrenorTakvimPage extends StatefulWidget {
  const AntrenorTakvimPage({super.key});

  @override
  State<AntrenorTakvimPage> createState() => _AntrenorTakvimPageState();
}

class _AntrenorTakvimPageState extends State<AntrenorTakvimPage> {
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Set<DateTime> _yuklenenGunler = {};
  final Map<DateTime, List<EtkinlikModel>> _gunlukDersler = {};
  final Map<DateTime, int> _gunlukDersSayilari = {};

  bool _routeArgsIslendiMi = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsIslendiMi) return;
    _routeArgsIslendiMi = true;

    // Bildirim yönlendirmesi: {tarih: 'YYYY-MM-DD', ders_id: int} argümanıyla
    // gelinirse ilgili günü açıp dersin dialogunu gösterir
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final tarih = DateTime.tryParse(args['tarih']?.toString() ?? '');
      final dersId = int.tryParse(args['ders_id']?.toString() ?? '');
      if (tarih != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _gunAcVeDersGoster(tarih, dersId);
        });
      }
    }
  }

  Future<void> _gunAcVeDersGoster(DateTime tarih, int? dersId) async {
    await _onDaySelected(tarih);
    if (dersId == null || !mounted) return;

    final dersler = _gunlukDersler[TimeUtils.normalizeDate(tarih)] ?? const [];
    for (final ders in dersler) {
      if (ders.id == dersId) {
        await _onLessonTap(ders);
        break;
      }
    }
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    final today = TimeUtils.normalizeDate(DateTime.now());
    await _loadDay(today);
    setState(() => _isLoading = false);
  }

  /* ------------------------------- API ------------------------------------ */
  Future<void> _loadDay(DateTime day00) async {
    if (_yuklenenGunler.contains(day00)) return;
    _yuklenenGunler.add(day00);

    final start = day00;

    try {
      final antrenorBilgi = await StorageService.antrenorBilgileriniGetir();

      final r = await AntrenorApiService.antrenorLoadDay(
        start: start,
        antrenorId: antrenorBilgi?.id,
      );

      final AntrenorTakvimDataDto data =
          r.data ?? AntrenorTakvimDataDto(dersler: []);

      // Dersleri kaydet
      final dersler = data.dersler;

      _gunlukDersler[day00] = dersler;
      _gunlukDersSayilari[day00] = dersler.where((d) => !d.iptalMi).length;
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      if (mounted) ShowMessage.error(context, 'Takvim alınamadı: $e');
    }
  }

  Future<void> _forceRefresh() async {
    HapticFeedback.lightImpact();
    final day = TimeUtils.normalizeDate(_selectedDay);
    _yuklenenGunler.remove(day);
    _gunlukDersler.remove(day);
    _gunlukDersSayilari.remove(day);
    setState(() => _isLoading = true);
    await _loadDay(day);
    setState(() => _isLoading = false);
  }

  /* ------------------------------- Handlers ------------------------------- */
  Future<void> _onDaySelected(DateTime selectedDay) async {
    final normalized = TimeUtils.normalizeDate(selectedDay);

    if (!_yuklenenGunler.contains(normalized)) {
      setState(() => _isLoading = true);
      await _loadDay(normalized);
      setState(() => _isLoading = false);
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = selectedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
  }

  Future<void> _onLessonTap(EtkinlikModel ders) async {
    HapticFeedback.selectionClick();

    // İptal edilmiş ders
    if (ders.iptalMi) {
      CancelledLessonInfoDialog.show(
        context: context,
        ders: ders,
      );
      return;
    }

    // User ID al
    final int userId = await SecureStorageService.getValue('user_id');

    // Geçmiş mi gelecek mi?
    final bitisSaati = DateTime(
      ders.bitisTarihSaat.year,
      ders.bitisTarihSaat.month,
      ders.bitisTarihSaat.day,
      ders.bitisTarihSaat.hour,
      ders.bitisTarihSaat.minute,
    );
    final isPast = bitisSaati.isBefore(DateTime.now());

    if (!mounted) return;

    if (isPast) {
      // Geçmiş ders — onay dialog'u
      LessonApprovalDialog.show(
        context: context,
        ders: ders,
        userId: userId,
        onSuccess: _forceRefresh,
      );
      return;
    }

    // Gelecek ders — detay + aksiyon dialog'u
    FutureLessonDetailDialog.show(
      context: context,
      ders: ders,
      userId: userId,
      onSuccess: _forceRefresh,
    );
  }

  /* --------------------------------- UI ----------------------------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final normalizedDay = TimeUtils.normalizeDate(_selectedDay);
    final selectedDersler = _gunlukDersler[normalizedDay] ?? [];

    return Scaffold(
      backgroundColor:
          isDark ? theme.colorScheme.surface : TakvimColors.surface,
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
              color: TakvimColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _forceRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: TakvimColors.primary),
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hafta seçici
          WeekDaySelector(
            selectedDay: _selectedDay,
            focusedDay: _focusedDay,
            lessonCounts: _gunlukDersSayilari,
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
          ),

          // Timeline
          Expanded(
            child: _isLoading
                ? const LoadingSpinnerWidget(message: 'Yükleniyor...')
                : TimelineView(
                    dersler: selectedDersler,
                    selectedDay: _selectedDay,
                    onLessonTap: _onLessonTap,
                  ),
          ),
        ],
      ),
    );
  }
}
