// lib/screens/6_muhasebe/havale/dekont_yukle_page.dart
//
// Tam ekran dekont yükleme formu (alt sayfa değil: dar ekranda ve 1.3 yazı
// ölçeğinde klavye açılınca "Gönder" kayboluyordu).
//
// Fotoğraf telefonda küçültülür (en uzun kenar 2000 px, JPEG %85; iOS'ta
// HEIC de JPEG'e döner), böylece 5 MB sınırı pratikte yalnız büyük PDF'e
// takılır. Tür ve boyut yüklemeden önce denetlenir; sunucu aynısını yeniden
// yapar. Başarıda sayfa yeni dekontla kapanır.


import 'package:file_selector/file_selector.dart';
import 'package:fitcall/common/dekont_dosya_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/dekont_yukle_govdesi.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/dekont_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const _pdfGrubu = XTypeGroup(
  label: 'PDF',
  extensions: ['pdf'],
  mimeTypes: ['application/pdf'],
  uniformTypeIdentifiers: ['com.adobe.pdf'],
);

class DekontYuklePage extends StatefulWidget {
  const DekontYuklePage({super.key});

  @override
  State<DekontYuklePage> createState() => _DekontYuklePageState();
}

class _DekontYuklePageState extends State<DekontYuklePage> {
  final _tutar = TextEditingController();
  final _aciklama = TextEditingController();

  String? _ad;
  String? _tur;
  Uint8List? _baytlar;
  String? _hata;
  String? _tutarHatasi;
  bool _gonderiliyor = false;

  @override
  void dispose() {
    _tutar.dispose();
    _aciklama.dispose();
    super.dispose();
  }

  Future<void> _dosyaSec() async {
    final kaynak = await showModalBottomSheet<DekontKaynagi>(
      context: context,
      builder: (c) => SafeArea(
        child: DosyaKaynagiSecenekleri(onSec: (k) => Navigator.pop(c, k)),
      ),
    );
    if (kaynak == null || !mounted) return;
    try {
      final XFile? dosya = kaynak == DekontKaynagi.pdf
          ? await openFile(acceptedTypeGroups: const [_pdfGrubu])
          : await ImagePicker().pickImage(
              source: kaynak == DekontKaynagi.kamera
                  ? ImageSource.camera
                  : ImageSource.gallery,
              maxWidth: 2000,
              maxHeight: 2000,
              imageQuality: 85,
            );
      if (dosya == null) return;
      final baytlar = await dosya.readAsBytes();
      final tur = dekontTuru(baytlar);
      var ad = dosya.name.trim();
      if (ad.isEmpty) ad = tur == 'application/pdf' ? 'dekont.pdf' : 'dekont.jpg';
      if (!mounted) return;
      setState(() {
        _ad = ad;
        _tur = tur;
        _baytlar = baytlar;
        _hata = dekontDosyasiHatasi(baytlar);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.code.contains('denied')
            ? 'Kamera veya fotoğraf izni verilmedi. Telefonun Ayarlar '
                'bölümünden izin verebilirsin.'
            : 'Dosya alınamadı.';
      });
    } catch (_) {
      if (mounted) setState(() => _hata = 'Dosya okunamadı.');
    }
  }

  Future<void> _gonder() async {
    final baytlar = _baytlar;
    if (baytlar == null || _hata != null || _gonderiliyor) return;
    final tutarMetni = _tutar.text.trim();
    if (tutarMetni.isNotEmpty) {
      final t = tutarCoz(tutarMetni);
      if (t == null || t.isNaN || t <= 0) {
        setState(() => _tutarHatasi = 'Tutarı rakamla yaz, ör. 12.500');
        return;
      }
    }
    setState(() {
      _tutarHatasi = null;
      _gonderiliyor = true;
    });
    try {
      final dekont = await DekontService.yukle(
        baytlar: baytlar,
        dosyaAdi: _ad ?? 'dekont',
        dosyaTuru: _tur ?? 'application/octet-stream',
        beyanTutar: tutarMetni,
        aciklama: _aciklama.text,
      );
      if (!mounted) return;
      Navigator.pop(context, dekont);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _hata = 'Dekont gönderilemedi, lütfen tekrar dene.');
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hazir = _baytlar != null && _hata == null && !_gonderiliyor;
    return PopScope(
      canPop: !_gonderiliyor,
      child: Scaffold(
        body: Column(
          children: [
            BaslikBandi(
              padding: const EdgeInsets.fromLTRB(4, 6, Bosluk.l, Bosluk.m),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed:
                        _gonderiliyor ? null : () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dekont yükle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text('Havale / EFT dekontun',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    Bosluk.l, Bosluk.xl, Bosluk.l, Bosluk.xl),
                child: DekontYukleGovdesi(
                  dosyaAdi: _ad,
                  dosyaBoyutu: _baytlar?.length,
                  pdfMi: _tur == 'application/pdf',
                  onizleme: _baytlar,
                  hata: _hata,
                  tutarHatasi: _tutarHatasi,
                  tutarController: _tutar,
                  aciklamaController: _aciklama,
                  onDosyaSec: _dosyaSec,
                  etkin: !_gonderiliyor,
                ),
              ),
            ),
            Material(
              color: context.cs.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
                  child: FilledButton(
                    onPressed: hazir ? _gonder : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Yaricap.l),
                      ),
                    ),
                    child: _gonderiliyor
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: ButonYukleniyorGostergesi(),
                          )
                        : const Text('Gönder'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
