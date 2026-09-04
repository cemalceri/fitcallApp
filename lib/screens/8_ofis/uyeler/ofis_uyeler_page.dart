// lib/screens/8_ofis/uyeler/ofis_uyeler_page.dart

import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uye_detay_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/widgets/ofis_uyeler_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ofis üye listesi — veri katmanı.
///
/// Görsel gövde [OfisUyelerGorunumu]'nda; burada yalnız API, filtre ve gezinme
/// var. Yönetici listesinin aksine bakiye/borç boyutu yok (bkz. api/ofis/).
class OfisUyelerPage extends StatefulWidget {
  const OfisUyelerPage({super.key});

  @override
  State<OfisUyelerPage> createState() => _OfisUyelerPageState();
}

class _OfisUyelerPageState extends State<OfisUyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Tüm liste tek seferde çekilir; arama/filtre client-side yapılır (API dövülmez).
  List<OfisUyeListeItem> _tumUyeler = [];
  bool _loading = true;
  String? _errorMessage;

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif'

  @override
  void initState() {
    super.initState();
    _loadData();
    _aramaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  /// [iskeletGoster]: ilk açılışta iskelet çizilir; aşağı çekip yenilemede
  /// mevcut liste ekranda kalır.
  Future<void> _loadData({bool iskeletGoster = true}) async {
    setState(() {
      if (iskeletGoster) _loading = true;
      _errorMessage = null;
    });

    try {
      final sonuc = await OfisApiService.uyeler(hepsi: true);
      if (!mounted) return;
      setState(() {
        _tumUyeler = sonuc.data?.uyeler ?? [];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
        _loading = false;
      });
    }
  }

  /// Client-side arama + filtre.
  List<OfisUyeListeItem> get _filtrelenmis {
    var list = _tumUyeler;

    if (_filtre == 'aktif') {
      list = list.where((u) => u.aktifMi).toList();
    } else if (_filtre == 'pasif') {
      list = list.where((u) => !u.aktifMi).toList();
    }

    final q = _aramaController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((u) =>
              u.adSoyad.toLowerCase().contains(q) ||
              (u.telefon ?? '').contains(q) ||
              u.uyeNo.toString().contains(q))
          .toList();
    }

    return list;
  }

  void _acUyeDetay(OfisUyeListeItem uye) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfisUyeDetayPage(
          uyeId: uye.id,
          baslangicAdSoyad: uye.adSoyad,
        ),
      ),
    );
  }

  Future<void> _ara(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('tel:0$telefon'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp(String? telefon) async {
    if (telefon == null || telefon.isEmpty) return;
    HapticFeedback.lightImpact();
    await launchUrl(Uri.parse('https://wa.me/90$telefon'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfisUyelerGorunumu(
        uyeler: _filtrelenmis,
        yukleniyor: _loading,
        hata: _errorMessage,
        filtre: _filtre,
        aramaDenetleyicisi: _aramaController,
        onFiltre: (f) => setState(() => _filtre = f),
        onYenile: () => _loadData(iskeletGoster: false),
        onYenidenDene: _loadData,
        onUyeSec: _acUyeDetay,
        onAra: (u) => _ara(u.telefon),
        onWhatsapp: (u) => _whatsapp(u.telefon),
      ),
    );
  }
}
