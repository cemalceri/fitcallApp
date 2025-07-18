// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart'; //  ←  getDersProgrami, setDersYapildiBilgisi, uyeDersIptal
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
  EtkinlikDataSource _dataSource = EtkinlikDataSource(const []);
  bool _apiBitti = false;
  UyeModel? currentUye;
  final Map<int, EtkinlikOnayModel> _userOnaylari = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    currentUye = await AuthService.uyeBilgileriniGetir();
    await _dersleriGetir();
  }

  /* -------------------------------------------------------------------------- */
  /*                             API - Ders listesi                             */
  /* -------------------------------------------------------------------------- */
  Future<void> _dersleriGetir() async {
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() => _apiBitti = true);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(getDersProgrami),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final dersler = EtkinlikModel.fromJson(res);
        _dataSource = EtkinlikDataSource(dersler.map(_toAppointment).toList());
      } else {
        ShowMessage.error(context, 'API ${res.statusCode}');
      }
    } catch (e) {
      ShowMessage.error(context, 'Dersler alınamadı: $e');
    } finally {
      setState(() => _apiBitti = true);
    }
  }

  Appointment _toAppointment(EtkinlikModel d) => Appointment(
        id: d.id,
        startTime: d.baslangicTarihSaat,
        endTime: d.bitisTarihSaat,
        subject: d.kortAdi,
        notes: jsonEncode(d.toJson()),
        color: d.iptalMi
            ? Colors.red
            : d.bitisTarihSaat.isBefore(DateTime.now())
                ? Colors.green
                : Colors.blue,
      );

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Takvimi')),
      body: _apiBitti
          ? SfCalendar(
              view: CalendarView.week,
              dataSource: _dataSource,
              firstDayOfWeek: 1,
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 7,
                endHour: 23,
                timeInterval: Duration(minutes: 60),
              ),
              onTap: _onTap,
            )
          : const LoadingSpinnerWidget(message: 'Dersler yükleniyor...'),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                             Takvim Tap-handler                             */
  /* -------------------------------------------------------------------------- */
  void _onTap(CalendarTapDetails d) {
    if (d.targetElement != CalendarElement.appointment ||
        (d.appointments?.isEmpty ?? true)) return;

    final Appointment appt = d.appointments!.first;
    final EtkinlikModel ders = EtkinlikModel.fromMap(jsonDecode(appt.notes!));

    final bool isPast = ders.bitisTarihSaat.isBefore(DateTime.now());

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
          appt.color = Colors.green;
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
        },
      );
    } else {
      _showIptalPopup(
        ders,
        onCancelled: () {
          appt.color = Colors.red;
          _dataSource.notifyListeners(
              CalendarDataSourceAction.reset, _dataSource.appointments!);
        },
      );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                       Geçmiş ders – tamamlama popup                        */
  /* -------------------------------------------------------------------------- */
  void _showTamamlamaPopup(
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
                    labelText: 'Not', border: OutlineInputBorder()),
              )
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
            },
          )
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                        Gelecek ders – iptal popup                          */
  /* -------------------------------------------------------------------------- */
  void _showIptalPopup(
    EtkinlikModel ders, {
    required VoidCallback onCancelled,
  }) {
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
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('İptal Et'),
            onPressed: () async {
              final token = await AuthService.getToken();
              if (token == null) return;

              try {
                final res = await http.post(
                  Uri.parse(setUyeDersIptal),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode(
                    {'etkinlik_id': ders.id, 'aciklama': ctrl.text},
                  ),
                );

                if (res.statusCode == 200) {
                  onCancelled();
                  ShowMessage.success(context,
                      jsonDecode(res.body)['message'] ?? 'İptal edildi');
                } else {
                  final errMsg = jsonDecode(res.body)['message'] ??
                      'İşlem gerçekleştirilemedi';
                  ShowMessage.error(context, errMsg);
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

/* -------------------------------------------------------------------------- */
/*                              DataSource class                               */
/* -------------------------------------------------------------------------- */
class EtkinlikDataSource extends CalendarDataSource {
  EtkinlikDataSource(List<Appointment> src) {
    appointments = src;
  }
}

/* -------------------------------------------------------------------------- */
/*                             Yardımcı uzantılar                              */
/* -------------------------------------------------------------------------- */
extension EtkinlikSerde on EtkinlikModel {
  Map<String, dynamic> toJson() => {
        'id': id,
        'haftalik_plan_kodu': haftalikPlanKodu,
        'grup_adi': grupAdi,
        'urun_adi': urunAdi,
        'baslangic_tarih_saat': baslangicTarihSaat.toIso8601String(),
        'bitis_tarih_saat': bitisTarihSaat.toIso8601String(),
        'kort_adi': kortAdi,
        'seviye': seviye,
        'antrenor_adi': antrenorAdi,
        'yardimci_antrenor_adi': yardimciAntrenorAdi,
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
