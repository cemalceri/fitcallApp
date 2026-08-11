// lib/screens/3_antrenor/takvim/antrenor_takvim_page.dart

import 'package:fitcall/common/tarih_util.dart';
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
import 'package:fitcall/screens/1_common/takvim/hafta_gun_secici.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_ajanda.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman_cizelgesi.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'widgets/takvim_constants.dart';
import 'widgets/lesson_approval_dialog.dart';
import 'widgets/lesson_block.dart';
import 'widgets/lesson_cancel_dialog.dart';
import 'widgets/lesson_devir_dialog.dart';

class AntrenorTakvimPage extends StatefulWidget {
  const AntrenorTakvimPage({super.key});

  @override
  State<AntrenorTakvimPage> createState() => _AntrenorTakvimPageState();
}

class _AntrenorTakvimPageState extends State<AntrenorTakvimPage> {
  bool _isLoading = false;
  DateTime _focusedDay = simdiKulup();
  DateTime _selectedDay = simdiKulup();

  final Set<DateTime> _yuklenenGunler = {};
  final Map<DateTime, List<EtkinlikModel>> _gunlukDersler = {};
  final Map<DateTime, int> _gunlukDersSayilari = {};

  bool _routeArgsIslendiMi = false;

  /// Antrenör gününü ızgarada görmek ister; ajanda isteğe bağlı.
  bool _ajandaGorunumu = false;

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
      final tarih = parseApiTarih(args['tarih']?.toString() ?? '');
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
    final today = TimeUtils.normalizeDate(simdiKulup());
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
    if (_ajandaGorunumu) _haftayiYukle();
  }

  /// Ajanda haftanın tamamını gösterir; ızgara gün gün yüklerken bu yedi günü
  /// birden ister.
  Future<void> _haftayiYukle() async {
    final basla = TimeUtils.getWeekStart(_focusedDay);
    setState(() => _isLoading = true);
    for (var i = 0; i < 7; i++) {
      await _loadDay(TimeUtils.normalizeDate(basla.add(Duration(days: i))));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<EtkinlikModel> _haftaDersleri() {
    final basla = TimeUtils.getWeekStart(_focusedDay);
    final liste = <EtkinlikModel>[];
    for (var i = 0; i < 7; i++) {
      liste.addAll(_gunlukDersler[
              TimeUtils.normalizeDate(basla.add(Duration(days: i)))] ??
          const []);
    }
    return liste;
  }

  void _gorunumDegistir() {
    setState(() => _ajandaGorunumu = !_ajandaGorunumu);
    if (_ajandaGorunumu) _haftayiYukle();
  }

  /// Ders bloğuna uzun basınca açılan bağlam menüsü: onay-iptal-devir tek
  /// dokunuşa iner (iOS/WhatsApp kalıbı).
  Future<void> _dersMenusu(EtkinlikModel ders) async {
    HapticFeedback.mediumImpact();
    if (ders.iptalMi) {
      await CancelledLessonInfoDialog.show(context: context, ders: ders);
      return;
    }

    final int userId = await SecureStorageService.getValue('user_id');
    if (!mounted) return;

    final gecmis = ders.bitisTarihSaat.isBefore(simdiKulup());

    await altSayfaGoster<void>(
      context,
      cocuk: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AltSayfaBasligi(
              ikon: Icons.sports_tennis_rounded,
              baslik: ders.kortAdi,
              altBaslik: '${TimeUtils.formatTime(ders.baslangicTarihSaat)} - '
                  '${TimeUtils.formatTime(ders.bitisTarihSaat)}',
            ),
            if (gecmis)
              ListTile(
                leading: const Icon(Icons.fact_check_rounded),
                title: const Text('Yoklama ve onay'),
                onTap: () {
                  Navigator.pop(context);
                  LessonApprovalDialog.show(
                    context: context,
                    ders: ders,
                    userId: userId,
                    onSuccess: _forceRefresh,
                  );
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Ders detayı'),
                onTap: () {
                  Navigator.pop(context);
                  FutureLessonDetailDialog.show(
                    context: context,
                    ders: ders,
                    userId: userId,
                    onSuccess: _forceRefresh,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Dersi devret'),
                onTap: () {
                  Navigator.pop(context);
                  LessonDevirDialog.show(
                    context: context,
                    ders: ders,
                    onSuccess: _forceRefresh,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.event_busy_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('İptal talebi'),
                onTap: () {
                  Navigator.pop(context);
                  LessonCancelDialog.show(
                    context: context,
                    ders: ders,
                    userId: userId,
                    onSuccess: _forceRefresh,
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
    final isPast = bitisSaati.isBefore(simdiKulup());

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
    final normalizedDay = TimeUtils.normalizeDate(_selectedDay);
    final selectedDersler = _gunlukDersler[normalizedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenör Takvimi'),
        actions: [
          IconButton(
            tooltip: _ajandaGorunumu ? 'Izgara görünümü' : 'Ajanda görünümü',
            onPressed: _gorunumDegistir,
            icon: Icon(_ajandaGorunumu
                ? Icons.calendar_view_day_rounded
                : Icons.view_agenda_rounded),
          ),
          IconButton(
            onPressed: _forceRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Hafta seçici
          HaftaGunSecici(
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
                : _ajandaGorunumu
                    ? TakvimAjanda(
                        dersler: _haftaDersleri(),
                        onLessonTap: _onLessonTap,
                        onLessonLongPress: _dersMenusu,
                      )
                    : TakvimZamanCizelgesi(
                        dersler: selectedDersler,
                        selectedDay: _selectedDay,
                        onLessonTap: _onLessonTap,
                        onLessonLongPress: _dersMenusu,
                        blokYapici: (ders, onTap) =>
                            LessonBlock(ders: ders, onTap: onTap),
                      ),
          ),
        ],
      ),
    );
  }
}
