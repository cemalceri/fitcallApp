// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

class DersTeyitPage extends StatefulWidget {
  const DersTeyitPage({super.key});

  @override
  State<DersTeyitPage> createState() => _DersTeyitPageState();
}

class _DersTeyitPageState extends State<DersTeyitPage> {
  Map<String, dynamic>? _args;
  bool _posting = false;
  bool _cevapVerildi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    _args = ((ModalRoute.of(context)?.settings.arguments as Map?) ?? {})
        .cast<String, dynamic>();
  }

  Future<void> _submit(bool durum) async {
    if (_posting || _args == null) return;
    setState(() => _posting = true);

    final uyeId = _args!['uye_id']?.toString() ?? '';
    final etkinlikId = _args!['etkinlik_id']?.toString() ?? '';

    if (uyeId.isEmpty || etkinlikId.isEmpty) {
      ShowMessage.error(context, 'Eksik bilgi.');
      setState(() => _posting = false);
      return;
    }

    try {
      final r = await DersTeyitService.setDersTeyitBilgisi(
          uyeId: uyeId, etkinlikId: etkinlikId, durum: durum);
      setState(() => _cevapVerildi = true);
      ShowMessage.success(context, r.mesaj);
    } on ApiException catch (e) {
      if (e.code == 'TEYIT_DEGISTIRME_YASAK' || e.statusCode == 409) {
        ShowMessage.warning(
            context,
            e.message.isNotEmpty
                ? e.message
                : 'Daha önce verdiğiniz karar değiştirilemez.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Onayı')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Derse katılacak mısınız?',
                style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
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
                            onPressed: () => _submit(true)),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Hayır'),
                            onPressed: () => _submit(false)),
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
