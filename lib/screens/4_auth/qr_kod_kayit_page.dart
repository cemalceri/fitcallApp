// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:fitcall/models/1_common/event/gecis_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fitcall/models/4_auth/group_model.dart';

class QRKodKayitPage extends StatefulWidget {
  const QRKodKayitPage({super.key});

  @override
  State<QRKodKayitPage> createState() => _QRKodKayitPageState();
}

class _QRKodKayitPageState extends State<QRKodKayitPage>
    with SingleTickerProviderStateMixin {
  GecisModel? _selfPass;
  List<GecisModel> _davetliler = [];
  bool _yukleniyor = true;
  String? _hata;

  GroupModel? _currentGroup;
  bool _isLoadingGroup = true;

  final ScrollController _guestCtrl = ScrollController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _guestCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<int?> _getUserId() async {
    return await StorageService.getUserId();
  }

  Future<void> _init() async {
    _currentGroup = await StorageService.groupBilgileriniGetir();
    setState(() => _isLoadingGroup = false);
    await _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final userId = await _getUserId();
      if (userId == null) {
        setState(() {
          _hata = "Kullanıcı bulunamadı";
          _yukleniyor = false;
        });
        return;
      }

      final spRes =
          await QrCodeApiService.kullaniciIcinQROlustursApi(userId: userId);
      final sp = spRes.data;

      final lstRes = await QrCodeApiService.listeleTesisMisafirPassApi(
        userId: userId,
      );
      final liste = lstRes.data ?? <GecisModel>[];

      // Süresi geçmiş misafirleri filtrele
      final now = DateTime.now();
      final aktifListe = liste.where((p) => p.expiresAt.isAfter(now)).toList();

      setState(() {
        _selfPass = sp;
        _davetliler = aktifListe;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat("dd MMM yyyy, HH:mm", "tr_TR").format(dt.toLocal());

  String _formatDateShort(DateTime dt) =>
      DateFormat("dd MMM, HH:mm", "tr_TR").format(dt.toLocal());

  Duration _kalanSure(DateTime expiresAt) {
    return expiresAt.difference(DateTime.now());
  }

  String _kalanSureText(DateTime expiresAt) {
    final kalan = _kalanSure(expiresAt);
    if (kalan.isNegative) return 'Süresi doldu';

    if (kalan.inDays > 0) {
      return '${kalan.inDays} gün ${kalan.inHours % 24} saat kaldı';
    } else if (kalan.inHours > 0) {
      return '${kalan.inHours} saat ${kalan.inMinutes % 60} dk kaldı';
    } else {
      return '${kalan.inMinutes} dakika kaldı';
    }
  }

  Color _kalanSureRenk(DateTime expiresAt) {
    final kalan = _kalanSure(expiresAt);
    if (kalan.isNegative) return Colors.red;
    if (kalan.inHours < 1) return Colors.orange;
    if (kalan.inHours < 24) return Colors.amber.shade700;
    return Colors.green;
  }

  Future<void> _paylasQrKodu(String code, {String? mesaj}) async {
    try {
      // QR boyutu ve padding ayarları - daha büyük QR
      const double qrSize = 400.0;
      const double padding = 50.0;
      const double totalSize = qrSize + (padding * 2);

      final painter = QrPainter(
        data: code,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Beyaz arka plan (tüm alan)
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalSize, totalSize),
        bgPaint,
      );

      // QR'ı padding ile ortala
      canvas.save();
      canvas.translate(padding, padding);
      painter.paint(canvas, Size.square(qrSize));
      canvas.restore();

      // PNG'ye çevir
      final img = await recorder
          .endRecording()
          .toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('QR üretilemedi');

      final bytes = byteData.buffer.asUint8List();

      // Geçici dosyaya kaydet
      final dir = await getTemporaryDirectory();
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final f = File('${dir.path}/$fileName');
      await f.writeAsBytes(bytes, flush: true);

      // iPad için share sheet konumu
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 0, 0);

      // Paylaş
      await SharePlus.instance.share(
        ShareParams(
          text: mesaj,
          files: [XFile(f.path)],
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Paylaşım başarısız: $e');
    }
  }

  Future<void> _davetEt() async {
    HapticFeedback.lightImpact();

    final groupName = _currentGroup?.name ?? '';
    final durationsForUye = const [5, 60, 60 * 24];
    final durationsForYonetici = const [5, 60, 60 * 24, 60 * 24 * 7];
    final List<int> options = (groupName == 'yonetici' || groupName == 'cafe')
        ? durationsForYonetici
        : durationsForUye;

    final sonuc = await showModalBottomSheet<_YeniMisafirInput?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DavetBottomSheet(options: options),
    );

    if (sonuc == null) return;

    try {
      final userId = await _getUserId();
      if (userId == null) return;

      final ApiResult<GecisModel> res =
          await QrCodeApiService.olusturTesisMisafirPassApi(
        userId: userId,
        label: sonuc.label,
        minutes: sonuc.minutes,
      );

      final created = res.data;
      if (created == null) {
        if (!mounted) return;
        ShowMessage.error(context, res.mesaj);
        return;
      }

      // Listeyi güncelle
      try {
        final lstRes =
            await QrCodeApiService.listeleTesisMisafirPassApi(userId: userId);
        if (lstRes.data != null) {
          final now = DateTime.now();
          final aktifListe =
              lstRes.data!.where((p) => p.expiresAt.isAfter(now)).toList();
          setState(() => _davetliler = aktifListe);
        }
      } on ApiException {
        ShowMessage.error(
            context, 'Davet oluşturuldu ancak liste güncellenemedi.');
      }

      await _paylasQrKodu(
        created.code,
        mesaj: _paylasMetni(created.label, created.expiresAt),
      );
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      return;
    }
  }

  Future<void> _silDavetli(GecisModel pass) async {
    HapticFeedback.lightImpact();

    final onay = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SilOnaySheet(label: _kisiEtiketi(pass.label)),
    );

    if (onay != true) return;

    try {
      final userId = await _getUserId();
      if (userId == null) return;
      await QrCodeApiService.silTesisMisafirPassApi(
          userId: userId, code: pass.code);

      final lstRes =
          await QrCodeApiService.listeleTesisMisafirPassApi(userId: userId);
      if (lstRes.data != null) {
        final now = DateTime.now();
        final aktifListe =
            lstRes.data!.where((p) => p.expiresAt.isAfter(now)).toList();
        setState(() => _davetliler = aktifListe);
      }

      if (!mounted) return;
      ShowMessage.success(context, "Davet silindi.");
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
      return;
    } catch (e) {
      ShowMessage.error(context, 'Hata: $e');
      return;
    }
  }

  String _kisiEtiketi(String? raw) {
    final t = (raw ?? '').trim();
    return t.isEmpty ? 'Misafir' : t;
  }

  String _paylasMetni(String? label, DateTime expiresAt) {
    final adSoyad = _kisiEtiketi(label);
    final bitisTarihi = _formatDateTime(expiresAt);
    return '''
🎾 Binay Tenis Akademi - Misafir Girişi

Merhaba $adSoyad,

Bu QR kod ile tesise giriş yapabilirsiniz.

📅 Geçerlilik: $bitisTarihi tarihine kadar

📍 Kullanım: QR kodu kapıdaki okuyucuya gösterin.

İyi günler dileriz!
''';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingGroup || _yukleniyor) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('QR kodlar yükleniyor...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_hata != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.error.withValues(alpha: 0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(_hata!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _yukle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D6B).withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(colorScheme),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 20),
                      if (_selfPass != null) ...[
                        _buildSelfPassSection(colorScheme),
                        const SizedBox(height: 24),
                      ],
                      _buildGuestSection(colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Kod ile Giriş',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Tesis giriş yönetimi',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _yukle,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF2E7D6B),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D6B), Color(0xFF4CAF93)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D6B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Tesis Girişi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'QR kodunuzu kapıdaki okuyucuya göstererek tesise giriş yapabilirsiniz.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfPassSection(ColorScheme colorScheme) {
    final sp = _selfPass!;
    final kalanRenk = _kalanSureRenk(sp.expiresAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kişisel QR Kodunuz', Icons.person_outline),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // QR Container with animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF2E7D6B).withValues(
                          alpha: 0.2 + (_pulseController.value * 0.15),
                        ),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D6B).withValues(
                            alpha: 0.1 + (_pulseController.value * 0.1),
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: sp.code,
                      version: QrVersions.auto,
                      size: 260,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Durum Bilgisi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kalanRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kalanRenk.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: kalanRenk),
                    const SizedBox(width: 8),
                    Text(
                      _kalanSureText(sp.expiresAt),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kalanRenk,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Bitiş: ${_formatDateTime(sp.expiresAt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              // İpucu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ekran parlaklığını artırarak QR kodun daha kolay okunmasını sağlayın.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle(
                  'Misafir Davetlerim', Icons.people_outline),
            ),
            if (_davetliler.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_davetliler.length} kişi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D6B),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_davetliler.isEmpty)
          _buildEmptyGuestState(colorScheme)
        else
          _buildGuestList(colorScheme),
      ],
    );
  }

  Widget _buildEmptyGuestState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz misafir yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aşağıdaki butona tıklayarak\nmisafir davet edebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestList(ColorScheme colorScheme) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: math.min(400, MediaQuery.of(context).size.height * 0.45),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Scrollbar(
          controller: _guestCtrl,
          thumbVisibility: true,
          radius: const Radius.circular(12),
          child: ListView.separated(
            controller: _guestCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: _davetliler.length,
            shrinkWrap: true,
            primary: false,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pass = _davetliler[index];
              return _GuestCard(
                pass: pass,
                label: _kisiEtiketi(pass.label),
                kalanSure: _kalanSureText(pass.expiresAt),
                kalanRenk: _kalanSureRenk(pass.expiresAt),
                bitisTarihi: _formatDateShort(pass.expiresAt),
                onShare: () => _paylasQrKodu(
                  pass.code,
                  mesaj: _paylasMetni(pass.label, pass.expiresAt),
                ),
                onDelete: () => _silDavetli(pass),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2E7D6B)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D6B).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _davetEt,
        backgroundColor: const Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Misafir Davet Et',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Guest Card Widget                             */
/* -------------------------------------------------------------------------- */

class _GuestCard extends StatelessWidget {
  final GecisModel pass;
  final String label;
  final String kalanSure;
  final Color kalanRenk;
  final String bitisTarihi;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _GuestCard({
    required this.pass,
    required this.label,
    required this.kalanSure,
    required this.kalanRenk,
    required this.bitisTarihi,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D6B),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kalanRenk,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        kalanSure,
                        style: TextStyle(
                          fontSize: 12,
                          color: kalanRenk,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Bitiş: $bitisTarihi',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.share_rounded,
                color: const Color(0xFF2E7D6B),
                onTap: onShare,
                tooltip: 'Paylaş',
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                color: colorScheme.error,
                onTap: onDelete,
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Davet Bottom Sheet                               */
/* -------------------------------------------------------------------------- */

class _DavetBottomSheet extends StatefulWidget {
  final List<int> options;

  const _DavetBottomSheet({required this.options});

  @override
  State<_DavetBottomSheet> createState() => _DavetBottomSheetState();
}

class _DavetBottomSheetState extends State<_DavetBottomSheet> {
  final _controller = TextEditingController();
  late int _secili;

  @override
  void initState() {
    super.initState();
    _secili = widget.options.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _minsToLabel(int m) {
    if (m < 60) return '$m dakika';
    if (m == 60) return '1 saat';
    if (m % (60 * 24 * 7) == 0) return '${m ~/ (60 * 24 * 7)} hafta';
    if (m % (60 * 24) == 0) return '${m ~/ (60 * 24)} gün';
    return '${(m / 60).round()} saat';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Color(0xFF2E7D6B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Misafir Davet Et',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tesise giriş için QR kod oluşturun',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // İsim alanı
                  Text(
                    'Misafir Adı *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Örn: Ahmet Yılmaz',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF2E7D6B), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Süre seçimi
                  Text(
                    'Geçerlilik Süresi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.options.map((m) {
                      final isSelected = m == _secili;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _secili = m),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2E7D6B)
                                  : const Color(0xFF2E7D6B)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2E7D6B)
                                    : const Color(0xFF2E7D6B)
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _minsToLabel(m),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2E7D6B),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _controller.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(
                                    context,
                                    _YeniMisafirInput(
                                      _controller.text.trim(),
                                      _secili,
                                    ),
                                  ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D6B),
                            disabledBackgroundColor:
                                const Color(0xFF2E7D6B).withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'QR Oluştur',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            Silme Onay Sheet                                */
/* -------------------------------------------------------------------------- */

class _SilOnaySheet extends StatelessWidget {
  final String label;

  const _SilOnaySheet({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 36,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daveti Sil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$label" için oluşturulan QR kod iptal edilecek ve artık kullanılamayacak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Sil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Helper Classes                                */
/* -------------------------------------------------------------------------- */

class _YeniMisafirInput {
  final String label;
  final int minutes;
  _YeniMisafirInput(this.label, this.minutes);
}
