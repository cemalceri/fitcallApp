import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/auth/login_model.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QRKodPage extends StatefulWidget {
  const QRKodPage({Key? key}) : super(key: key);

  @override
  State<QRKodPage> createState() => _QRKodPageState();
}

class _QRKodPageState extends State<QRKodPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  String scanResult = ''; // Taranan kodu ekranda göstermek için
  bool isProcessing =
      false; // Aynı kodun arka arkaya okunmasını engellemek için

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;

    // Kameradan gelen tarama sonuçlarını dinliyoruz
    controller!.scannedDataStream.listen((scanData) async {
      if (!isProcessing) {
        isProcessing = true;

        final code = scanData.code ?? '';
        setState(() {
          scanResult = code;
        });

        // Tarama sonrası Django'ya POST isteği at
        await _postToDjango(code);

        // Birkaç saniye bekleyip tekrar taramaya izin ver
        await Future.delayed(const Duration(seconds: 2));
        isProcessing = false;
      }
    });
  }

  /// Django'ya tarama sonuçlarını gönderen method
  ///
  /// - 200 dönerse: Sayfayı kapat (Navigator.pop).
  /// - 400 dönerse: Uyarı göster, tekrar okutmaya devam et.
  /// - Diğer durumlar: Genel bir hata mesajı göster.
  Future<void> _postToDjango(String code) async {
    try {
      // SharedPreferences'tan kullanıcı bilgisi alalım.
      final sp = await SharedPreferences.getInstance();
      final kullaniciJson = sp.getString('kullanici');

      // Eğer kullanıcı kaydı yoksa user_id olarak örneğin '0' gönderilebilir.
      // Normalde login olmuş kullanıcı bilgisi parse edilmelidir.
      String userId = '0';
      if (kullaniciJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(kullaniciJson);
        final userModel = UserModel.fromJson(userMap);
        userId = userModel.id.toString();
      }

      // Django'ya POST isteği
      final url = Uri.parse(qrInOrOut); // common/api_urls.dart içinde tanımlı
      final response = await http.post(url, body: {
        'user_id': userId,
        'guid': code,
      });

      if (response.statusCode == 200) {
        // Başarılı durum: sayfayı kapatıyoruz
        if (!mounted) return;
        Navigator.pop(context);
      } else if (response.statusCode == 400) {
        // Kullanıcıya hatalı kod uyarısı gösterelim
        if (!mounted) return;
        _showAlertDialog(
          context: context,
          title: 'Geçersiz Kod',
          message: 'Kod geçerli değil, lütfen tekrar deneyin.',
        );
      } else {
        // Diğer durumlar (örneğin sunucu hatası vb.)
        if (!mounted) return;
        _showAlertDialog(
          context: context,
          title: 'Hata',
          message: 'Bir hata oluştu. Hata kodu: ${response.statusCode}',
        );
      }
    } catch (e) {
      // İstek atarken exception alırsa
      if (!mounted) return;
      _showAlertDialog(
        context: context,
        title: 'Hata',
        message: 'İstek sırasında bir sorun oluştu.\n$e',
      );
    }
  }

  /// Basit uyarı dialog'u
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
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),

          // Taranan kodu göstermek için alt kısım
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Taranan Kod:',
                    style: TextStyle(fontSize: 16),
                  ),
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
