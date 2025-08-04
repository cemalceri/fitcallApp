import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/models/7_kort/kort_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  /// {'Mon': [09:00, 10:00], ...}
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

  /* -------------------------------------------------------------------------- */
  /*                        Kort + Antrenör listesi                             */
  /* -------------------------------------------------------------------------- */
  Future<void> _loadList() async {
    setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(getKortveAntrenorList),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final Map data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _kortlar = (data['kortlar'] as List)
              .map((e) => KortModel.fromJson(e))
              .toList();
          _antrenorler = (data['antrenorler'] as List)
              .map((e) => AntrenorModel.fromJson(e))
              .toList();
          _loading = false;
        });
      } else {
        ShowMessage.error(context, 'Liste alınamadı (${res.statusCode})');
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _loading = false);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                    UI                                      */
  /* -------------------------------------------------------------------------- */
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
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _gonder,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator())
                              : const Text('Talep Gönder'),
                        ),
                      )
                    ]),
              ),
      );

  DropdownButtonFormField<int> _dropdownKort() => DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Kort (opsiyonel)', border: OutlineInputBorder()),
        value: _selectedKortId,
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
            labelText: 'Antrenör (opsiyonel)', border: OutlineInputBorder()),
        value: _selectedAntrenorId,
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('Herhangi')),
          ..._antrenorler.map((h) => DropdownMenuItem<int>(
              value: h.id, child: Text('${h.adi} ${h.soyadi}')))
        ],
        onChanged: (v) => setState(() => _selectedAntrenorId = v),
      );

  /* ---------------- Haftaya yayılmış saat seçici ---------------- */
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
                        Text(_gunAdi(gun),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final TimeOfDay? secim = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      const TimeOfDay(hour: 9, minute: 0));
                              if (secim == null) return;
                              setState(() => saatList.add(secim));
                            })
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      children: saatList
                          .map((t) => Chip(
                                label: Text(
                                    '${t.hour.toString().padLeft(2, '0')}:00'),
                                onDeleted: () =>
                                    setState(() => saatList.remove(t)),
                              ))
                          .toList(),
                    )
                  ]),
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

  /* -------------------------------------------------------------------------- */
  /*                             Talep Gönderme                                 */
  /* -------------------------------------------------------------------------- */
  Future<void> _gonder() async {
    // En az bir saat seçili olmalı
    final Map<String, List<String>> saatJson = {};
    _secilenSaatler.forEach((gun, list) {
      if (list.isNotEmpty) {
        saatJson[gun] =
            list.map((t) => '${t.hour.toString().padLeft(2, '0')}:00').toList();
      }
    });
    if (saatJson.isEmpty) {
      ShowMessage.error(context, 'En az bir saat seçin');
      return;
    }

    setState(() => _sending = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _sending = false);
      return;
    }

    final payload = <String, dynamic>{
      'saatler': saatJson,
      'aciklama': _aciklamaCtrl.text,
      if (_selectedKortId != null) 'kort_id': _selectedKortId,
      if (_selectedAntrenorId != null) 'antrenor_id': _selectedAntrenorId,
    };

    try {
      final res = await http.post(Uri.parse(setGenelDersTalep),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (!mounted) return;

      if (res.statusCode == 200) {
        ShowMessage.success(context, 'Talebiniz gönderildi');
        Navigator.pop(context, true);
      } else {
        ShowMessage.error(context, 'Hata: ${res.statusCode}');
        setState(() => _sending = false);
      }
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _sending = false);
    }
  }
}
