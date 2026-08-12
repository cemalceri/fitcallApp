// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yönetici üye listesi — veri katmanı.
///
/// Görsel gövde [UyelerGorunumu]'nda; burada yalnız API, filtre ve gezinme var.
class UyelerPage extends StatefulWidget {
  const UyelerPage({super.key});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Tüm liste tek seferde çekilir; arama/filtre client-side yapılır (API dövülmez).
  UyeIstatistik? _istatistik;
  List<UyeListeItem> _tumUyeler = [];
  bool _loading = true;
  String? _errorMessage;

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif' | 'borclu'

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
  /// mevcut liste ekranda kalır (iskelet listeyi bir anlığına silip geri
  /// getiriyordu).
  Future<void> _loadData({bool iskeletGoster = true}) async {
    setState(() {
      if (iskeletGoster) _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getUyeler(hepsi: true);
      if (mounted) {
        setState(() {
          _istatistik = result.data?.istatistikler;
          _tumUyeler = result.data?.uyeler ?? [];
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  /// Client-side arama + filtre.
  List<UyeListeItem> get _filtrelenmis {
    var list = _tumUyeler;

    if (_filtre == 'aktif') {
      list = list.where((u) => u.aktifMi).toList();
    } else if (_filtre == 'pasif') {
      list = list.where((u) => !u.aktifMi).toList();
    } else if (_filtre == 'borclu') {
      list = list.where((u) => u.bakiye < 0).toList();
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

    if (_filtre == 'borclu') {
      // En borçlu (en negatif bakiye) önce
      list = [...list]..sort((a, b) => a.bakiye.compareTo(b.bakiye));
    }

    return list;
  }

  void _acUyeDetay(UyeListeItem uye) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UyeDetayPage(
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
      body: SafeArea(
        bottom: false,
        child: UyelerGorunumu(
          istatistik: _istatistik,
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
      ),
    );
  }
}
