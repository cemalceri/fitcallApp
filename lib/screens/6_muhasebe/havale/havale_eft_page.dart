// lib/screens/6_muhasebe/havale/havale_eft_page.dart
//
// Havale / EFT ile ödeme ("İnceleme masası" tasarımının üye tarafı).
//
// Hesap Özeti'ndeki "EFT / Havale" (kredi kartı uyarısından da) bu sayfayı açar; borçtan
// bağımsız, her zaman ulaşılabilir. Başlıkta Hesaplar | Dekontlarım seçici:
// - Hesaplar: kulübün banka hesapları (IBAN, alıcı, karekod + İndir / Paylaş).
// - Dekontlarım: yüklenen dekontlar ve durumları; yüklemeden sonra bu sekmeye
//   geçilir ve yeni satır vurgulanır.
// Dekont işleme (onay/ret) web'de; üyeye durum için push gitmez, durumu
// buradan takip eder (kullanıcı kararı).
//
// Argüman (isteğe bağlı): {'kalanBakiye': double, 'sekme': 'dekontlar'}.

import 'dart:async';
import 'dart:io';

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_detay.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/banka_hesabi_karti.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_listesi.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/hesaplar_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/dekont_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Sekme { hesaplar, dekontlar }

/// Hesap yoksa ya da üye takılırsa kulübe yazabileceği WhatsApp hattı.
const String kulupWhatsappUrl = 'https://wa.me/905422462982';

class HavaleEftPage extends StatefulWidget {
  const HavaleEftPage({super.key});

  @override
  State<HavaleEftPage> createState() => _HavaleEftPageState();
}

