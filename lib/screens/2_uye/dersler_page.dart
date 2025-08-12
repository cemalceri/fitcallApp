// lib/screens/ders_listesi_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/models/dtos/week_takvim_data_dto.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_onay_model.dart';
import 'package:fitcall/screens/2_uye/ders_talep_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/* -------------------------------------------------------------------------- */
/*                            Renk Sabitleri                                   */
/* -------------------------------------------------------------------------- */
const Color dersDoluRenk = Colors.grey; // Takvimdeki dolu ders
const Color uygunSaatRenk = Colors.green; // Rezervasyon yapılabilir saat
const Color uygunOlmayanRenk = Colors.white; // Meşgul slot

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});
  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  EtkinlikDataSource _dataSource = EtkinlikDataSource(const []);
  final List<Appointment> _tumRandevular = [];
  bool _isLoading = false;

  UyeModel? currentUye;
  final Map<int, EtkinlikOnayModel> _userOnaylari = {};
  final Map<String, List<Map<String, dynamic>>> _slotAlternatifleri = {};
  final Set<DateTime> _yuklenenHaftalar = {};

  // ---- Filtre state ----
  final Map<int, String> _hocaAdlari = {};
  final Map<int, String> _kortAdlari = {};
  int? _seciliHocaId;
  int? _seciliKortId;
  RangeValues _saatAralik = const RangeValues(7, 23);

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    currentUye = await StorageService.uyeBilgileriniGetir();
    final now = DateTime.now();
    await _loadWeek(_haftaBaslangic(now));
    _applyFilters();
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

      final dersAppts = data.dersler.map(_dersToAppt).toList();

      final busyAppts = data.mesgul.map((s) => Appointment(
            id: 'busy-${s.baslangic.toIso8601String()}',
            startTime: s.baslangic,
            endTime: s.bitis,
            subject: '', // busy slotlar için subject boş
            notes: jsonEncode({
              'tip': 'busy',
              'antrenor_id': s.antrenorId,
              'antrenor_adi': s.antrenorAdi,
              'kort_id': s.kortId,
              'kort_adi': s.kortAdi,
            }),
            color: uygunOlmayanRenk,
          ));

      final availableAppts =
          data.uygun.where((s) => s.baslangic.isAfter(nowPlus3h)).map((s) {
        final key = s.baslangic.toUtc().toIso8601String();
        final m = {
          'baslangic_tarih_saat': s.baslangic.toUtc().toIso8601String(),
          'bitis_tarih_saat': s.bitis.toUtc().toIso8601String(),
          'antrenor_id': s.antrenorId,
          'antrenor_adi': s.antrenorAdi,
          'kort_id': s.kortId,
          'kort_adi': s.kortAdi,
        };
        _slotAlternatifleri.putIfAbsent(key, () => []);
        _slotAlternatifleri[key]!.add(m);
        return _availableToAppt(m);
      });

      _tumRandevular.addAll(dersAppts);
      _tumRandevular.addAll(busyAppts);
      _tumRandevular.addAll(availableAppts);

      _yenileFiltreOpsiyonlari();
      _applyFilters();
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Takvim alınamadı: $e');
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               Helpers                                      */
  /* -------------------------------------------------------------------------- */
  DateTime _haftaBaslangic(DateTime d) => d
      .subtract(Duration(days: d.weekday - 1))
      .copyWith(hour: 7, minute: 0, second: 0, millisecond: 0);

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

  Appointment _availableToAppt(Map<String, dynamic> s) => Appointment(
        id: 'available-${s['baslangic_tarih_saat']}',
        startTime: DateTime.parse(s['baslangic_tarih_saat']).toLocal(),
        endTime: DateTime.parse(s['bitis_tarih_saat']).toLocal(),
        subject: s['kort_adi']?.toString() ?? '',
        notes: jsonEncode({
          'tip': 'available',
          'baslangic': s['baslangic_tarih_saat'],
          'bitis': s['bitis_tarih_saat'],
          'antrenor_id': s['antrenor_id'],
          'antrenor_adi': s['antrenor_adi'],
          'kort_id': s['kort_id'],
          'kort_adi': s['kort_adi'],
        }),
        color: uygunSaatRenk.withAlpha((0.3 * 255).toInt()),
      );

  /* ----------------------- Filtre yardımcıları ----------------------------- */
  void _yenileFiltreOpsiyonlari() {
    _hocaAdlari.clear();
    _kortAdlari.clear();

    for (final a in _tumRandevular) {
      final n = _safeNotes(a);

      final hId = _toInt(n['antrenor_id']);
      // API bazı slotlarda hoca adı dönmeyebilir — ID’den fallback üret.
      final hAd = (n['antrenor_adi']?.toString() ?? '').trim();
      final hocaAdFinal =
          (hAd.isNotEmpty) ? hAd : (hId != null ? 'Hoca #$hId' : null);

      final kId = _toInt(n['kort_id']);
      // Kort adı yoksa appointment.subject’ten al (derslerde subject kort adı).
      final kAdRaw = (n['kort_adi']?.toString() ?? '').trim();
      final kAd = kAdRaw.isNotEmpty ? kAdRaw : (a.subject.toString());

      if (hId != null && (hocaAdFinal?.isNotEmpty ?? false)) {
        _hocaAdlari[hId] = hocaAdFinal!;
      }
      if (kId != null && kAd.isNotEmpty) {
        _kortAdlari[kId] = kAd;
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

  void _applyFilters() {
    final startH = _saatAralik.start.floor();
    final endH = _saatAralik.end.ceil();

    bool pass(Appointment a) {
      final n = _safeNotes(a);
      final hId = _toInt(n['antrenor_id']);
      final kId = _toInt(n['kort_id']);

      if (_seciliHocaId != null && hId != _seciliHocaId) return false;
      if (_seciliKortId != null && kId != _seciliKortId) return false;

      final sh = a.startTime.hour;
      final eh = a.endTime.hour == 0 ? 24 : a.endTime.hour;
      if (sh < startH || eh > endH) return false;

      return true;
    }

    final filtered = _tumRandevular.where(pass).toList();
    setState(() => _dataSource = EtkinlikDataSource(filtered));
  }

  int _aktifFiltreSayisi() {
    int c = 0;
    if (_seciliHocaId != null) c++;
    if (_seciliKortId != null) c++;
    if (!(_saatAralik.start == 7 && _saatAralik.end == 23)) c++;
    return c;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Takvimi'),
        actions: [
          IconButton(
            tooltip: 'Filtreleri Göster',
            icon: const Icon(Icons.filter_alt_rounded),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : _FilterFab(
              count: _aktifFiltreSayisi(),
              onPressed: _openFilterSheet,
            ),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : Column(
              children: [
                // Artık üstte sabit filtre bar yok; modern bottom sheet kullanılacak.
                Expanded(
                  child: Stack(
                    children: [
                      SfCalendar(
                        view: CalendarView.week,
                        dataSource: _dataSource,
                        firstDayOfWeek: 1,
                        timeSlotViewSettings: const TimeSlotViewSettings(
                          startHour: 7,
                          endHour: 23,
                          timeInterval: Duration(minutes: 60),
                        ),
                        onTap: _onTap,
                        onViewChanged: (ViewChangedDetails d) async {
                          if (d.visibleDates.isEmpty) return;
                          final wkStart = _haftaBaslangic(d.visibleDates.first);
                          await _loadWeek(wkStart);
                        },
                      ),
                      const Positioned(right: 16, bottom: 16, child: _Legend()),
                    ],
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
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
            ];
            final kortItems = <DropdownMenuItem<int?>>[
              const DropdownMenuItem(value: null, child: Text('Tüm Kortlar')),
              ..._kortAdlari.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
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
                          value: tempHoca,
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
                          value: tempKort,
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
                            });
                            _applyFilters();
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
  /*                                Tap handler                                 */
  /* -------------------------------------------------------------------------- */
  void _onTap(CalendarTapDetails d) async {
    if (d.targetElement == CalendarElement.calendarCell &&
        (d.appointments?.isEmpty ?? true)) {
      await _showBosSaatPopup(d.date!);
      return;
    }

    if (d.appointments?.isEmpty ?? true) return;
    final Appointment appt = d.appointments!.first;
    final note = _safeNotes(appt);
    final tip = note['tip'];

    if (tip == 'busy') {
      ShowMessage.error(context, 'Bu saat uygun değil.');
      return;
    }

    if (tip == 'available') {
      final bas = DateTime.parse(note['baslangic']).toLocal();
      await _showBosSaatPopup(bas);
      return;
    }

    if (tip != 'ders') return;

    final EtkinlikModel ders =
        EtkinlikModel.fromMap(note.cast<String, dynamic>());
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
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
        },
      );
    } else {
      _showIptalPopup(
        ders,
        onCancelled: () {
          appt.color = uygunOlmayanRenk;
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
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

    final secim = await showModalBottomSheet<Map>(
      context: context,
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: alternatifler.length,
        itemBuilder: (_, i) {
          final a = alternatifler[i];
          final bas = slotStart;
          final bit = bas.add(const Duration(hours: 1));
          return ListTile(
            title: Text('${a['kort_adi']} – ${a['antrenor_adi']}'),
            subtitle: Text(
              '${bas.hour.toString().padLeft(2, "0")}:00 – ${bit.hour.toString().padLeft(2, "0")}:00',
            ),
            onTap: () => Navigator.pop(context, a),
          );
        },
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
                  final r = await TakvimService.dersYapildiBilgisi(
                    dersId: ders.id,
                    tamamlandi: tamamlandi,
                    aciklama: ctrl.text,
                  );
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
      {required VoidCallback onCancelled}) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ders İptal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('İptal açıklaması (isteğe bağlı)'),
            const SizedBox(height: 8),
            TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Neden iptal ediyorsunuz?',
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

                onCancelled();
                ShowMessage.success(context, res.mesaj);
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
/*                       CalendarDataSource Wrapper                            */
/* -------------------------------------------------------------------------- */
class EtkinlikDataSource extends CalendarDataSource {
  EtkinlikDataSource(List<Appointment> src) {
    appointments = src;
  }
}

/* -------------------------------------------------------------------------- */
/*                               Legend Widget                                 */
/* -------------------------------------------------------------------------- */
class _Legend extends StatelessWidget {
  const _Legend();
  Widget _item(Color c, String t, {bool border = false}) => Row(
        children: [
          Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  color: c,
                  border: border ? Border.all(color: Colors.black54) : null)),
          Text(t),
        ],
      );
  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        color: Colors.white.withAlpha((0.9 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _item(dersDoluRenk, 'Dolu ders', border: true),
            const SizedBox(height: 4),
            _item(uygunSaatRenk, 'Uygun saat'),
            const SizedBox(height: 4),
            _item(uygunOlmayanRenk, 'Uygun olmayan saat'),
          ]),
        ),
      );
}

/* -------------------------------------------------------------------------- */
/*                              Filtre FAB                                     */
/* -------------------------------------------------------------------------- */
class _FilterFab extends StatelessWidget {
  const _FilterFab({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.filter_alt),
      label: const Text('Filtreleri Göster'),
    );

    if (count <= 0) return fab;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        fab,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
