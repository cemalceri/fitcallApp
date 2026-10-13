// lib/screens/8_ofis/uyeler/ofis_uyeler_page.dart

import 'dart:async';

import 'package:fitcall/common/sayfali_liste.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_models.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uye_detay_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/widgets/ofis_uyeler_gorunumu.dart';
import 'package:fitcall/services/ofis/ofis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ofis üye listesi — veri katmanı.
///
/// Görsel gövde [OfisUyelerGorunumu]'nda; burada yalnız API, filtre/arama ve
/// gezinme var. Yönetici listesinin aksine bakiye/borç boyutu yok (bkz. api/ofis/).
class OfisUyelerPage extends StatefulWidget {
  const OfisUyelerPage({super.key});

  @override
  State<OfisUyelerPage> createState() => _OfisUyelerPageState();
}

class _OfisUyelerPageState extends State<OfisUyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Liste sayfalı: aşağı kaydırdıkça 20'şer gelir; arama ve filtre sunucuda.
  late final SayfaliListe<OfisUyeListeItem> _liste =
      SayfaliListe<OfisUyeListeItem>(_getirici(), anahtar: (u) => u.id);

  String _filtre = 'tumu'; // 'tumu' | 'aktif' | 'pasif'

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

  SayfaGetirici<OfisUyeListeItem> _getirici() {
    final arama = _aramaController.text.trim();
    final filtre = _filtre;
    return (sayfa) async {
      final sonuc = await OfisApiService.uyeler(
        sayfa: sayfa,
        arama: arama,
        filtre: filtre,
      );
      final veri = sonuc.data;
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
    );
  }
}
