import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QRKodPage extends StatefulWidget {
  const QRKodPage({super.key});

  @override
  State<QRKodPage> createState() => _QRKodPageState();
}

class _QRKodPageState extends State<QRKodPage> {
  final MobileScannerController _cameraController = MobileScannerController();

  bool isProcessing = false; // Aynı kodu tekrar tekrar işlememek için
  String scanResult = ''; // Ekranda göstermek için taranan kod

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  /// Tarama gerçekleştiğinde tetiklenen SENKRON callback.
  /// Asenkron işlemleri `_processCaptureAsync` fonksiyonuna devrediyoruz.
  void _onDetect(BarcodeCapture capture) {
    // capture.barcodes listesinde bir veya birden fazla barkod/QR olabilir
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;

    if (code == null) return; // Geçerli data yoksa çık
    if (!isProcessing) {
      isProcessing = true;
      setState(() {
        scanResult = code;
      });

      // Asenkron iş (HTTP isteği vb.) için ayrı fonksiyon:
      _processCaptureAsync(code);
    }
  }

  /// QR kodu veya barkodu yakaladıktan sonra asenkron işlemleri yöneteceğimiz fonksiyon.
  Future<void> _processCaptureAsync(String code) async {
    try {
      // Örnek: SharedPreferences'tan kullanıcı bilgisi
      final sp = await SharedPreferences.getInstance();
      final kullaniciJson = sp.getString('kullanici');

      String uyeId = '0'; // Eğer kayıt yoksa varsayılan ID
      if (kullaniciJson != null) {
        final user = UserModel.fromJson(json.decode(kullaniciJson));
        uyeId = user.id.toString();
      }

      // Django endpoint'iniz (örnek):
      final url = Uri.parse(qrInOrOut);

      // POST isteği
      final response = await http.post(url, body: {
        'uye_id': uyeId,
        'guid': code,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Başarılı -> sayfayı kapatıyoruz
        Navigator.pop(context);
      } else if (response.statusCode == 400) {
        // Geçersiz kod
        _showAlertDialog(
          context: context,
          title: 'Geçersiz Kod',
          message: 'Kod geçerli değil, lütfen tekrar deneyin.',
        );
      } else {
        // Diğer durumlar
        _showAlertDialog(
          context: context,
          title: 'Hata',
          message:
              'Bir hata oluştu. Kod: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAlertDialog(
        context: context,
        title: 'Hata',
        message: 'Bir sorun oluştu.\n$e',
      );
    }

    // 2 saniye bekleyip tekrar taramaya izin verelim
    await Future.delayed(const Duration(seconds: 2));
    isProcessing = false;
  }

  /// Basit diyalog gösteren yardımcı fonksiyon
  void _showAlertDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Okuyucu'),
      ),
      body: Column(
        children: [
          // Kameranın bulunduğu alan
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _cameraController,
              // allowDuplicates parametresi kaldırıldığı için yok.
              onDetect: _onDetect, // senkron callback
            ),
          ),
          // Taranan kodu basitçe göstermek için alt kısım
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Taranan Kod:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    scanResult,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
