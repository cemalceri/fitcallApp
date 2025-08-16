// lib/screens/5_etkinlik/antrenor_takvim_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/* -------------------------------------------------------------------------- */
/*                               Renk Sabitleri                                */
/* -------------------------------------------------------------------------- */
const Color dersDoluRenk = Colors.grey; // Takvimdeki dolu ders
const Color uygunSaatRenk = Colors.white; // Uygun (available) saat
const Color uygunOlmayanRenk =
    Color.fromARGB(255, 233, 240, 255); // Uygun olmayan slot/past (arka plan)

/* -------------------------------------------------------------------------- */
/*                                Sayfa                                        */
/* -------------------------------------------------------------------------- */
class AntrenorTakvimPage extends StatefulWidget {
  const AntrenorTakvimPage({super.key});

  @override
  State<AntrenorTakvimPage> createState() => _AntrenorTakvimPageState();
}

class _AntrenorTakvimPageState extends State<AntrenorTakvimPage> {
  // Data
  EtkinlikDataSource _dataSource = EtkinlikDataSource(const []);
  final List<Appointment> _tumRandevular = [];
  bool _isLoading = false;

  // Gün yükleme/region state
  final Set<DateTime> _yuklenenGunler = {};
  final Map<DateTime, List<TimeRegion>> _gunBusyRegions =
      {}; // API'den gelen busy
  List<TimeRegion> _regions = [];

  // Saat aralığı (görünüm)
  static const int _basSaat = 7;
  static const int _bitSaat = 23;

  // Sebep listeleri
  final List<String> _sebepYapildi = const [
    'Planlandığı gibi yapıldı',
    'Telafi/ek ders yapıldı',
    'Deneme dersi yapıldı',
  ];
  final List<String> _sebepYapilmadi = const [
    'Öğrenci gelmedi',
    'Antrenör mazeretli',
    'Hava şartları',
    'Kort müsait değil',
    'Diğer',
  ];
  final List<String> _sebepIptal = const [
    'Program değişikliği',
    'Hava koşulları',
    'Kort bakımı',
    'Öğrenci talebi',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    final today = _gun00(DateTime.now());
    await _loadDay(today);
    _rebuildRegionsForVisible(today);
    setState(() => _isLoading = false);
  }

