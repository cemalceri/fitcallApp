// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:fitcall/models/1_common/qr_kod_models.dart';
import 'package:fitcall/screens/1_common/widgets/qr_sonuc_gorunumu.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fitcall/services/core/izin_durumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/api_result.dart';

class QRKodDogrulaPage extends StatefulWidget {
  const QRKodDogrulaPage({super.key});

  @override
  State<QRKodDogrulaPage> createState() => _QRKodDogrulaPageState();
}

enum _ScanPhase { idle, scanning, result }

class _QRKodDogrulaPageState extends State<QRKodDogrulaPage> {
  late MobileScannerController _controller;
  _ScanPhase _phase = _ScanPhase.idle;
  bool _busy = false;

  /// Ekranın çizeceği sonuç. Hem başarıyı hem hata sebebini tek tip taşır;
  /// eskiden ayrı `_result`/`_errorMessage` alanları vardı ve hata kodu
  /// kaybolduğu için her hata aynı gri "Bilgi" kartına düşüyordu.
  QrSonucu? _sonuc;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _phase = _ScanPhase.scanning;
      _sonuc = null;
      _busy = false;
    });
    try {
      // Kamera iznini mobile_scanner'ın kendisi soruyor; damgayı biz bırakıyoruz
      // ki cihaz kaydında "sorulmadı" ile "reddedildi" ayırt edilebilsin.
      await IzinSorgusu.isaretle(IzinAnahtari.kamera);
      await _controller.start();
    } catch (_) {
      setState(() {
        _phase = _ScanPhase.result;
        _sonuc = QrSonucu(
          tip: QrSonucTipi.hata,
          mesaj: 'Kamera başlatılamadı.',
          zaman: DateTime.now(),
        );
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _handleCode(String code) async {
    if (_busy) return;
    _busy = true;
    await _stopScan();

    try {
      final ApiResult<QrKodVerifyResponse> res =
          await QrCodeApiService.qrKodDogrulaApi(kod: code);

      final cevap = res.data;
      setState(() {
        _sonuc = QrSonucu(
          tip: (cevap?.success ?? false)
              ? QrSonucTipi.basarili
              : QrSonucTipi.hata,
          mesaj: cevap?.message ?? 'QR kod doğrulanamadı.',
          zaman: DateTime.now(),
        );
        _phase = _ScanPhase.result;
      });
    } on ApiException catch (e) {
      setState(() {
        _sonuc = QrSonucu.hatadan(e);
        _phase = _ScanPhase.result;
      });
    } catch (_) {
      setState(() {
        _sonuc = QrSonucu(
          tip: QrSonucTipi.hata,
          mesaj: 'QR kod doğrulanamadı.',
          zaman: DateTime.now(),
        );
        _phase = _ScanPhase.result;
      });
    } finally {
      _busy = false;
    }
  }

  // Modern overlay – ortada tarama penceresi
  Widget _scannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final side = size.width * 0.78;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.35),
      width: side,
      height: side,
    );

    return Stack(
      children: [
        // Yumuşak blur + karartma
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: Colors.black.withAlpha((0.25 * 255).toInt()),
            ),
          ),
        ),
        // Kesik pencere
        IgnorePointer(
          child: CustomPaint(
            painter: _ScannerHolePainter(rect),
            child: const SizedBox.expand(),
          ),
        ),
        // Köşe çerçeveleri
        IgnorePointer(
          child: CustomPaint(
            painter: _ScannerBorderPainter(rect),
            child: const SizedBox.expand(),
          ),
        ),
        // Üst açıklama
        Positioned(
          left: 24,
          right: 24,
          top: size.height * 0.12,
          child: Column(
            children: const [
              Text(
                'QR Kodu Merkeze Getir',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Kod otomatik olarak okunacaktır',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: Color(0xFFEFEFEF)),
              ),
            ],
          ),
        ),
        // Sağ üst: İptal
        Positioned(
          right: 12,
          top: 12,
          child: IconButton(
            onPressed: () async {
              await _stopScan();
              if (!mounted) return;
              setState(() => _phase = _ScanPhase.idle);
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'İptal',
          ),
        ),
      ],
    );
  }

  Widget _idleView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner,
              size: 112, color: Color(0xFF2F6B5F)),
          const SizedBox(height: 18),
          const Text('QR Kod Doğrulama',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            'Başlamak için aşağıdaki “Tara” butonuna dokunun.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.5, color: Colors.black54),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.center_focus_strong),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
              child: Text('Tara',
                  style:
                      TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_busy) return;
            final codes = capture.barcodes;
            if (codes.isEmpty) return;
            final raw = codes.first.rawValue;
            if (raw == null || raw.isEmpty) return;
            _handleCode(raw);
          },
        ),
        _scannerOverlay(context),
      ],
    );
  }
  /// Sonuç paneli. Görsel gövde [QrSonucGorunumu]'nda: kapıda uzaktan
  /// okunabilsin diye tüm ekranı kaplayan renkli panel, hata sebebine göre
  /// ayrı ikon/renk ve "şimdi ne yapmalı" satırı.
  Widget _resultView() {
    final sonuc = _sonuc ??
        QrSonucu(
          tip: QrSonucTipi.gecersiz,
          mesaj: 'QR kod okunamadı.',
          zaman: DateTime.now(),
        );

    return QrSonucGorunumu(
      sonuc: sonuc,
      onYenidenTara: _startScan,
      onBitir: () => Navigator.of(context).maybePop(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Doğrula'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: () {
          switch (_phase) {
            case _ScanPhase.idle:
              return Center(child: _idleView());
            case _ScanPhase.scanning:
              return _scannerView();
            case _ScanPhase.result:
              return SingleChildScrollView(child: _resultView());
          }
        }(),
      ),
    );
  }
}

/// Arka planı karartırken ortada bir pencere aç
class _ScannerHolePainter extends CustomPainter {
  final Rect rect;
  _ScannerHolePainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withAlpha((0.35 * 255).toInt());
    final hole = Path()..addRect(rect);
    final full = Path()..addRect(Offset.zero & size);
    final diff = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(diff, bg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kenarlara modern çerçeve
class _ScannerBorderPainter extends CustomPainter {
  final Rect rect;
  _ScannerBorderPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final corner = 30.0;
    final stroke = 5.0;
    final p = Paint()
      ..color = const Color(0xFF4DB6AC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Dört köşe L çizgileri
    // Sol üst
    canvas.drawLine(
        Offset(rect.left, rect.top + corner), Offset(rect.left, rect.top), p);
    canvas.drawLine(
        Offset(rect.left, rect.top), Offset(rect.left + corner, rect.top), p);
    // Sağ üst
    canvas.drawLine(
        Offset(rect.right - corner, rect.top), Offset(rect.right, rect.top), p);
    canvas.drawLine(
        Offset(rect.right, rect.top), Offset(rect.right, rect.top + corner), p);
    // Sol alt
    canvas.drawLine(Offset(rect.left, rect.bottom - corner),
        Offset(rect.left, rect.bottom), p);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + corner, rect.bottom), p);
    // Sağ alt
    canvas.drawLine(Offset(rect.right - corner, rect.bottom),
        Offset(rect.right, rect.bottom), p);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - corner), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
