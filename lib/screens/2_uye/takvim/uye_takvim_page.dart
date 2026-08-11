// lib/screens/5_etkinlik/takvim/ders_listesi_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/ders_degerlendirme_popup.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/ders_detay_popup.dart';
import 'package:fitcall/screens/1_common/takvim/hafta_gun_secici.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_ajanda.dart';
import 'package:fitcall/screens/1_common/takvim/takvim_zaman_cizelgesi.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/lesson_block.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/takvim_constants.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/common/tarih_util.dart';

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage>
    with SingleTickerProviderStateMixin {
  // Veri
  final List<EtkinlikModel> _tumDersler = [];
  final Set<DateTime> _yuklenenHaftalar = {};

  // Kullanıcı bilgileri
  UyeModel? _currentUye;
  int _userId = 0;

  // UI state
  bool _isLoading = false;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Hesaplanmış değerler
  Map<DateTime, int> _gunlukDersSayilari = {};
  List<EtkinlikModel> _selectedDayDersler = [];
  List<EtkinlikModel> _haftaDersleri = [];

  /// Üyenin asıl sorusu "sıradaki dersim ne zaman" olduğu için varsayılan
  /// görünüm ajanda; ızgaraya anahtarla geçilir (tercih oturum boyu kalır).
  bool _ajandaGorunumu = true;

  // Animasyon
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final now = simdiKulup();
    _focusedDay = now;
    _selectedDay = TimeUtils.normalizeDate(now);

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _initialize();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      _currentUye = await StorageService.uyeBilgileriniGetir();
      _userId = await SecureStorageService.getValue('user_id');

      await _loadWeek(TimeUtils.getWeekStart(_focusedDay));
      _recomputeCaches();

      setState(() => _isLoading = false);
      _animController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ShowMessage.error(context, 'Takvim yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _loadWeek(DateTime weekStart) async {
    final normalizedWeekStart = TimeUtils.normalizeDate(weekStart);
    if (_yuklenenHaftalar.contains(normalizedWeekStart)) return;
    _yuklenenHaftalar.add(normalizedWeekStart);

    final weekEnd = normalizedWeekStart.add(const Duration(days: 7));

    try {
      final response = await TakvimService.getUyeDersProramiApi(
        start: normalizedWeekStart,
        end: weekEnd,
      );

      final data = response.data;
      if (data == null) return;

      final existingIds = _tumDersler.map((d) => d.id).toSet();
      for (final ders in data.dersler) {
        if (!existingIds.contains(ders.id)) {
          _tumDersler.add(ders);
        }
      }
    } on ApiException catch (e) {
      debugPrint('API Hatası: ${e.message}');
    } catch (e) {
      debugPrint('Takvim yükleme hatası: $e');
    }
  }

  Future<void> _forceReloadCurrentWeek() async {
    setState(() => _isLoading = true);

    final weekStart = TimeUtils.getWeekStart(_focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 7));

    _tumDersler.removeWhere((d) =>
        !d.baslangicTarihSaat.isBefore(weekStart) &&
        d.baslangicTarihSaat.isBefore(weekEnd));
    _yuklenenHaftalar.remove(weekStart);

    await _loadWeek(weekStart);
    _recomputeCaches();

    setState(() => _isLoading = false);
  }

  void _recomputeCaches() {
    final weekStart = TimeUtils.getWeekStart(_focusedDay);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final selectedNormalized = TimeUtils.normalizeDate(_selectedDay);

    final counts = <DateTime, int>{};
    final selectedDersler = <EtkinlikModel>[];
    final haftaDersleri = <EtkinlikModel>[];

    for (final ders in _tumDersler) {
      final dersDay = TimeUtils.normalizeDate(ders.baslangicTarihSaat);

      // Hafta içindeyse say
      if (!dersDay.isBefore(weekStart) && dersDay.isBefore(weekEnd)) {
        counts[dersDay] = (counts[dersDay] ?? 0) + 1;
        haftaDersleri.add(ders);
      }

      // Seçili günse listeye ekle
      if (dersDay == selectedNormalized) {
        selectedDersler.add(ders);
      }
    }

    // Hafta günlerini ekle (ders olmasa bile)
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      counts.putIfAbsent(day, () => 0);
    }

    // Seçili günün derslerini sırala
    selectedDersler
        .sort((a, b) => a.baslangicTarihSaat.compareTo(b.baslangicTarihSaat));

    setState(() {
      _gunlukDersSayilari = counts;
      _selectedDayDersler = selectedDersler;
      _haftaDersleri = haftaDersleri;
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = TimeUtils.normalizeDate(day);
      _focusedDay = day;
    });
    _recomputeCaches();
  }

  Future<void> _onPageChanged(DateTime newFocusedDay) async {
    final newWeekStart = TimeUtils.getWeekStart(newFocusedDay);
    final oldWeekStart = TimeUtils.getWeekStart(_focusedDay);

    setState(() {
      _focusedDay = newFocusedDay;
      // Seçili günü yeni haftaya taşı (aynı gün indeksinde)
      final dayOffset = _selectedDay.weekday - 1;
      _selectedDay = newWeekStart.add(Duration(days: dayOffset));
    });

    if (newWeekStart != oldWeekStart) {
      setState(() => _isLoading = true);
      await _loadWeek(newWeekStart);
      _recomputeCaches();
      setState(() => _isLoading = false);
    } else {
      _recomputeCaches();
    }
  }

  void _onLessonTap(EtkinlikModel ders) {
    // İPTAL EDİLDİ KONTROLÜ KALDIRILDI - Artık iptal edilen derslere de tıklanabilir
    // İptal durumu popup içinde gösterilecek

    final isPast = ders.bitisTarihSaat.isBefore(simdiKulup());

    if (isPast) {
      // Geçmiş ders - değerlendirme popup'ı
      DersDegerlendirmePopup.show(
        context: context,
        ders: ders,
        userId: _userId,
        onSuccess: _forceReloadCurrentWeek,
      );
    } else {
      // Gelecek ders - detay popup'ı (iptal edilen dersler de dahil)
      if (_currentUye == null) {
        ShowMessage.error(context, 'Kullanıcı bilgisi bulunamadı');
        return;
      }

      DersDetayPopup.show(
        context: context,
        ders: ders,
        uyeId: _currentUye!.id,
        onSuccess: _forceReloadCurrentWeek,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Derslerim'),
        actions: [
          // Ajanda / Hafta anahtarı — ajanda "ne zaman", ızgara "günüm nasıl"
          // sorusuna cevap verir.
          IconButton(
            tooltip: _ajandaGorunumu ? 'Izgara görünümü' : 'Ajanda görünümü',
            onPressed: () => setState(() => _ajandaGorunumu = !_ajandaGorunumu),
            icon: Icon(_ajandaGorunumu
                ? Icons.calendar_view_day_rounded
                : Icons.view_agenda_rounded),
          ),
          IconButton(
            tooltip: 'Bugüne git',
            onPressed: () {
              final today = simdiKulup();
              _onPageChanged(today);
              _onDaySelected(today);
            },
            icon: const Icon(Icons.today_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Dersler yükleniyor...')
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  HaftaGunSecici(
                    selectedDay: _selectedDay,
                    focusedDay: _focusedDay,
                    lessonCounts: _gunlukDersSayilari,
                    onDaySelected: _onDaySelected,
                    onPageChanged: _onPageChanged,
                  ),
                  if (!_ajandaGorunumu) _buildDayHeader(Theme.of(context)),
                  Expanded(
                    child: _ajandaGorunumu
                        ? TakvimAjanda(
                            dersler: _haftaDersleri,
                            onLessonTap: _onLessonTap,
                          )
                        : TakvimZamanCizelgesi(
                            dersler: _selectedDayDersler,
                            selectedDay: _selectedDay,
                            onLessonTap: _onLessonTap,
                            blokYapici: (ders, onTap) =>
                                LessonBlock(ders: ders, onTap: onTap),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDayHeader(ThemeData theme) {
    final isToday = TimeUtils.isSameDay(_selectedDay, simdiKulup());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isToday
                  ? context.takvim.primary.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: isToday
                  ? context.takvim.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      TimeUtils.formatDateFull(_selectedDay),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.takvim.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Bugün',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedDayDersler.isEmpty
                      ? 'Ders bulunmuyor'
                      : '${_selectedDayDersler.length} ders',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedDayDersler.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.takvim.pending.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_tennis_rounded,
                    size: 14,
                    color: context.takvim.pending,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedDayDersler.length}',
                    style: TextStyle(
                      color: context.takvim.pending,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