class _HavaleEftPageState extends State<HavaleEftPage> {
  final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  _Sekme _sekme = _Sekme.hesaplar;
  double? _kalanBakiye;
  bool _argumanOkundu = false;
  bool _yukleniyor = true;
  List<BankaHesabiModel> _hesaplar = const [];
  List<DekontModel> _dekontlar = const [];
  int _bekleyen = 0;
  int? _vurgulanan;
  Timer? _vurguZamanlayici;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumanOkundu) return;
    _argumanOkundu = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final b = args['kalanBakiye'];
      if (b is num) _kalanBakiye = b.toDouble();
      if (args['sekme'] == 'dekontlar') _sekme = _Sekme.dekontlar;
    }
    _yukle();
  }

  @override
  void dispose() {
    _vurguZamanlayici?.cancel();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = await Future.wait([
        DekontService.hesaplar(),
        DekontService.dekontlarim(),
      ]);
      if (!mounted) return;
      final dekontlar = sonuclar[1] as DekontlarimSonucu;
      setState(() {
        _hesaplar = sonuclar[0] as List<BankaHesabiModel>;
        _dekontlar = dekontlar.dekontlar;
        _bekleyen = dekontlar.bekleyenSayisi;
      });
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Bilgiler yüklenemedi.');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _dekontlariYenile() async {
    try {
      final sonuc = await DekontService.dekontlarim();
      if (!mounted) return;
      setState(() {
        _dekontlar = sonuc.dekontlar;
        _bekleyen = sonuc.bekleyenSayisi;
      });
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    }
  }

  Future<void> _dekontYukle() async {
    HapticFeedback.lightImpact();
    final sonuc =
        await Navigator.pushNamed(context, routeEnums[SayfaAdi.dekontYukle]!);
    if (!mounted || sonuc is! DekontModel) return;
    setState(() {
      _sekme = _Sekme.dekontlar;
      _vurgulanan = sonuc.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dekontun gönderildi, kontrol edilecek.')),
    );
    await _dekontlariYenile();
    _vurguZamanlayici?.cancel();
    _vurguZamanlayici = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _vurgulanan = null);
    });
  }

  Future<void> _geriCek(DekontModel d) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Dekont geri çekilsin mi?'),
        content: const Text(
            'Kulüp bu dekontu işlemez. Gerekirse yeniden yükleyebilirsin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          YikiciButon(
            etiket: 'Geri çek',
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    try {
      final mesaj = await DekontService.geriCek(d.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(mesaj.isNotEmpty ? mesaj : 'Dekont geri çekildi.')),
      );
      await _dekontlariYenile();
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    }
  }

  void _detayAc(DekontModel d) {
    HapticFeedback.lightImpact();
    var aciliyor = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (c, setSheet) => DekontDetayIcerik(
              dekont: d,
              dosyaAciliyor: aciliyor,
              onDosyaGor: () async {
                setSheet(() => aciliyor = true);
                await _dosyaGoster(d);
                if (c.mounted) setSheet(() => aciliyor = false);
              },
              onGeriCek: () {
                Navigator.pop(c);
                _geriCek(d);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dosyaGoster(DekontModel d) async {
    try {
      final dosya = await DekontService.dosya(d.id);
      if (!mounted) return;
      if (dosya.pdfMi) {
        // Uygulama içinde PDF görüntüleyici yok: paylaşım menüsünden açılır.
        final dizin = await getTemporaryDirectory();
        final f = File('${dizin.path}/${dosya.ad}');
        await f.writeAsBytes(dosya.baytlar, flush: true);
        await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (c) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: Text(dekontBasligi(d))),
            body: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image.memory(dosya.baytlar)),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Dosya açılamadı.');
    }
  }

  Future<void> _karekodPaylas(BankaHesabiModel hesap) async {
    final url = hesap.karekodUrl;
    if (url == null) return;
    final kutu = context.findRenderObject() as RenderBox?;
    final konum = kutu != null
        ? kutu.localToGlobal(Offset.zero) & kutu.size
        : const Rect.fromLTWH(0, 0, 0, 0);
    try {
      final baytlar = await karekodBaytlari(url);
      final dizin = await getTemporaryDirectory();
      final uzanti = url.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final f = File('${dizin.path}/karekod_${hesap.id}.$uzanti');
      await f.writeAsBytes(baytlar, flush: true);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(f.path)],
        text: '${hesap.etiket} · ${hesap.aliciAdi}\n${hesap.ibanGruplu}',
        sharePositionOrigin: konum,
      ));
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Karekod paylaşılamadı.');
    }
  }

  /// Karekodu galeriye kaydeder: üye banka uygulamasında "galeriden oku" ile
  /// açar. İzin yalnız ilk kayıtta sorulur (Android 10 ve altı, iOS).
  Future<void> _karekodIndir(BankaHesabiModel hesap) async {
    final url = hesap.karekodUrl;
    if (url == null) return;
    try {
      final baytlar = await karekodBaytlari(url);
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        if (mounted) {
          ShowMessage.error(context,
              'Galeri izni verilmedi. Ayarlardan izin verip tekrar dene.');
        }
        return;
      }
      await Gal.putImageBytes(baytlar, name: 'binay_karekod_${hesap.id}');
      if (mounted) ShowMessage.success(context, 'Karekod galeriye kaydedildi.');
    } on GalException catch (e) {
      if (!mounted) return;
      ShowMessage.error(
          context,
          e.type == GalExceptionType.accessDenied
              ? 'Galeri izni verilmedi. Ayarlardan izin verip tekrar dene.'
              : 'Karekod galeriye kaydedilemedi.');
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Karekod indirilemedi.');
    }
  }

  Future<void> _iletisim() async {
    await launchUrl(Uri.parse(kulupWhatsappUrl),
        mode: LaunchMode.externalApplication);
  }

  String get _altBaslik {
    final b = _kalanBakiye;
    if (b == null) return 'Hesaplar ve dekontların';
    if (b < 0) return 'Kalan borç ${_tl.format(b.abs())}';
    if (b > 0) return 'Fazla ödeme ${_tl.format(b)}';
    return 'Borç yok';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BaslikBandi(
            padding: const EdgeInsets.fromLTRB(4, 6, Bosluk.l, Bosluk.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Geri',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Havale / EFT',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(_altBaslik,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Bosluk.m),
                Padding(
                  padding: const EdgeInsets.only(left: Bosluk.m),
                  child: BaslikSecici<_Sekme>(
                    secenekler: [
                      (_Sekme.hesaplar, 'Hesaplar'),
                      (
                        _Sekme.dekontlar,
                        _bekleyen > 0
                            ? 'Dekontlarım · $_bekleyen'
                            : 'Dekontlarım'
                      ),
                    ],
                    secili: _sekme,
                    onSec: (s) => setState(() => _sekme = s),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _yukleniyor
                ? const IskeletListe()
                : _sekme == _Sekme.hesaplar
                    ? HesaplarGorunumu(
                        hesaplar: _hesaplar,
                        onKarekodIndir: _karekodIndir,
                        onKarekodPaylas: _karekodPaylas,
                        onIletisim: _iletisim,
                        onYenile: _yukle,
                      )
                    : DekontlarimGorunumu(
                        dekontlar: _dekontlar,
                        vurgulananId: _vurgulanan,
                        onTap: _detayAc,
                        onGeriCek: _geriCek,
                        onDekontYukle: _dekontYukle,
                        onYenile: _dekontlariYenile,
                      ),
          ),
          Material(
            color: context.cs.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
                child: FilledButton.icon(
                  onPressed: _dekontYukle,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Dekont yükle'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Yaricap.l),
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
