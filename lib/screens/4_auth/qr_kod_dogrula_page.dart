import 'dart:io';
import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class QRKodDogrulaPage extends StatefulWidget {
  const QRKodDogrulaPage({super.key});

  @override
  State<QRKodDogrulaPage> createState() => _QRKodDogrulaPageState();
}

class _QRKodDogrulaPageState extends State<QRKodDogrulaPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? _apiResponse;
  bool _isScanningPaused = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (!_isScanningPaused) {
        _isScanningPaused = true;
        // Tarama yapıldıktan sonra taranan QR kodu API'ye gönderip cevabı alıyoruz.
        String responseMessage = await _postScannedQR(scanData.code ?? '');
        if (mounted) {
          setState(() {
            _apiResponse = responseMessage;
          });
          controller!.pauseCamera();
        }
      }
    });
  }

  /// Tarana QR kodu, API'ye POST eder ve cevabı uygun formatta döndürür.
  Future<String> _postScannedQR(String code) async {
    try {
      final response = await http.post(
        Uri.parse(getQRKodBilgisi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr_code': code}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API'den dönen veriler:
        // "message": hoş geldiniz mesajı,
        // "gecerlilik_suresi": QR kod geçerlilik tarihi,
        // "kalan_giris_hakki_sayisi": kalan giriş hakkı.
        final welcomeMessage = data['message'] ?? 'Hoşgeldiniz!';
        final expiration = data['gecerlilik_suresi'] ?? '';
        final remaining = data['kalan_giris_hakki_sayisi'];

        String result = "$welcomeMessage\n\nGeçerlilik Süresi: $expiration";
        if (remaining != null && remaining is int && remaining > 0) {
          result +=
              "\n\nBu QR kod ile $remaining kadar daha giriş yapabilirsiniz.";
        }
        return result;
      } else {
        return 'Hata: ${response.statusCode}';
      }
    } catch (e) {
      return 'Hata: $e';
    }
  }

  /// "Kapat" butonuna basınca overlay'i kapatıp okuma işlemini yeniden başlatır.
  void _closeOverlay() {
    setState(() {
      _apiResponse = null;
      _isScanningPaused = false;
    });
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Okuyucu'),
      ),
      body: Stack(
        children: [
          // Kamera üzerinden QR kod okuma widget'ı
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blueAccent,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          // API cevabını gösteren overlay; ekranın layout'unu etkilemeden sabit konumda.
          if (_apiResponse != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha((0.7 * 255).toInt()),
                child: Center(
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'QR Kod Sonucu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _apiResponse!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _closeOverlay,
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
