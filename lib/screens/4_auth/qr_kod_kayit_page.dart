// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:fitcall/models/1_common/event/gecis_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/api_result.dart';
// Mevcut servisi korudum; istersen QrPassApiService'e geçebiliriz.
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';
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

class _QRKodKayitPageState extends State<QRKodKayitPage> {
  // TESIS akışı
  GecisModel? _selfPass;
  List<GecisModel> _davetliler = [];
  bool _yukleniyor = true;
  String? _hata;

  // Grup bilgisi (yetkiler: yonetici/cafe ekstra süreler)
  GroupModel? _currentGroup;
  bool _isLoadingGroup = true;

  // Davetli listesi scroll
  final ScrollController _guestCtrl = ScrollController();

  // Self-pass default dakika (ilk yüklemede)
  static const int _defaultMinutes = 60;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _guestCtrl.dispose();
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

      // 1) TESIS self-pass (mevcut varsa döner, yetmiyorsa _defaultMinutes'a uzatır)
      final spRes = await QrCodeApiService.getirTesisSelfPassApi(
        userId: userId,
        minutes: _defaultMinutes,
      );
      final sp = spRes.data;

      // 2) Aktif TESIS misafir listesi
      final lstRes = await QrCodeApiService.listeleTesisMisafirPassApi(
        userId: userId,
      );
      final liste = lstRes.data ?? <GecisModel>[];

      setState(() {
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

  // -> Yerel saate çevirerek formatla
  String _f(DateTime dt) =>
      DateFormat("dd MMMM yyyy EEEE HH:mm", "tr_TR").format(dt.toLocal());

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

      // 1) Canvas'a çiz
      const double sizePx = 1024;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Beyaz arka plan
      final bg = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, sizePx, sizePx), bg);

      // QR çiz
      painter.paint(canvas, const Size.square(sizePx));

      // 2) PNG byte'larına çevir
      final img =
          await recorder.endRecording().toImage(sizePx.toInt(), sizePx.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('QR üretilemedi');

      final bytes = byteData.buffer.asUint8List();

      // 3) Geçici dosyaya yaz (birçok hedef için gerekli)
      final dir = await getTemporaryDirectory();
      final fileName = 'qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final f = File('${dir.path}/$fileName');
      await f.writeAsBytes(bytes, flush: true);

      // 4) iPad için share sheet konumu
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 0, 0);

      // 5) Yeni API ile paylaş
      await SharePlus.instance.share(
        ShareParams(
          text: mesaj,
          files: [XFile(f.path)],
          sharePositionOrigin: origin,
          // subject: 'QR Kod', // opsiyonel
          // title: 'Paylaş',   // opsiyonel
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım başarısız: $e')),
      );
    }
  }

  Future<void> _davetEt() async {
    final groupName = _currentGroup?.name ?? '';
    final durationsForUye = const [5, 60, 60 * 24];
    final durationsForYonetici = const [5, 60, 60 * 24, 60 * 24 * 7];
    final List<int> options = (groupName == 'yonetici' || groupName == 'cafe')
        ? durationsForYonetici
        : durationsForUye;

    final sonuc = await showDialog<_YeniMisafirInput?>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        int secili = options.first;

        // 🔧 Tüm içerik TEK StatefulBuilder ile yönetiliyor
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            title: const Text('Misafir Daveti'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((m) {
                      final txt = _minsToLabel(m);
                      return ChoiceChip(
                        label: Text(txt),
                        selected: m == secili,
                        onSelected: (v) {
                          if (!v) return;
                          setD(() => secili = m);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                    ctx, _YeniMisafirInput(c.text.trim(), secili)),
                child: const Text('Oluştur'),
              ),
            ],
          ),
        );
      },
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
        if (lstRes.data != null) setState(() => _davetliler = lstRes.data!);
      } catch (_) {}

      await _paylasQrKodu(
        created.code,
        mesaj: _paylasMetni(created.label),
      );
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
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
      final userId = await _getUserId();
      if (userId == null) return;
      await QrCodeApiService.silTesisMisafirPassApi(userId: userId, code: code);

      final lstRes =
          await QrCodeApiService.listeleTesisMisafirPassApi(userId: userId);
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

  String _kisiEtiketi(String? raw) {
    final t = (raw ?? '').trim();
    return t.isEmpty ? 'Davetli' : t;
  }

  String _minsToLabel(int m) {
    if (m < 60) return '${m}dk';
    if (m == 60) return '1saat';
    if (m % (60 * 24 * 7) == 0) return '${(m ~/ (60 * 24 * 7))}hafta';
    if (m % (60 * 24) == 0) return '${(m ~/ (60 * 24))}gun';
    return '${(m / 60).round()}saat';
  }

  String _paylasMetni(String? label) {
    final adSoyad = _kisiEtiketi(label);
    return 'Merhaba $adSoyad, bu QR kod belirtilen süre boyunca geçerlidir.\n'
        'Binay Akademi TESİS girişi için kapıda okutunuz.';
  }

  Widget _qrKutu(String code) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
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
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGroup || _yukleniyor) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Kod ile Giriş')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_hata != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('QR Kod ile Giriş')),
          body: Center(child: Text(_hata!)));
    }

    final theme = Theme.of(context);
    final sp = _selfPass;

    return Scaffold(
      appBar: AppBar(title: const Text('QR Kod ile Giriş')),
      backgroundColor: const Color(0xFFF7F6F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _davetEt,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Davet Et'),
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
              child: const DefaultTextStyle(
                style: TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tesis Giriş',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text(
                      'Kişisel giriş için QR kodunuzu okutun. Misafir eklemek için alttaki “Davet Et” butonunu kullanın.',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEFFAF6)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SELF PASS QR
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
                    Text(
                      'Geçerlilik Bitişi: ${_f(sp.expiresAt)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text('Parlaklığı artırın ve kodu tamamen gösterin.',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // DAVETLILER
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
                        360, MediaQuery.of(context).size.height * 0.45)),
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
                      final adSoyad = _kisiEtiketi(p.label);
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
                                  Text('Geçerlilik Bitişi: ${_f(p.expiresAt)}',
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12.5)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Paylaş',
                              onPressed: () => _paylasQrKodu(
                                p.code,
                                mesaj: _paylasMetni(p.label),
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
    );
  }
}

class _YeniMisafirInput {
  final String label;
  final int minutes;
  _YeniMisafirInput(this.label, this.minutes);
}
