import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/7_kort/kort_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_talep_api_service.dart';
import 'package:fitcall/services/kort/kort_api_service.dart';
import 'package:flutter/material.dart';

class GenelDersTalepPage extends StatefulWidget {
  const GenelDersTalepPage({super.key});

  @override
  State<GenelDersTalepPage> createState() => _GenelDersTalepPageState();
}

class _GenelDersTalepPageState extends State<GenelDersTalepPage> {
  final TextEditingController _aciklamaCtrl = TextEditingController();
  bool _loading = false;
  bool _sending = false;

  List<KortModel> _kortlar = [];
  List<AntrenorModel> _antrenorler = [];
  int? _selectedKortId;
  int? _selectedAntrenorId;

  final Map<String, List<TimeOfDay>> _secilenSaatler = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _loading = true);
    try {
      final res = await KortApiService.getKortVeAntrenorList();
      final data = res.data ?? {};
      setState(() {
        _kortlar = (data['kortlar'] as List)
            .map((e) => KortModel.fromJson(e))
            .toList();
        _antrenorler = (data['antrenorler'] as List)
            .map((e) => AntrenorModel.fromJson(e))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Genel Ders Talep')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdownKort(),
                    const SizedBox(height: 8),
                    _dropdownAntrenor(),
                    const SizedBox(height: 16),
                    Expanded(child: _haftalikSaatPicker()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aciklamaCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _gonder,
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              )
                            : const Text('Talep Gönder'),
                      ),
                    ),
                  ],
                ),
              ),
      );

  DropdownButtonFormField<int> _dropdownKort() => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Kort (opsiyonel)',
          border: OutlineInputBorder(),
        ),
        initialValue: _selectedKortId,
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('Herhangi')),
          ..._kortlar.map(
              (k) => DropdownMenuItem<int>(value: k.id, child: Text(k.adi)))
        ],
        onChanged: (v) => setState(() => _selectedKortId = v),
      );

  DropdownButtonFormField<int> _dropdownAntrenor() =>
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Antrenör (opsiyonel)',
          border: OutlineInputBorder(),
        ),
        initialValue: _selectedAntrenorId,
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('Herhangi')),
          ..._antrenorler.map(
            (h) => DropdownMenuItem<int>(
              value: h.id,
              child: Text('${h.adi} ${h.soyadi}'),
            ),
          )
        ],
        onChanged: (v) => setState(() => _selectedAntrenorId = v),
      );

  Widget _haftalikSaatPicker() => ListView(
        children: _secilenSaatler.keys.map((gun) {
          final saatList = _secilenSaatler[gun]!;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _gunAdi(gun),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final TimeOfDay? secim = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                            builder: (ctx, child) => MediaQuery(
                              data: MediaQuery.of(ctx)
                                  .copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            ),
                          );
                          if (secim == null) return;

                          // Yalnızca tam ve buçuk saat: dakikayı 00/30'a sabitle
                          final snapped = _snapToHalfHour(secim);

                          setState(() {
                            final exists = saatList.any(
                              (t) =>
                                  t.hour == snapped.hour &&
                                  t.minute == snapped.minute,
                            );
                            if (!exists) {
                              saatList.add(snapped);
                              saatList.sort((a, b) => (a.hour * 60 + a.minute)
                                  .compareTo(b.hour * 60 + b.minute));
                            }
                          });
                        },
                      )
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: saatList
                        .map(
                          (t) => Chip(
                            label: Text(_formatTime(t)), // HH:mm olarak göster
                            onDeleted: () => setState(() => saatList.remove(t)),
                          ),
                        )
                        .toList(),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      );

  String _gunAdi(String code) => switch (code) {
        'Mon' => 'Pazartesi',
        'Tue' => 'Salı',
        'Wed' => 'Çarşamba',
        'Thu' => 'Perşembe',
        'Fri' => 'Cuma',
        'Sat' => 'Cumartesi',
        _ => 'Pazar',
      };

  // Dakikayı 00 veya 30'a sabitle (floor mantığı)
  TimeOfDay _snapToHalfHour(TimeOfDay t) =>
      TimeOfDay(hour: t.hour, minute: t.minute < 30 ? 0 : 30);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _gonder() async {
    final Map<String, List<String>> saatJson = {};
    _secilenSaatler.forEach((gun, list) {
      if (list.isNotEmpty) {
        saatJson[gun] =
            list.map((t) => _formatTime(t)).toList(); // HH:mm gönder
      }
    });

    if (saatJson.isEmpty) {
      if (!mounted) return;
      ShowMessage.error(context, 'En az bir saat seçin');
      return;
    }

    setState(() => _sending = true);

    try {
      final res = await DersTalepApiService.gonderGenelDersTalep(
        saatler: saatJson,
        aciklama: _aciklamaCtrl.text,
        kortId: _selectedKortId,
        antrenorId: _selectedAntrenorId,
      );

      if (!mounted) return;
      ShowMessage.success(context, res.mesaj);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
      setState(() => _sending = false);
    }
  }
}