  /* -------------------------------------------------------------------------- */
  /*                                API çağrısı                                 */
  /* -------------------------------------------------------------------------- */
  Future<void> _loadDay(DateTime day00) async {
    if (_yuklenenGunler.contains(day00)) return;
    _yuklenenGunler.add(day00);

    final start = day00; // 00:00
    final end = start.add(const Duration(days: 1));

    try {
      // Gün verilerini tek istekle çekiyoruz (dersler + uygun + meşgul)
      final r = await TakvimService.antrenorLoadDay(start: start, end: end);
      final WeekTakvimDataDto data =
          r.data ?? WeekTakvimDataDto(dersler: [], mesgul: [], uygun: []);

      // --- DERSLER ---
      final dersAppts = data.dersler.map(_dersToAppt).toList();

      // --- UYGUN (available) ---
      final Set<String> availKeys = {};
      final List<Appointment> availableAppts = [];
      for (final s in data.uygun) {
        final key = s.baslangic.toUtc().toIso8601String();
        if (availKeys.add(key)) {
          availableAppts.add(
            Appointment(
              id: 'available-$key',
              startTime: s.baslangic,
              endTime: s.bitis,
              subject: '', // metin yok
              notes: jsonEncode({
                'tip': 'available',
                'baslangic': key,
                'bitis': s.bitis.toUtc().toIso8601String(),
                'antrenor_id': s.antrenorId,
                'antrenor_adi': s.antrenorAdi,
                'kort_id': s.kortId,
                'kort_adi': s.kortAdi,
              }),
              color: uygunSaatRenk.withAlpha((0.28 * 255).toInt()),
            ),
          );
        }
      }

      // --- BUSY → TimeRegion olarak sakla ---
      final List<TimeRegion> busyRegions = [];
      final Set<String> busyKeys = {};
      for (final s in data.mesgul) {
        final key =
            '${s.baslangic.toUtc().toIso8601String()}_${s.bitis.toUtc().toIso8601String()}';
        if (!busyKeys.add(key)) continue;
        busyRegions.add(TimeRegion(
          startTime: s.baslangic,
          endTime: s.bitis,
          enablePointerInteraction: false,
          color: uygunOlmayanRenk,
        ));
      }
      _gunBusyRegions[day00] = busyRegions;

      // Topla
      _tumRandevular.addAll(dersAppts);
      _tumRandevular.addAll(availableAppts);

      // Ekrana bas
      setState(() {
        _dataSource =
            EtkinlikDataSource(List<Appointment>.from(_tumRandevular));
      });
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Takvim alınamadı: $e');
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               Helpers                                      */
  /* -------------------------------------------------------------------------- */
  DateTime _gun00(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _gunBas(DateTime d) =>
      DateTime(d.year, d.month, d.day, _basSaat, 0, 0, 0, 0);
  DateTime _gunBit(DateTime d) =>
      DateTime(d.year, d.month, d.day, _bitSaat, 0, 0, 0, 0);

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

  Map<String, dynamic> _safeNotes(Appointment a) {
    try {
      return (jsonDecode(a.notes ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {
      return const {};
    }
  }

  void _rebuildRegionsForVisible(DateTime visibleDay) {
    final day00 = _gun00(visibleDay);
    final now = DateTime.now();

    // 1) Günün geçmiş kısmını boya
    final List<TimeRegion> past = [];
    final dayStart = _gunBas(day00);
    final dayEnd = _gunBit(day00);

    if (dayEnd.isBefore(now)) {
      // Tüm gün geçmiş
      past.add(TimeRegion(
        startTime: dayStart,
        endTime: dayEnd,
        enablePointerInteraction: false,
        color: uygunOlmayanRenk,
      ));
    } else if (!dayStart.isAfter(now)) {
      // Günün bir kısmı geçmiş (07:00 → now)
      past.add(TimeRegion(
        startTime: dayStart,
        endTime: now,
        enablePointerInteraction: false,
        color: uygunOlmayanRenk,
      ));
    }

    // 2) API'den gelen busy bölgeleri ekle
    final busy = _gunBusyRegions[day00] ?? const [];

    setState(() => _regions = [...past, ...busy]);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrenör Takvimi')),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : Column(
              children: [
                Expanded(
                  child: SfCalendar(
                    view: CalendarView.day,
                    dataSource: _dataSource,
                    firstDayOfWeek: 1,
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      startHour: 7.0,
                      endHour: 23.0,
                      timeInterval: Duration(minutes: 60),
                    ),
                    specialRegions: _regions,
                    onTap: _onTap,
                    onViewChanged: (ViewChangedDetails d) async {
                      if (d.visibleDates.isEmpty) return;
                      final day = _gun00(d.visibleDates.first);
                      await _loadDay(day);
                      _rebuildRegionsForVisible(day);
                    },
                  ),
                ),
                const _LegendBar(),
              ],
            ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                Tap handler                                 */
  /* -------------------------------------------------------------------------- */
  void _onTap(CalendarTapDetails d) async {
    if (d.appointments == null || d.appointments!.isEmpty) return;

    final Appointment appt = d.appointments!.first;
    final note = _safeNotes(appt);
    final tip = note['tip'];

    // Available veya busy seçimi ile işlem yok
    if (tip == 'available') return;

    if (tip != 'ders') return;

    final EtkinlikModel ders =
        EtkinlikModel.fromMap(note.cast<String, dynamic>());
    final now = DateTime.now();
    final isPast = ders.bitisTarihSaat.isBefore(now);

    if (ders.iptalMi) {
      ShowMessage.error(context, 'Bu ders iptal edilmiş.');
      return;
    }

    if (isPast) {
      _showTamamlamaPopup(ders, onSaved: (tamamlandi, sebep, notMetni) async {
        final aciklama =
            'Sebep: $sebep${notMetni.isNotEmpty ? ' - $notMetni' : ''}';
        try {
          final r = await TakvimService.dersYapildiBilgisi(
            dersId: ders.id,
            tamamlandi: tamamlandi,
            aciklama: aciklama,
          );
          // Görünümü tazelemek için basit renk güncellemesi:
          appt.color = dersDoluRenk; // ders zaten dolu tipinde
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
          ShowMessage.success(context, r.mesaj);
        } on ApiException catch (e) {
          ShowMessage.error(context, e.message);
        } catch (e) {
          ShowMessage.error(context, 'Hata: $e');
        }
      });
    } else {
      _showIptalPopup(ders, onCancelled: (sebep, notMetni) async {
        final aciklama =
            'Sebep: $sebep${notMetni.isNotEmpty ? ' - $notMetni' : ''}';
        try {
          // Not: Projenizde metod adı farklıysa (örn. dersIptal) burayı değiştirin.
          final res = await TakvimService.antrenorDersIptal(
            dersId: ders.id,
            aciklama: aciklama,
          );
          appt.color = uygunOlmayanRenk;
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
          ShowMessage.success(context, res.mesaj);
        } on ApiException catch (e) {
          ShowMessage.error(context, e.message);
        } catch (e) {
          ShowMessage.error(context, 'Hata: $e');
        }
      });
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                    Geçmiş ders – tamamlama popup                           */
  /* -------------------------------------------------------------------------- */
  void _showTamamlamaPopup(
    EtkinlikModel ders, {
    required void Function(bool tamamlandi, String sebep, String notMetni)
        onSaved,
  }) {
    bool tamamlandi = true;
    String? seciliSebep = _sebepYapildi.first;
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          title: const Text('Ders Değerlendirme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Ders yapıldı mı?'),
                value: tamamlandi,
                onChanged: (v) {
                  setS(() {
                    tamamlandi = v;
                    // Sebep listesini hemen değiştir
                    final list = v ? _sebepYapildi : _sebepYapilmadi;
                    seciliSebep =
                        (seciliSebep != null && list.contains(seciliSebep))
                            ? seciliSebep
                            : list.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: seciliSebep,
                items: (tamamlandi ? _sebepYapildi : _sebepYapilmadi)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setS(() => seciliSebep = v),
                decoration: const InputDecoration(
                  labelText: 'Sebep',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Not (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              onPressed: () {
                onSaved(tamamlandi, seciliSebep ?? '', ctrl.text.trim());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                     Gelecek ders – iptal popup                             */
  /* -------------------------------------------------------------------------- */
  void _showIptalPopup(
    EtkinlikModel ders, {
    required void Function(String sebep, String notMetni) onCancelled,
  }) {
    String seciliSebep = _sebepIptal.first;
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dersi İptal Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: seciliSebep,
              items: _sebepIptal
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => seciliSebep = v ?? _sebepIptal.first,
              decoration: const InputDecoration(
                labelText: 'Sebep',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            const Text('* Bu işlem geri alınamaz.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç')),
          ElevatedButton(
            child: const Text('İptal Et'),
            onPressed: () {
              onCancelled(seciliSebep, ctrl.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                       CalendarDataSource Wrapper                            */
/* -------------------------------------------------------------------------- */
class EtkinlikDataSource extends CalendarDataSource {
  EtkinlikDataSource(List<Appointment> src) {
    appointments = src;
  }
}

/* -------------------------------------------------------------------------- */
/*                         Alttaki Legend (Sabit Çubuk)                        */
/* -------------------------------------------------------------------------- */
class _LegendBar extends StatelessWidget {
  const _LegendBar();

  Widget _pill(BuildContext context, Color c, String t, {bool border = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: Colors.black54) : null,
          ),
        ),
        Text(t, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

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
              _pill(context, uygunOlmayanRenk, 'Uygun olmayan/past'),
            ],
          ),
        ),
      ),
    );
  }
}
