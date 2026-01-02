// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/models/1_common/event/gecis_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class EventQrPage extends StatefulWidget {
  final int userId;
  const EventQrPage({super.key, required this.userId});

  @override
  State<EventQrPage> createState() => _EventQrPageState();
}

class _EventQrPageState extends State<EventQrPage>
    with SingleTickerProviderStateMixin {
  EventModel? _event;
  GecisModel? _selfPass;
  List<GecisModel> _davetliler = [];
  bool _yukleniyor = true;
  String? _hata;

  final ScrollController _guestCtrl = ScrollController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _yukle();
  }

  @override
  void dispose() {
    _guestCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final ApiResult<EventModel?> evRes =
          await QrCodeApiService.getirEventAktifApi(userId: widget.userId);
      final ev = evRes.data;
      if (ev == null) {
        setState(() {
          _event = null;
          _selfPass = null;
          _davetliler = [];
          _yukleniyor = false;
        });
        return;
      }

      GecisModel? sp;
      try {
        final spRes =
            await QrCodeApiService.getirEventSelfPassApi(userId: widget.userId);
        sp = spRes.data;
      } catch (_) {
        sp = null;
      }

      final lstRes = await QrCodeApiService.listeleEventMisafirPassApi(
          userId: widget.userId);
      final liste = lstRes.data ?? <GecisModel>[];

      setState(() {
        _event = ev;
        _selfPass = sp;
        _davetliler = liste;
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
      DateFormat("dd MMMM yyyy, HH:mm", "tr_TR").format(dt.toLocal());

  String _kotaMetni() {
    if (_event?.maxMisafirKisiBasi == null) return '';
    final kalan = (_event!.maxMisafirKisiBasi ?? 0) - _davetliler.length;
    return '$kalan davet hakkınız kaldı';
  }

  Future<void> _paylasQrKodu(String code, {String? mesaj}) async {
    try {
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

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalSize, totalSize),
        bgPaint,
      );

      canvas.save();
      canvas.translate(padding, padding);
      painter.paint(canvas, Size.square(qrSize));
      canvas.restore();

      final img = await recorder
          .endRecording()
          .toImage(totalSize.toInt(), totalSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('QR üretilemedi');

      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final f = File('${dir.path}/$fileName');
      await f.writeAsBytes(bytes, flush: true);

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 0, 0);

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

    final sonuc = await showModalBottomSheet<_YeniDavetInput?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DavetBottomSheet(),
    );

    if (sonuc == null) return;

    try {
      final ApiResult<GecisModel> res =
          await QrCodeApiService.olusturEventMisafirPassApi(
        userId: widget.userId,
        label: sonuc.label,
        telefon: sonuc.telefon,
      );

      final created = res.data;
      if (created == null) {
        if (!mounted) return;
        ShowMessage.error(context, res.mesaj);
        return;
      }

      try {
        final lstRes = await QrCodeApiService.listeleEventMisafirPassApi(
            userId: widget.userId);
        if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);
      } catch (_) {}

      await _paylasQrKodu(
        created.code,
        mesaj: _paylasMetni(created.label, _event?.ad ?? 'Etkinlik'),
      );
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
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
      await QrCodeApiService.silEventMisafirPassApi(code: pass.code);

      final lstRes = await QrCodeApiService.listeleEventMisafirPassApi(
          userId: widget.userId);
      if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);

      if (!mounted) return;
      ShowMessage.success(context, "Davet silindi.");
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Hata: $e');
    }
  }

  String _kisiEtiketi(String? raw) {
    final t = (raw ?? '').trim();
    return t.isEmpty ? 'Davetli' : t;
  }

  String _paylasMetni(String? label, String eventAdi) {
    final adSoyad = _kisiEtiketi(label);
    return '''
🎉 $eventAdi - Davet

Merhaba $adSoyad,

Bu QR kod ile etkinliğe giriş yapabilirsiniz.

📍 Kullanım: QR kodu kapıdaki okuyucuya gösterin.

İyi eğlenceler!
''';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_yukleniyor) {
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
                Text('Etkinlik bilgileri yükleniyor...'),
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

    if (_event == null) {
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
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(colorScheme),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Şu anda aktif bir etkinlik yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ev = _event!;
    final sp = _selfPass;
    final bool kotaVar = ev.maxMisafirKisiBasi != null;
    final int davetSayisi = _davetliler.length;
    final bool kotaDoldu =
        kotaVar && (davetSayisi >= (ev.maxMisafirKisiBasi ?? 0));

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
                      _buildHeaderCard(ev),
                      const SizedBox(height: 20),
                      if (sp != null) ...[
                        _buildSelfPassSection(colorScheme, sp),
                        const SizedBox(height: 24),
                      ],
                      _buildGuestSection(colorScheme, kotaDoldu),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(kotaDoldu),
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
                  'Event / Davet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Etkinlik giriş yönetimi',
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

  Widget _buildHeaderCard(EventModel ev) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D6B), Color(0xFF4FAE97)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ev.ad,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              Icons.calendar_today_rounded, _formatDateTime(ev.baslangic)),
          if (ev.mekan != null && ev.mekan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_rounded, ev.mekan!),
          ],
          if (ev.maxMisafirKisiBasi != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_outlined,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _kotaMetni(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfPassSection(ColorScheme colorScheme, GecisModel sp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giriş QR Kodunuz', Icons.qr_code_scanner_rounded),
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
                      size: 220,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D6B).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: Color(0xFF2E7D6B)),
                    SizedBox(width: 8),
                    Text(
                      'Etkinlik boyunca geçerlidir.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D6B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildGuestSection(ColorScheme colorScheme, bool kotaDoldu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSectionTitle('Davetli Listem', Icons.people_outline),
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
            'Henüz davetli yok',
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
                telefon: pass.telefon,
                onShare: () => _paylasQrKodu(
                  pass.code,
                  mesaj: _paylasMetni(pass.label, _event?.ad ?? 'Etkinlik'),
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

  Widget _buildFAB(bool kotaDoldu) {
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
        onPressed: kotaDoldu ? null : _davetEt,
        backgroundColor: kotaDoldu ? Colors.grey : const Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(kotaDoldu ? Icons.block : Icons.person_add_alt_1_rounded),
        label: Text(
          kotaDoldu ? 'Kota Doldu' : 'Davet Et',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
  final String? telefon;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _GuestCard({
    required this.pass,
    required this.label,
    this.telefon,
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
                if (telefon != null && telefon!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        telefon!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Etkinlik boyunca tek kullanımlıktır.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
  const _DavetBottomSheet();

  @override
  State<_DavetBottomSheet> createState() => _DavetBottomSheetState();
}

class _DavetBottomSheetState extends State<_DavetBottomSheet> {
  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    super.dispose();
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
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            'Davet Et',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Etkinliğe misafir davet edin',
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
                Text(
                  'Ad Soyad *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _adSoyadController,
                  textCapitalization: TextCapitalization.words,
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
                      borderSide:
                          const BorderSide(color: Color(0xFF2E7D6B), width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  'Telefon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _telefonController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '05XX XXX XX XX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF2E7D6B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
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
                        onPressed: _adSoyadController.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(
                                  context,
                                  _YeniDavetInput(
                                    _adSoyadController.text.trim(),
                                    _telefonController.text.trim(),
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

class _YeniDavetInput {
  final String label;
  final String? telefon;
  _YeniDavetInput(this.label, this.telefon);
}
