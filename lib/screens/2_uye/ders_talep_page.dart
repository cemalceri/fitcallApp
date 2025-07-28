import 'dart:convert';
import 'package:fitcall/common/api_urls.dart'; // setDersTalep
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DersTalepPage extends StatefulWidget {
  final Map
      secimJson; // {"kort_id":..,"antrenor_id":..,"kort_adi":..,"antrenor_adi":..}
  final DateTime baslangic;

  const DersTalepPage(
      {super.key, required this.secimJson, required this.baslangic});

  @override
  State<DersTalepPage> createState() => _DersTalepPageState();
}

class _DersTalepPageState extends State<DersTalepPage> {
  final TextEditingController _aciklamaCtrl = TextEditingController();
  bool _sending = false;

  DateTime get _bitis => widget.baslangic.add(const Duration(hours: 1));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rezervasyon Talebi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoCard(
              icon: Icons.sports_tennis,
              label: 'Kort',
              value: widget.secimJson['kort_adi'] ?? '',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.person,
              label: 'Antrenör',
              value: widget.secimJson['antrenor_adi'] ?? '',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.schedule,
              label: 'Saat',
              value:
                  '${widget.baslangic.hour.toString().padLeft(2, "0")}:00 – ${_bitis.hour.toString().padLeft(2, "0")}:00',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _aciklamaCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Text('Talep Gönder',
                        style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _sending ? null : _gonder,
              ),
            ),
          ]),
        ),
      );

  /* ------------------ Bilgi kartı ------------------ */
  Widget _infoCard(
          {required IconData icon,
          required String label,
          required String value}) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ]),
            ),
          ]),
        ),
      );

  /* ------------------ Talep gönder ------------------ */
  Future<void> _gonder() async {
    setState(() => _sending = true);
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _sending = false);
      return;
    }

    final payload = {
      'kort_id': widget.secimJson['kort_id'],
      'antrenor_id': widget.secimJson['antrenor_id'],
      'baslangic_tarih_saat': widget.baslangic.toUtc().toIso8601String(),
      'bitis_tarih_saat': _bitis.toUtc().toIso8601String(),
      'aciklama': _aciklamaCtrl.text,
    };

    try {
      final res = await http.post(Uri.parse(setDersTalep),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(payload));

      if (!mounted) return;

      if (res.statusCode == 200) {
        ShowMessage.success(context, 'Talebiniz oluşturuldu');
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
