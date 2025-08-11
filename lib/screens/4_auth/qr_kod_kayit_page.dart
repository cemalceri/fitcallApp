// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/4_auth/group_model.dart';

class QRKodKayitPage extends StatefulWidget {
  const QRKodKayitPage({super.key});

  @override
  State<QRKodKayitPage> createState() => _QRKodKayitState();
}

class _QRKodKayitState extends State<QRKodKayitPage> {
  // QR verileri
  String _generatedCode = '';
  String? _validityTime;
  String? _passCount;

  // Kullanıcı grubu
  GroupModel? _currentGroup; // groupBilgileriniGetir(context) sonucu
  bool _isLoadingGroup = true;

  // Ekrandaki seçimler
  bool _isMisafirSecildi = false;
  String _selectedSure = '5dk'; // Varsayılan
  int _kullanimSayisi = 1; // Yonetici/cafe misafir girebilir

  // Bu key, QrImageView’i kaydedebilmemiz için gerekli
  final GlobalKey _qrBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initGroup();
  }

  Future<void> _initGroup() async {
    _currentGroup = await AuthService.groupBilgileriniGetir();
    setState(() {
      _isLoadingGroup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGroup) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod İle Giriş'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // (1) Giriş mi, Misafir mi seçimi
              _buildQrTypeSelection(),
              const SizedBox(height: 16),

              // (2) Misafir seçildiyse süre seçenekleri
              if (_isMisafirSecildi) _buildMisafirSureSecimi(),

              // (3) Eğer user group = yonetici veya cafe ve misafir seçiliyse => kullanım sayısı (1-5 arası combobox)
              if (_isMisafirSecildi &&
                  (_currentGroup!.name == 'yonetici' ||
                      _currentGroup!.name == 'cafe')) ...[
                const SizedBox(height: 16),
                _buildKullanimSayisiDropdown(),
              ],
              const SizedBox(height: 24),

              // (4) Oluşturulmuş QR kod görüntüsü
              if (_generatedCode.isNotEmpty) _buildQrResult(),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget: Giriş veya Misafir seçimi (ChoiceChip)
  Widget _buildQrTypeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Giriş QR Oluştur'),
          selected: !_isMisafirSecildi,
          onSelected: (val) {
            setState(() {
              _isMisafirSecildi = false;
            });
            _generateQrCode(); // Seçim değişince anında QR oluştur
          },
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Misafir QR Oluştur'),
          selected: _isMisafirSecildi,
          onSelected: (val) {
            setState(() {
              _isMisafirSecildi = true;
            });
            _generateQrCode(); // Seçim değişince anında QR oluştur
          },
        ),
      ],
    );
  }

  /// Widget: Misafir Süre Seçimi (ChoiceChip)
  Widget _buildMisafirSureSecimi() {
    final groupName = _currentGroup!.name;
    final durationsForUye = ['5dk', '1saat', '1gun'];
    final durationsForYonetici = ['5dk', '1saat', '1gun', '1hafta'];

    final list = (groupName == 'yonetici' || groupName == 'cafe')
        ? durationsForYonetici
        : durationsForUye;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: list.map((sure) {
        return ChoiceChip(
          label: Text(sure),
          selected: _selectedSure == sure,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedSure = sure;
              });
              _generateQrCode(); // Süre değişince de QR otomatik güncellenir
            }
          },
        );
      }).toList(),
    );
  }

  /// Widget: Yönetici / Cafe misafir kullanım sayısı combo
  Widget _buildKullanimSayisiDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Kullanım Hakkı: '),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _kullanimSayisi,
          items: [1, 2, 3, 4, 5].map((val) {
            return DropdownMenuItem<int>(
              value: val,
              child: Text('$val'),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _kullanimSayisi = val;
            });
            _generateQrCode(); // Kullanım hakkı değişince de yeniden oluştur
          },
        ),
      ],
    );
  }

  /// Widget: Oluşmuş QR Kodu & Bilgiler & (misafir ise paylaş)
  Widget _buildQrResult() {
    return Column(
      children: [
        // QrImage'ı RepaintBoundary içine alıyoruz ki resmi paylaşabilelim
        RepaintBoundary(
          key: _qrBoundaryKey,
          // Arka plana beyaz veriyoruz ki siyah resim olarak görünmesin
          child: Container(
            color: Colors.white,
            child: QrImageView(
              data: _generatedCode,
              version: QrVersions.auto,
              size: 300.0, // QR biraz daha büyük
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_validityTime != null)
          Text(
            'Geçerlilik Süresi: $_validityTime',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (_passCount != null) ...[
          const SizedBox(height: 8),
          Text(
            'Geçiş Hakkı: $_passCount',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],

        // Misafir ise paylaş butonu
        if (_isMisafirSecildi) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _shareQrAsImage,
            icon: const Icon(Icons.share),
            label: const Text('QR Kodunu Paylaş'),
          ),
        ],
      ],
    );
  }

  /// Misafir QR’ı resim olarak paylaşmak
  Future<void> _shareQrAsImage() async {
    try {
      // 1) RepaintBoundary'yi bul
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // 2) Görseli UI Image olarak al
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // 3) ByteData -> Uint8List (PNG)
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // 4) Geçici dizine kaydet
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qrcode.png');
      await file.writeAsBytes(pngBytes);

      // 5) share_plus ile paylaş
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Merhaba! Bu QR Kod ile $_validityTime tarihine kadar $_passCount kez giriş yapabilirsiniz.',
      );
    } catch (e) {
      debugPrint('Hata (QR paylaşırken): $e');
      ShowMessage.error(context, 'QR Kod paylaşılamadı!');
    }
  }

  /// QR Oluşturma & Sunucuya Gönderme
  Future<void> _generateQrCode() async {
    try {
      final token = await AuthService.getToken();
      final newCode = _generateUuid();

      // Geçerlilik süresi (dakika)
      int minutesToAdd = 5; // Giriş seçimi = 5 dk
      if (_isMisafirSecildi) {
        switch (_selectedSure) {
          case '5dk':
            minutesToAdd = 5;
            break;
          case '1saat':
            minutesToAdd = 60;
            break;
          case '1gun':
            minutesToAdd = 60 * 24;
            break;
          case '1hafta':
            minutesToAdd = 60 * 24 * 7;
            break;
          default:
            minutesToAdd = 5;
        }
      }

      // Kullanım hakkı
      int usageCount = 1; // Normalde tek
      if (_isMisafirSecildi &&
          (_currentGroup!.name == 'yonetici' ||
              _currentGroup!.name == 'cafe')) {
        usageCount = _kullanimSayisi;
      }

      final payload = {
        'kod': newCode,
        'misafir_mi': _isMisafirSecildi,
        'gecerlilik_suresi_dakika': minutesToAdd,
        'giris_hakki_sayisi': usageCount,
      };

      final response = await http.post(
        Uri.parse(setQRKodBilgisi),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _generatedCode = newCode;
          _validityTime = data['gecerlilik_suresi']?.toString();
          _passCount = data['kalan_giris_hakki_sayisi']?.toString();
        });
      } else {
        ShowMessage.error(context, 'QR Kod oluşturulamadı!');
      }
    } catch (e) {
      ShowMessage.error(context, 'QR Kod oluşturulamadı!');
    }
  }

  /// Basit UUID v4 üretimi
  String _generateUuid() {
    final rnd = Random.secure();
    const template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

    return template.replaceAllMapped(RegExp('[xy]'), (match) {
      final r = rnd.nextInt(16);
      final v = (match[0] == 'x') ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }
}
