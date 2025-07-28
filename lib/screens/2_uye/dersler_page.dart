// lib/screens/ders_listesi_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_onay_model.dart';
import 'package:fitcall/screens/2_uye/ders_talep_page.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  /* -------------------------------------------------------------------------- */
  /*                             State değişkenleri                             */
  /* -------------------------------------------------------------------------- */
  EtkinlikDataSource _dataSource = EtkinlikDataSource(const []);
  bool _isLoading = false;

  UyeModel? currentUye;
  final Map<int, EtkinlikOnayModel> _userOnaylari = {};
  final Map<String, List<dynamic>> _slotAlternatifleri = {}; // cache
  final Set<DateTime> _yuklenenHaftalar = {}; // aynı haftaya tekrar api atmasın

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _isLoading = true);
    currentUye = await AuthService.uyeBilgileriniGetir();
    final now = DateTime.now();
    await _loadWeek(_haftaBaslangic(now));
    setState(() => _isLoading = false);
  }

  /* -------------------------------------------------------------------------- */
  /*                                API çağrısı                                 */
  /* -------------------------------------------------------------------------- */
  Future<void> _loadWeek(DateTime weekStart) async {
    if (_yuklenenHaftalar.contains(weekStart)) return; // cache
    _yuklenenHaftalar.add(weekStart);

    final token = await AuthService.getToken();
    if (token == null) return;

    final weekEnd = weekStart.add(const Duration(days: 7));
    final nowPlus3h = DateTime.now().add(const Duration(hours: 3));

    try {
      /* Dersler */
      final dersRes = await http.post(Uri.parse(getDersProgrami),
          headers: {'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'start': weekStart.toIso8601String(),
            'end': weekEnd.toIso8601String(),
          }));

      final List<Appointment> appts = [..._dataSource.appointments ?? []];

      if (dersRes.statusCode == 200) {
        final dersler = EtkinlikModel.fromJson(dersRes);
        appts.addAll(dersler.map(_dersToAppt));
      }

      /* Uygun / dolu slotlar */
      final slotRes = await http.post(Uri.parse(getUygunSaatler),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'start': weekStart.toIso8601String(),
            'end': weekEnd.toIso8601String(),
          }));

      if (slotRes.statusCode == 200) {
        final Map data = jsonDecode(slotRes.body);

        for (final s in data['busy']) {
          appts.add(_busyToAppt(s));
        }

        for (final s in data['available']) {
          final bas = DateTime.parse(s['baslangic_tarih_saat']).toLocal();
          if (bas.isBefore(nowPlus3h)) continue; // 3 saat kuralı
          appts.add(_availableToAppt(s));
          _slotAlternatifleri
              .putIfAbsent(s['baslangic_tarih_saat'], () => [])
              .add(s);
        }
      }

      setState(() => _dataSource = EtkinlikDataSource(appts));
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

  Appointment _dersToAppt(EtkinlikModel d) => Appointment(
        id: d.id,
        startTime: d.baslangicTarihSaat,
        endTime: d.bitisTarihSaat,
        subject: d.kortAdi,
        notes: jsonEncode({...d.toJson(), 'tip': 'ders'}),
        color: d.iptalMi ? uygunOlmayanRenk : dersDoluRenk,
      );

  Appointment _busyToAppt(dynamic s) => Appointment(
        id: 'busy-${s['baslangic_tarih_saat']}',
        startTime: DateTime.parse(s['baslangic_tarih_saat']).toLocal(),
        endTime: DateTime.parse(s['bitis_tarih_saat']).toLocal(),
        subject: '',
        notes: jsonEncode({'tip': 'busy'}),
        color: uygunOlmayanRenk,
      );

  Appointment _availableToAppt(dynamic s) => Appointment(
        id: 'available-${s['baslangic_tarih_saat']}',
        startTime: DateTime.parse(s['baslangic_tarih_saat']).toLocal(),
        endTime: DateTime.parse(s['bitis_tarih_saat']).toLocal(),
        subject: '',
        notes: jsonEncode(
            {'tip': 'available', 'baslangic': s['baslangic_tarih_saat']}),
        color: uygunSaatRenk.withAlpha((0.3 * 255).toInt()),
      );

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Takvimi')),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Takvim yükleniyor...')
          : Stack(
              children: [
                SfCalendar(
                  view: CalendarView.week,
                  dataSource: _dataSource,
                  firstDayOfWeek: 1,
                  timeSlotViewSettings: const TimeSlotViewSettings(
                      startHour: 7,
                      endHour: 23,
                      timeInterval: Duration(minutes: 60)),
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
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                Tap handler                                 */
  /* -------------------------------------------------------------------------- */
  void _onTap(CalendarTapDetails d) async {
    /* Hücre boş ise */
    if (d.targetElement == CalendarElement.calendarCell &&
        (d.appointments?.isEmpty ?? true)) {
      await _showBosSaatPopup(d.date!);
      return;
    }

    if (d.appointments?.isEmpty ?? true) return;
    final Appointment appt = d.appointments!.first;
    Map note;
    try {
      note = jsonDecode(appt.notes ?? '{}');
    } catch (_) {
      return;
    }
    final tip = note['tip'];

    /* Uygun olmayan */
    if (tip == 'busy') {
      ShowMessage.error(context, 'Bu saat uygun değil.');
      return;
    }

    /* Uygun saat tıklandıysa */
    if (tip == 'available') {
      final bas = DateTime.parse(note['baslangic']).toLocal();
      await _showBosSaatPopup(bas);
      return;
    }

    /* Ders */
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

    final token = await AuthService.getToken();
    if (token == null) return;

    final key = slotStart.toUtc().toIso8601String();
    List<dynamic> alternatifler = _slotAlternatifleri[key] ?? [];

    if (alternatifler.isEmpty) {
      final res = await http.post(Uri.parse(getUygunSaatler),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'start': slotStart.toIso8601String(),
            'end': slotStart.add(const Duration(hours: 1)).toIso8601String(),
          }));
      if (res.statusCode == 200) {
        final Map data = jsonDecode(utf8.decode(res.bodyBytes));
        alternatifler = data['available']
            .where((a) => DateTime.parse(a['baslangic_tarih_saat'])
                .toLocal()
                .isAfter(nowPlus3h))
            .toList();
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
                '${bas.hour.toString().padLeft(2, "0")}:00 – ${bit.hour.toString().padLeft(2, "0")}:00'),
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
                final token = await AuthService.getToken();
                if (token == null) return;
                try {
                  final r = await http.post(Uri.parse(setDersYapildiBilgisi),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token'
                      },
                      body: jsonEncode({
                        'ders_id': ders.id,
                        'aciklama': ctrl.text,
                        'tamamlandi': tamamlandi
                      }));
                  if (r.statusCode == 200) {
                    onSaved(tamamlandi, ctrl.text);
                    ShowMessage.success(context, 'Kaydedildi');
                  } else {
                    ShowMessage.error(context, 'Kaydedilemedi');
                  }
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
              final token = await AuthService.getToken();
              if (token == null) return;

              try {
                final res = await http.post(Uri.parse(setUyeDersIptal),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token'
                    },
                    body: jsonEncode(
                        {'etkinlik_id': ders.id, 'aciklama': ctrl.text}));

                if (res.statusCode == 200) {
                  onCancelled();
                  ShowMessage.success(
                      context,
                      jsonDecode(utf8.decode(res.bodyBytes))['message'] ??
                          'İptal edildi');
                } else {
                  ShowMessage.error(
                      context,
                      jsonDecode(utf8.decode(res.bodyBytes))['message'] ??
                          'İşlem yapılamadı');
                }
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
/*                       CalendarDataSource Wrapper                           */
/* -------------------------------------------------------------------------- */
class EtkinlikDataSource extends CalendarDataSource {
  EtkinlikDataSource(List<Appointment> src) {
    appointments = src;
  }
}

/* -------------------------------------------------------------------------- */
/*                               Legend Widget                                */
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
