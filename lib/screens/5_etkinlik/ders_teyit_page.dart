// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fitcall/common/api_urls.dart'; // setDersTeyit, getBildirimById
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

class DersTeyitPage extends StatefulWidget {
  /// Route ile `arguments` olarak gönderilen map alınır.
  ///   {
  ///     "notification_id": 123,
  ///     "generic_id": "45",     // uye_id
  ///     "model_own_id": "78"    // etkinlik_id
  ///   }
  const DersTeyitPage({super.key, this.data});
  final Map<String, dynamic>? data;

  @override
  State<DersTeyitPage> createState() => _DersTeyitPageState();
}

class _DersTeyitPageState extends State<DersTeyitPage> {
  String _bildirimId = '';
  String _uyeId = '';
  String _etkinlikId = '';

  NotificationModel? _bildirim;
  bool _loading = true; // bildirim getiriliyor
  bool _posting = false; // evet/hayır gönderiliyor
  bool _cevapVerildi = false;

  /* -------- arguments hem ctor’dan hem ModalRoute’tan alınabilir -------- */
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bildirimId.isNotEmpty) return; // sadece ilk kez
    final args = widget.data ??
        (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {};
    _bildirimId = '${args['notification_id'] ?? ''}';
    _uyeId = '${args['generic_id'] ?? ''}';
    _etkinlikId = '${args['model_own_id'] ?? ''}';
    _fetchBildirim();
  }

  /* ---------------- Bildirimi getir ---------------- */
  Future<void> _fetchBildirim() async {
    if (_bildirimId.isEmpty) {
      ShowMessage.error(context, 'Bildirim bilgisi eksik.');
      Navigator.pop(context);
      return;
    }

    try {
      final res = await http
          .post(Uri.parse(getBildirimById),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'bildirim_id': _bildirimId}))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final j = jsonDecode(utf8.decode(res.bodyBytes));
        _bildirim = NotificationModel.fromJson(j);
      } else {
        ShowMessage.error(context, 'Bildirim alınamadı (${res.statusCode}).');
      }
    } catch (e) {
      ShowMessage.error(context, 'Sunucu hatası: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------------- Cevap gönder ---------------- */
  Future<void> _submit(bool durum) async {
    if (_posting) return;
    setState(() => _posting = true);

    try {
      final res = await http
          .post(Uri.parse(setDersTeyit),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'uye_id': _uyeId,
                'etkinlik_id': _etkinlikId,
                'durum': durum,
              }))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        setState(() => _cevapVerildi = true);
        ShowMessage.success(context, 'Cevabınız kaydedildi');
      } else {
        ShowMessage.error(context, 'İşlem başarısız (${res.statusCode})');
      }
    } catch (_) {
      ShowMessage.error(context, 'İşlem sırasında hata oluştu');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    final soru = _bildirim?.body ?? 'Derse katılacak mısınız?';

    return Scaffold(
      appBar: AppBar(title: Text(_bildirim?.title ?? 'Ders Onayı')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(soru,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (!_cevapVerildi)
                    _posting
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Evet'),
                                onPressed: () => _submit(true),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Hayır'),
                                onPressed: () => _submit(false),
                              ),
                            ],
                          )
                  else
                    const Icon(Icons.done, size: 48, color: Colors.green),
                ],
              ),
      ),
    );
  }
}
