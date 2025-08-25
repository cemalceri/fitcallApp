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

class _EventQrPageState extends State<EventQrPage> {
  EventModel? _event;
  GecisModel? _selfPass;
  List<GecisModel> _davetliler = [];
  bool _yukleniyor = true;
  String? _hata;

  // Kapat (X) için opsiyonel overlay flag (göstermiyoruz ama kalsın)
  final bool _kapatiliyor = false;

  // Davetli listesi için controller (Scrollbar assert fix)
  final ScrollController _guestCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _guestCtrl.dispose();
    super.dispose();
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const SizedBox.shrink(),
      actions: [
        if (_kapatiliyor)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          tooltip: 'Kapat',
          icon: const Icon(Icons.close),
          onPressed: _kapatiliyor ? null : _kapat,
        ),
      ],
    );
  }

  // Kapat: sadece bir önceki sayfaya dön. Profil/rol akışı ProfilSecPage’de yönetilir.
  Future<void> _kapat() async {
    if (!mounted) return;
    Navigator.maybePop(context);
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      // 1) Event
      final ApiResult<EventModel?> evRes =
          await QrEventApiService.getirEventAktifApi(userId: widget.userId);
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

      // 2) Self pass (opsiyonel)
      GecisModel? sp;
      try {
        final spRes = await QrEventApiService.getirEventSelfPassApi(
            userId: widget.userId);
        sp = spRes.data;
      } catch (_) {
        sp = null;
      }

      // 3) Davetliler
      final lstRes = await QrEventApiService.listeleEventMisafirPassApi(
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

  String _f(DateTime dt) =>
      DateFormat("dd MMMM yyyy EEEE HH:mm", "tr_TR").format(dt);

  Future<void> _paylasQrKodu(String code, {String? mesaj}) async {
    try {
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

      const double sizePx = 1024;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Beyaz arka plan
      final bg = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, sizePx, sizePx), bg);

      // QR'yi çiz
      painter.paint(canvas, const Size.square(sizePx));

      // PNG üret
      final img =
          await recorder.endRecording().toImage(sizePx.toInt(), sizePx.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('QR üretilemedi');

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final f =
          File('${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(f.path)], text: mesaj);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım başarısız: $e')),
      );
    }
  }

  Future<void> _davetEt() async {
    final label = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Davet Et'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Davetli adı soyadı',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.pop(ctx, c.text.trim()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('İptal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: const Text('Oluştur')),
          ],
        );
      },
    );
    if (label == null || label.isEmpty) return;

    try {
      final ApiResult<GecisModel> res =
          await QrEventApiService.olusturEventMisafirPassApi(
              userId: widget.userId, label: label);

      final created = res.data;
      if (created == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.mesaj)));
        return;
      }

      setState(() => _davetliler = [created, ..._davetliler]);

      // Sunucu ile senkron
      try {
        final lstRes = await QrEventApiService.listeleEventMisafirPassApi(
            userId: widget.userId);
        if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);
      } catch (_) {}

      await _paylasQrKodu(
        created.code,
        mesaj:
            'Merhaba ${created.label ?? label}, bu QR kod etkinlik boyunca geçerlidir.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _silDavetli(String code) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Davetlinin QR kodu iptal edilecektir.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await QrEventApiService.silEventMisafirPassApi(code: code);

      final lstRes = await QrEventApiService.listeleEventMisafirPassApi(
          userId: widget.userId);
      if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);
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

  String _kotaMetni() {
    if (_event?.maxMisafirKisiBasi == null) return '';
    return 'Bu etkinlik için ${_event!.maxMisafirKisiBasi} kişiyi davet edebilirsiniz.';
  }

  Widget _qrKutu(String code) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // ~%8 siyah
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: QrImageView(data: code, version: QrVersions.auto, size: 220),
      );

  Widget _bolumBasligi(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget wrapWithOverlay(Widget child) {
      return Stack(
        children: [
          child,
          if (_kapatiliyor)
            Positioned.fill(
              child: Container(
                color: const Color(0x66000000), // %40 siyah
                child: const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    if (_yukleniyor) {
      return wrapWithOverlay(
        Scaffold(
            appBar: _appBar(),
            body: const Center(child: CircularProgressIndicator())),
      );
    }
    if (_hata != null) {
      return wrapWithOverlay(
        Scaffold(appBar: _appBar(), body: Center(child: Text(_hata!))),
      );
    }
    if (_event == null) {
      return wrapWithOverlay(
        Scaffold(
            appBar: _appBar(),
            body: const Center(child: Text('Şu anda aktif bir event yok.'))),
      );
    }

    final ev = _event!;
    final sp = _selfPass;

    final bool kotaVar = ev.maxMisafirKisiBasi != null;
    final int davetSayisi = _davetliler.length;
    final bool kotaDoldu =
        kotaVar && (davetSayisi >= (ev.maxMisafirKisiBasi ?? 0));

    return wrapWithOverlay(
      Scaffold(
        appBar: _appBar(),
        backgroundColor: const Color(0xFFF7F6F5),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: kotaDoldu ? null : _davetEt,
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(kotaDoldu ? 'Kota doldu' : 'Davet Et'),
        ),
        body: RefreshIndicator(
          onRefresh: _yukle,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6EC1A6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ],
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.ad,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        '${_f(ev.baslangic)}${ev.mekan != null ? '  •  ${ev.mekan}' : ''}',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEFFAF6)),
                      ),
                      if (ev.maxMisafirKisiBasi != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x2EFFFFFF), // ~%18 beyaz
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _kotaMetni(),
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // QR alanı
              if (sp != null) ...[
                _bolumBasligi('Giriş için QR kodu okutunuz', Icons.qr_code_2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    children: [
                      _qrKutu(sp.code),
                      const SizedBox(height: 10),
                      const Text(
                        'Parlaklığı artırın ve kodu tamamen gösterin.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Davetliler
              _bolumBasligi('Davetli Listem', Icons.people_alt),
              const SizedBox(height: 8),

              if (_davetliler.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Text('Henüz davet oluşturmadınız.'),
                )
              else
                Container(
                  constraints: BoxConstraints(
                    maxHeight: math.min(
                        360, MediaQuery.of(context).size.height * 0.45),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Scrollbar(
                    controller: _guestCtrl,
                    thumbVisibility: true,
                    radius: const Radius.circular(12),
                    child: ListView.builder(
                      controller: _guestCtrl,
                      padding: const EdgeInsets.all(8),
                      itemCount: _davetliler.length,
                      shrinkWrap: true,
                      primary: false,
                      itemBuilder: (context, index) {
                        final p = _davetliler[index];
                        final adSoyad =
                            (p.label == null || p.label!.trim().isEmpty)
                                ? 'Davetli'
                                : p.label!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(adSoyad,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.black)),
                                    const SizedBox(height: 4),
                                    const Text(
                                        'Bu davet kodu etkinlik boyunca geçerlidir.',
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Paylaş',
                                onPressed: () => _paylasQrKodu(
                                  p.code,
                                  mesaj:
                                      'Merhaba $adSoyad, bu QR kod etkinlik boyunca geçerlidir.',
                                ),
                                icon: const Icon(Icons.share),
                              ),
                              IconButton(
                                tooltip: 'Sil',
                                onPressed: () => _silDavetli(p.code),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
