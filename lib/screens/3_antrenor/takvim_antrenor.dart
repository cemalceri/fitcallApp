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
const Color dersDoluRenk = Colors.grey;
const Color uygunSaatRenk = Colors.white;
const Color uygunOlmayanRenk = Color.fromARGB(255, 233, 240, 255);
const Color uiPrimaryBlue = Color(0xFF2F6FED);

/* -------------------------------- Sayfa ----------------------------------- */
class AntrenorTakvimPage extends StatefulWidget {
  const AntrenorTakvimPage({super.key});
  @override
  State<AntrenorTakvimPage> createState() => _AntrenorTakvimPageState();
}

class _AntrenorTakvimPageState extends State<AntrenorTakvimPage> {
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.week;

  final Set<DateTime> _yuklenenGunler = {};
  final Map<DateTime, List<_TimeSlotItem>> _gunlukSlotlar = {};
  final List<EtkinlikModel> _tumDersler = [];

  static const int _basSaat = 7, _bitSaat = 23;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    final today = _normalizeDate(DateTime.now());
    await _loadDay(today);
    setState(() => _isLoading = false);
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

    // 7:00 - 23:00 arası her saat için slot oluştur
    for (int saat = _basSaat; saat < _bitSaat; saat++) {
      final slotStart = gun00.add(Duration(hours: saat));
      final slotEnd = slotStart.add(const Duration(hours: 1));

      // Geçmiş mi?
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

  /* --------------- Onay bilgisini backend'den çek ------------------------- */
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
    final selectedSlotlar = _gunlukSlotlar[_normalizeDate(_selectedDay)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenör Takvimi')),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : Column(
              children: [
                // Table Calendar
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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

                        final dersSayisi =
                            slotlar.where((s) => s.tip == _SlotTip.ders).length;

                        if (dersSayisi == 0) return null;

                        return Positioned(
                          bottom: 2,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Gün başlığı
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _formatGunBaslik(_selectedDay),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Slot listesi
                Expanded(
                  child: selectedSlotlar.isEmpty
                      ? Center(
                          child: Text(
                            'Bu gün için ders yok',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: selectedSlotlar.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final slot = selectedSlotlar[i];
                            return _buildSlotCard(slot);
                          },
                        ),
                ),

                // Legend
                const _LegendBar(),
              ],
            ),
    );
  }

  Widget _buildSlotCard(_TimeSlotItem slot) {
    final saatStr = _formatSaat(slot.baslangic, slot.bitis);

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;
    String subtitle = '';
    bool isClickable = false;

    switch (slot.tip) {
      case _SlotTip.uygun:
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        subtitle = '${slot.kortAdi ?? ''} • ${slot.antrenorAdi ?? ''}';
        break;

      case _SlotTip.ders:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        borderColor = Colors.blue;
        textColor = Colors.blue.shade700;
        icon = Icons.sports_tennis;
        subtitle = '${slot.kortAdi ?? ''} • ${slot.ders?.seviye ?? ''}';
        isClickable = true;
        break;

      case _SlotTip.iptal:
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        subtitle = 'İptal edildi';
        break;

      case _SlotTip.uygunDegil:
        bgColor = uygunOlmayanRenk.withValues(alpha: 0.3);
        borderColor = Colors.grey;
        textColor = Colors.black54;
        icon = Icons.block;
        subtitle = 'Uygun değil';
        break;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isClickable ? () => _onSlotTap(slot) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Saat
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  saatStr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // İkon ve bilgi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...[
                          Icon(icon, size: 20, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            _slotBaslik(slot),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (isClickable)
                Icon(
                  Icons.chevron_right,
                  color: textColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _slotBaslik(_TimeSlotItem slot) {
    switch (slot.tip) {
      case _SlotTip.uygun:
        return 'Uygun Saat';
      case _SlotTip.ders:
        return 'Ders';
      case _SlotTip.iptal:
        return 'İptal Edildi';
      case _SlotTip.uygunDegil:
        return 'Uygun Değil';
    }
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
            // Refresh
            final day = _normalizeDate(_selectedDay);
            _yuklenenGunler.remove(day);
            _gunlukSlotlar.remove(day);
            setState(() => _isLoading = true);
            await _loadDay(day);
            setState(() => _isLoading = false);
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
            // Refresh
            final day = _normalizeDate(_selectedDay);
            _yuklenenGunler.remove(day);
            _gunlukSlotlar.remove(day);
            setState(() => _isLoading = true);
            await _loadDay(day);
            setState(() => _isLoading = false);
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
                title: const Text('Ders Değerlendirme'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  SwitchListTile(
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
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: seciliKod,
                    items: aktifListe
                        .map((o) => DropdownMenuItem(
                            value: o.kod, child: Text(o.etiket)))
                        .toList(),
                    onChanged: (v) =>
                        setS(() => seciliKod = v ?? aktifListe.first.kod),
                    decoration: const InputDecoration(
                        labelText: 'Sebep',
                        border: OutlineInputBorder(),
                        isDense: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: ctrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Not (isteğe bağlı)',
                          border: OutlineInputBorder())),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat')),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet'),
                      onPressed: () {
                        final lbl = OnayRedIptalNedeniEnums.findByKod(seciliKod)
                            ?.etiket;
                        onSaved(tamamlandi, seciliKod, ctrl.text.trim(), lbl);
                        Navigator.pop(context);
                      }),
                ],
              ),
            ));
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
                title: const Text('Dersi İptal Et'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    initialValue: seciliKod,
                    items: OnayRedIptalNedeniEnums.iptal
                        .map((o) => DropdownMenuItem(
                            value: o.kod, child: Text(o.etiket)))
                        .toList(),
                    onChanged: (v) => setS(() => seciliKod =
                        v ?? OnayRedIptalNedeniEnums.iptal.first.kod),
                    decoration: const InputDecoration(
                        labelText: 'Sebep',
                        border: OutlineInputBorder(),
                        isDense: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: ctrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Not (isteğe bağlı)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 4),
                  const Text('* Bu işlem geri alınamaz.',
                      style: TextStyle(fontSize: 12)),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Vazgeç')),
                  ElevatedButton(
                      child: const Text('İptal Et'),
                      onPressed: () {
                        final lbl = OnayRedIptalNedeniEnums.findByKod(seciliKod)
                            ?.etiket;
                        onCancelled(seciliKod, ctrl.text.trim(), lbl);
                        Navigator.pop(context);
                      }),
                ],
              ),
            ));
  }
}

/* --------------------------- Legend Bar ---------------------------------- */
class _LegendBar extends StatelessWidget {
  const _LegendBar();

  Widget _pill(BuildContext context, Color c, String t,
          {bool border = false}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
                border: border ? Border.all(color: Colors.black54) : null)),
        Text(t, style: Theme.of(context).textTheme.bodyMedium),
      ]);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _pill(context, dersDoluRenk, 'Dolu ders', border: true),
                    _pill(context, uygunSaatRenk, 'Uygun saat'),
                    _pill(context, uygunOlmayanRenk, 'Uygun olmayan'),
                  ]),
            )));
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
  return '${f(bas.hour)}:${f(bas.minute)} – ${f(bit.hour)}:${f(bit.minute)}';
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
