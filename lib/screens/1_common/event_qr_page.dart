// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:ui' as ui;
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/models/1_common/event/gecis_model.dart';
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

  @override
  void initState() {
    super.initState();
    _yukle();
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
          _yukleniyor = false;
        });
        return;
      }

      // 2) Self pass
      final spRes =
          await QrEventApiService.getirEventSelfPassApi(userId: widget.userId);
      final sp = spRes.data;
      if (sp == null) {
        setState(() {
          _hata = spRes.mesaj;
          _yukleniyor = false;
        });
        return;
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
      );
      final uiBytes =
          await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (uiBytes == null) throw Exception('QR üretilemedi');

      final bytes = uiBytes.buffer.asUint8List();
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

      // Listeyi yenile
      final lstRes = await QrEventApiService.listeleEventMisafirPassApi(
          userId: widget.userId);
      var liste = lstRes.data ?? <GecisModel>[];

      // Backend label döndürmüyorsa: yeni oluşturulan code için label'ı yerelde set et
      liste = liste.map((e) {
        if (e.code == created.code &&
            (e.label == null || e.label!.trim().isEmpty)) {
          return GecisModel(
            kapsam: e.kapsam,
            gecisTipi: e.gecisTipi,
            eventId: e.eventId,
            code: e.code,
            expiresAt: e.expiresAt,
            iptalMi: e.iptalMi,
            label: label,
          );
        }
        return e;
      }).toList();

      setState(() => _davetliler = liste);

      // İsteğe bağlı: direkt paylaş
      await _paylasQrKodu(
        created.code,
        mesaj: 'Merhaba $label, bu QR kod etkinlik boyunca geçerlidir.',
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
      final ApiResult<bool> res =
          await QrEventApiService.silEventMisafirPassApi(
              userId: widget.userId, code: code);

      if (res.data == true) {
        final lstRes = await QrEventApiService.listeleEventMisafirPassApi(
            userId: widget.userId);
        if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silindi. Kota iade edildi.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.mesaj)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  String _kotaMetni() {
    if (_event?.maxMisafirKisiBasi == null) return '';
    return 'Bu etkinlik için ${_event!.maxMisafirKisiBasi} kişiyi davet edebilirsiniz.';
  }

  Widget _qrKutu(String code) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(.06),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: QrImageView(data: code, version: QrVersions.auto, size: 220),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_yukleniyor) {
      return Scaffold(
          appBar: AppBar(title: const Text('Etkinlik Girişi')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_hata != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Etkinlik Girişi')),
          body: Center(child: Text(_hata!)));
    }
    if (_event == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Etkinlik Girişi')),
          body: const Center(child: Text('Şu anda aktif bir event yok.')));
    }

    final ev = _event!;
    final sp = _selfPass;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Girişi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child:
                const Text('Ana Sayfam', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _davetEt,
        label: const Text('Davet Et'),
        icon: const Icon(Icons.person_add_alt_1),
      ),
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Event header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary
                ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.ad,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      // SADECE BAŞLANGIÇ TARİHİ
                      Text(
                          '${_f(ev.baslangic)}${ev.mekan != null ? '  •  ${ev.mekan}' : ''}'),
                      if (_event!.maxMisafirKisiBasi != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(24)),
                          child: Text(_kotaMetni(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
              ),
            ),

            const SizedBox(height: 16),

            // Kullanıcının QR'ı
            if (sp != null) ...[
              Text('Girişi için QR kodu okutunuz',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _qrKutu(sp.code),
                    const SizedBox(height: 12),
                    // Paylaş kaldırıldı; sadece bilgi notu kalsın
                    const Text('• Parlaklığı artırın, kodu tamamen gösterin.',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text('Davet Ettiklerim', style: theme.textTheme.titleMedium),
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
              ..._davetliler.map((p) {
                final adSoyad = (p.label == null || p.label!.trim().isEmpty)
                    ? 'Davetli'
                    : p.label!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Bu davet kodu etkinlik boyunca geçerlidir.',
                                  style: TextStyle(color: Colors.black54)),
                            ]),
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
              }),

            // ALTTAKİ KOTA METNİ KALDIRILDI (üstte gösteriliyor)
          ],
        ),
      ),
    );
  }
}
