import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class QRKodDogrulaPage extends StatefulWidget {
  const QRKodDogrulaPage({super.key});

  @override
  State<QRKodDogrulaPage> createState() => _QRKodDogrulaPageState();
}

class _QRKodDogrulaPageState extends State<QRKodDogrulaPage> {
  late MobileScannerController controller;
  String? _apiResponse;
  bool _isScanningPaused = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Tarana QR kodu, API'ye POST eder ve cevabı uygun formatta döndürür.
  Future<String> _postScannedQR(String code) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(getQRKodBilgisi),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'kod': code}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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
              "\n\nBu QR kod ile $remaining kez daha giriş yapabilirsiniz.";
        }
        return result;
      } else {
        final hataMesaji =
            jsonDecode(utf8.decode(response.bodyBytes))['message'];
        return 'Hata: ${hataMesaji ?? 'Hata oluştu.'}';
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
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Okuyucu'),
        actions: [],
      ),
      body: Stack(
        children: [
          // mobile_scanner kullanarak QR kod okuma
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isScanningPaused) {
                _isScanningPaused = true;
                final String code = barcodes.first.rawValue ?? '';
                // Tarama yapıldıktan sonra taranan QR kodu API'ye gönderip cevabı alıyoruz.
                String responseMessage = await _postScannedQR(code);
                if (mounted) {
                  setState(() {
                    _apiResponse = responseMessage;
                  });
                  controller.stop();
                }
              }
            },
            scanWindow: Rect.fromCenter(
              center: Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          // QR kod tarama için overlay
          CustomPaint(
            painter: ScannerOverlay(
              Rect.fromCenter(
                center: Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2,
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
            child: const SizedBox.expand(),
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

// Özel tarama overlay'i çizmek için CustomPainter sınıfı
class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay(this.scanWindow);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha((0.5 * 255).toInt())
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    // Ekranın tamamını yarı saydam siyahla kapla
    canvas.drawPath(backgroundPath,
        Paint()..color = Colors.black.withAlpha((0.5 * 255).toInt()));

    // Tarama penceresini kesip çıkar
    canvas.drawPath(cutoutPath, backgroundPaint);

    // Tarama penceresi etrafına mavi kenar çiz
    canvas.drawRect(scanWindow, borderPaint);

    // Köşe dekorasyonları
    final cornerSize = 30.0;

    // Sol üst köşe
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top + cornerSize),
      Offset(scanWindow.left, scanWindow.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.top),
      Offset(scanWindow.left + cornerSize, scanWindow.top),
      borderPaint,
    );

    // Sağ üst köşe
    canvas.drawLine(
      Offset(scanWindow.right - cornerSize, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.top),
      Offset(scanWindow.right, scanWindow.top + cornerSize),
      borderPaint,
    );

    // Sol alt köşe
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom - cornerSize),
      Offset(scanWindow.left, scanWindow.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.left, scanWindow.bottom),
      Offset(scanWindow.left + cornerSize, scanWindow.bottom),
      borderPaint,
    );

    // Sağ alt köşe
    canvas.drawLine(
      Offset(scanWindow.right - cornerSize, scanWindow.bottom),
      Offset(scanWindow.right, scanWindow.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanWindow.right, scanWindow.bottom),
      Offset(scanWindow.right, scanWindow.bottom - cornerSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) => false;
}
