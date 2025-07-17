// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/widgets/show_message_widget.dart';
import 'package:fitcall/common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_onay_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  EtkinlikDataSource _dataSource =
      EtkinlikDataSource(const []); // <-- başlangıçta boş
  bool _apiIstegiTamamlandiMi = false;
  UyeModel? currentUye;
  final Map<int, EtkinlikOnayModel> _userOnaylari = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    currentUye = await AuthService.uyeBilgileriniGetir();
    await _dersBilgileriniCek();
  }

  Future<void> _dersBilgileriniCek() async {
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _apiIstegiTamamlandiMi = true);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(getDersProgrami),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final dersler = EtkinlikModel.fromJson(res);
        _dataSource = EtkinlikDataSource(
          dersler.map(_etkinlikToAppointment).toList(),
        );
      } else {
        ShowMessage.error(context, 'API ${res.statusCode}');
      }
    } catch (e) {
      ShowMessage.error(context, 'Dersler alınamadı: $e');
    } finally {
      setState(() => _apiIstegiTamamlandiMi = true);
    }
  }

  Appointment _etkinlikToAppointment(EtkinlikModel d) => Appointment(
        id: d.id,
        startTime: d.baslangicTarihSaat,
        endTime: d.bitisTarihSaat,
        subject: d.kort,
        notes: jsonEncode(d.toJson()),
        color: d.bitisTarihSaat.isBefore(DateTime.now())
            ? Colors.green
            : Colors.blue,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Takvimi')),
      body: _apiIstegiTamamlandiMi
          ? SfCalendar(
              view: CalendarView.week,
              dataSource: _dataSource,
              firstDayOfWeek: 1,
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 7,
                endHour: 23,
                timeInterval: Duration(minutes: 60),
              ),
              onTap: _onCalendarTap,
            )
          : const LoadingSpinnerWidget(message: 'Dersler yükleniyor...'),
    );
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.appointment ||
            details.appointments!.isEmpty ??
        true) return;

    final Appointment appt = details.appointments!.first;
    final ders = EtkinlikModel.fromMap(jsonDecode(appt.notes!));
    if (ders.bitisTarihSaat.isAfter(DateTime.now())) return;

    final onay = _userOnaylari[ders.id];
    _showEditPopup(
      ders,
      userCompleted: onay?.tamamlandi ?? false,
      userAciklama: onay?.aciklama ?? '',
      onSaved: (tam, acik) {
        _userOnaylari[ders.id] = EtkinlikOnayModel.empty()
          ..tamamlandi = tam
          ..aciklama = acik;
        appt.color = Colors.green;
        _dataSource.notifyListeners(
          CalendarDataSourceAction.reset,
          _dataSource.appointments!,
        );
      },
    );
  }

  /* --------------------------- Popup + API kaydet -------------------------- */
  void _showEditPopup(
    EtkinlikModel ders, {
    required bool userCompleted,
    required String userAciklama,
    required void Function(bool, String) onSaved,
  }) {
    final ctrl = TextEditingController(text: userAciklama);
    bool tamamlandi = userCompleted;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ders Değerlendirme'),
        content: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Ders tamamlandı mı?'),
                value: tamamlandi,
                onChanged: (v) => setState(() => tamamlandi = v ?? false),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Not Ekle',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Kaydet'),
            onPressed: () async {
              final token = await AuthService.getToken();
              if (token == null) return;

              try {
                final r = await http.post(
                  Uri.parse(setDersYapildiBilgisi),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({
                    'ders_id': ders.id,
                    'aciklama': ctrl.text,
                    'tamamlandi': tamamlandi,
                  }),
                );
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
            },
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- DataSource sınıfı ---------------------------- */

class EtkinlikDataSource extends CalendarDataSource {
  EtkinlikDataSource(List<Appointment> source) {
    appointments = source;
  }
}

/* ---------------------------- Yardımcı uzantılar ---------------------------- */

extension EtkinlikSerde on EtkinlikModel {
  Map<String, dynamic> toJson() => {
        'id': id,
        'haftalik_plan_kodu': haftalikPlanKodu,
        'grup': grup,
        'urun': urun,
        'baslangic_tarih_saat': baslangicTarihSaat.toIso8601String(),
        'bitis_tarih_saat': bitisTarihSaat.toIso8601String(),
        'kort': kort,
        'seviye': seviye,
        'antrenor': antrenor,
        'yardimci_antrenor': yardimciAntrenor,
        'iptal_mi': iptalMi,
        'iptal_eden': iptalEden,
        'iptal_tarih_saat': iptalTarihSaat?.toIso8601String(),
        'ucret': ucret,
        'is_active': isActive,
        'is_deleted': isDeleted,
        'olusturulma_zamani': createdAt.toIso8601String(),
        'guncellenme_zamani': updatedAt.toIso8601String(),
      };
}

extension EtkinlikOnayModelExt on EtkinlikOnayModel {
  static EtkinlikOnayModel empty() => EtkinlikOnayModel(
        id: 0,
        etkinlik: '',
        rol: '',
        tamamlandi: false,
        onayTarihi: DateTime.now(),
        isActive: true,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
