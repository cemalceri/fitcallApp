// ignore_for_file: use_build_context_synchronously
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

class DersTeyitPage extends StatefulWidget {
  /// Route ile `arguments` olarak gönderilen map:
  /// {
  ///   "notification_id": 123,
  ///   "generic_id": "45",     // uye_id
  ///   "model_own_id": "78"    // etkinlik_id
  /// }
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

  Future<void> _fetchBildirim() async {
    if (_bildirimId.isEmpty) {
      ShowMessage.error(context, 'Bildirim bilgisi eksik.');
      Navigator.pop(context);
      return;
    }
    try {
      final r = await DersTeyitService.getBildirim(_bildirimId);
      setState(() => _bildirim = r.data);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
      Navigator.pop(context);
    } catch (e) {
      ShowMessage.error(context, 'Sunucu hatası: $e');
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(bool durum) async {
    if (_posting) return;
    setState(() => _posting = true);

    try {
      final r = await DersTeyitService.setDersTeyitBilgisi(
        uyeId: _uyeId,
        etkinlikId: _etkinlikId,
        durum: durum,
      );
      setState(() => _cevapVerildi = true);
      ShowMessage.success(context, r.mesaj); // backend mesajı öncelikli
    } on ApiException catch (e) {
      if (e.code == 'TEYIT_DEGISTIRME_YASAK' || e.statusCode == 409) {
        ShowMessage.warning(
          context,
          e.message.isNotEmpty
              ? e.message
              : 'Daha önce verdiğiniz karar değiştirilemez. Lütfen kulüp ile iletişime geçiniz.',
        );
      } else if (e.code == 'TIMEOUT') {
        ShowMessage.error(context, 'Zaman aşımı. Lütfen tekrar deneyiniz.');
      } else {
        ShowMessage.error(
            context, e.message.isNotEmpty ? e.message : 'İşlem başarısız.');
      }
    } catch (e) {
      ShowMessage.error(context, 'İşlem sırasında hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

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
                    const Column(
                      children: [
                        Icon(Icons.done, size: 48, color: Colors.green),
                        SizedBox(height: 8),
                        Text('Cevabınız alındı. Teşekkürler.'),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
