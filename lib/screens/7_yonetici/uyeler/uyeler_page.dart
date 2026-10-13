// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'dart:async';

import 'package:fitcall/common/sayfali_liste.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Yönetici üye listesi — veri katmanı.
///
/// Görsel gövde [UyelerGorunumu]'nda; burada yalnız API, filtre/arama ve
/// gezinme var.
class UyelerPage extends StatefulWidget {
  const UyelerPage({super.key});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Liste sayfalı: aşağı kaydırdıkça 20'şer gelir; arama ve filtre sunucuda.
  late final SayfaliListe<UyeListeItem> _liste =
      SayfaliListe<UyeListeItem>(_getirici(), anahtar: (u) => u.id);

  /// İstatistik kartları; her sayfayla birlikte gelir, sonuncusu tutulur.
  UyeIstatistik? _istatistik;

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif' | 'borclu'

  /// Sunucuya en son gönderilen arama; aynı metinle tekrar istek atılmaz.
  String _sonArama = '';
  Timer? _aramaZamanlayici;

  @override
  void initState() {
    super.initState();
    _liste.addListener(_degisti);
    _liste.yenile();
    _aramaController.addListener(_aramaDegisti);
  }

  @override
  void dispose() {
    _aramaZamanlayici?.cancel();
    _liste.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  void _degisti() {
    if (mounted) setState(() {});
  }

  SayfaGetirici<UyeListeItem> _getirici() {
    final arama = _aramaController.text.trim();
    final filtre = _filtre;
    final borclu = filtre == 'borclu';
    return (sayfa) async {
      final sonuc = await YoneticiApiService.getUyeler(
        sayfa: sayfa,
        arama: arama,
        // "Borçlular" aktif/pasif ayırmaz: bakiye koşulu + en borçlu önce.
        filtre: borclu ? 'tumu' : filtre,
        siralama: borclu ? 'bakiye' : 'ad',
        sadeceBorclu: borclu,
      );
      final veri = sonuc.data;
      // İstatistik yalnız ilk sayfada gelir (sonrakilerde sunucu hesaplamaz).
      if (veri != null && sayfa == 1 && mounted) {
        setState(() => _istatistik = veri.istatistikler);
      }
      return SayfaSonucu(
        ogeler: veri?.uyeler ?? const [],
        toplamSayfa: veri?.toplamSayfa ?? 1,
        toplam: veri?.toplamUye ?? 0,
      );
    };
  }

  /// Yazmayı bırakınca (350 ms) sunucuda aranır; her harfte istek atılmaz.
  void _aramaDegisti() {
    setState(() {}); // temizle butonu
    _aramaZamanlayici?.cancel();
    _aramaZamanlayici = Timer(const Duration(milliseconds: 350), () {
      final arama = _aramaController.text.trim();
      if (arama == _sonArama || !mounted) return;
      _sonArama = arama;
      _liste.yenile(getir: _getirici());
    });
  }

  void _filtreSec(String filtre) {
    if (filtre == _filtre) return;
    // Bekleyen arama zamanlayıcısı da bu istekle karşılanır; aynı istek
    // iki kez gitmesin.
    _aramaZamanlayici?.cancel();
    _sonArama = _aramaController.text.trim();
    setState(() => _filtre = filtre);
    _liste.yenile(getir: _getirici());
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
      // Üst güvenli alanı SliverAppBar karşılar: renkli başlık durum
      // çubuğunun arkasına uzanır.
      body: SafeArea(
        top: false,
        bottom: false,
        child: UyelerGorunumu(
          istatistik: _istatistik,
          uyeler: _liste.ogeler,
          toplam: _liste.toplam,
          yukleniyor: _liste.ilkYukleniyor,
          hata: _liste.hata,
          dahaYukleniyor: _liste.dahaYukleniyor,
          dahaHatasi: _liste.dahaHatasi,
          onDahaFazla: _liste.dahaFazla,
          onDahaTekrarDene: _liste.dahaTekrarDene,
          filtre: _filtre,
          aramaDenetleyicisi: _aramaController,
          onFiltre: _filtreSec,
          onYenile: () => _liste.yenile(iskelet: false),
          onYenidenDene: _liste.yenile,
          onUyeSec: _acUyeDetay,
          onAra: (u) => _ara(u.telefon),
          onWhatsapp: (u) => _whatsapp(u.telefon),
        ),
      ),
    );
  }
}
