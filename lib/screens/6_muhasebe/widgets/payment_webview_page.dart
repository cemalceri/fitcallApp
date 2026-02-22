// lib/screens/6_muhasebe/widgets/payment_webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String siparisId;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.siparisId,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            // Sonuç sayfasına yönlenme yakalanır
            if (url.contains('/odeme/sonuc/')) {
              final basarili = url.contains('durum=basarili');
              // WebView'ı kapat, sonucu döndür
              Navigator.pop(context, basarili);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenli Ödeme'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödemeyi İptal Et'),
        content: const Text(
          'Ödeme işleminden çıkmak istediğinize emin misiniz? İşlem tamamlanmayacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Devam Et'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // dialog kapat
              Navigator.pop(context, false); // webview kapat, başarısız döndür
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }
}
