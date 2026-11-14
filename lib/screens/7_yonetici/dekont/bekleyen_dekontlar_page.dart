// lib/screens/7_yonetici/dekont/bekleyen_dekontlar_page.dart
//
// Yönetici → Ana Sayfa "Ödeme onay bekliyor" maddesi: ofisin henüz işlemediği
// dekontlar. Yalnız görüntüleme; görünüm [BekleyenDekontlarGorunumu]'nda.

import 'dart:io';

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/9_yonetici/bekleyen_dekont_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/7_yonetici/dekont/bekleyen_dekontlar_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/indirme_service.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BekleyenDekontlarPage extends StatefulWidget {
  const BekleyenDekontlarPage({super.key});

  @override
  State<BekleyenDekontlarPage> createState() => _BekleyenDekontlarPageState();
}

class _BekleyenDekontlarPageState extends State<BekleyenDekontlarPage> {
  late Future<List<BekleyenDekont>> _liste = _getir();
  int? _acilan;

  Future<List<BekleyenDekont>> _getir() async =>
      (await YoneticiApiService.getBekleyenDekontlar()).data ?? const [];

  Future<void> _yenile() async {
    final yeni = _getir();
    setState(() => _liste = yeni);
    await yeni;
  }

  Future<void> _dosyaGoster(BekleyenDekont d) async {
    if (_acilan != null) return;
    setState(() => _acilan = d.id);
    try {
      final dosya = await YoneticiApiService.getDekontDosya(d.id);
      if (!mounted) return;
      if (dosya.pdfMi) {
        // PDF doğrudan telefona iner (Android "İndirilenler"); bildirimdeki
        // «Aç» telefonun PDF okuyucusunu açar.
        final uri = await IndirmeService.indirilenlereKaydet(
            ad: dosya.ad, baytlar: dosya.baytlar, tur: dosya.tur);
        if (!mounted) return;
        if (uri != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('${dosya.ad} İndirilenler klasörüne kaydedildi.'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Aç',
                onPressed: () async {
                  final acildi = await IndirmeService.ac(uri, dosya.tur);
                  if (!acildi && mounted) {
                    ShowMessage.warning(
                        context, 'Telefonda PDF açacak uygulama yok.');
                  }
                },
              ),
            ));
          return;
        }
        // iOS ve eski Android: "İndirilenler"e izinsiz yazılamıyor; paylaşım
        // menüsü açılır ("Dosyalar'a Kaydet" oradadır).
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
            appBar: AppBar(title: Text(d.uyeAdi)),
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
    } finally {
      if (mounted) setState(() => _acilan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme onay bekliyor'),
        actions: [
          OgrenmeButonu(
            sayfa: OgrenmeSayfasi.yoneticiDekontlar,
            sssRotasi: routeEnums[SayfaAdi.yoneticiYardim]!,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<BekleyenDekont>>(
        future: _liste,
        builder: (context, anlik) {
          if (anlik.connectionState != ConnectionState.done) {
            return const IskeletListe();
          }
          if (anlik.hasError) {
            final hata = anlik.error;
            return BosDurum(
              ikon: Icons.error_outline_rounded,
              baslik: 'Liste alınamadı',
              aciklama: hata is ApiException
                  ? hata.message
                  : 'Bekleyen ödemeler alınamadı.',
              eylemEtiketi: 'Tekrar dene',
              eylemIkonu: Icons.refresh_rounded,
              onEylem: _yenile,
              ikonRengi: Theme.of(context).colorScheme.error,
            );
          }
          return RefreshIndicator(
            onRefresh: _yenile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Stack(
                children: [
                  BekleyenDekontlarGorunumu(
                    dekontlar: anlik.data ?? const [],
                    onDekont: _dosyaGoster,
                  ),
                  if (_acilan != null)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
