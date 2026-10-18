// lib/screens/7_yonetici/uyeler/uyeler_page.dart

import 'dart:async';

import 'package:fitcall/common/sayfali_liste.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_filtre_sheet.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uye_siralama_sheet.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/widgets/uyeler_gorunumu.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uye_detay_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Üyeler sekmesini dışarıdan bir ön ayarla açma isteği (Dashboard'daki
/// "Toplam Alacak" kartı, menüdeki "Borçlu Üyeler"). Her istek yeni bir
/// nesnedir; aynı ön ayar art arda istense de dinleyici tetiklenir.
class UyeOnAyarIstegi {
  final UyeOnAyari onAyar;

  UyeOnAyarIstegi(this.onAyar);
}

/// Yönetici üye listesi — veri katmanı.
///
/// Görsel gövde [UyelerGorunumu]'nda; burada yalnız API, filtre/sıralama,
/// arama ve gezinme var. Filtre ve sıralama sekme değişince korunur
/// (IndexedStack), cihazda saklanmaz.
class UyelerPage extends StatefulWidget {
  /// Dışarıdan gelen ön ayar istekleri; bkz. [UyeOnAyarIstegi].
  final ValueListenable<UyeOnAyarIstegi?>? onAyarIstegi;

  const UyelerPage({super.key, this.onAyarIstegi});

  @override
  State<UyelerPage> createState() => _UyelerPageState();
}

class _UyelerPageState extends State<UyelerPage> {
  final TextEditingController _aramaController = TextEditingController();

  // Liste sayfalı: aşağı kaydırdıkça 20'şer gelir; arama ve filtre sunucuda.
  late final SayfaliListe<UyeListeItem> _liste =
      SayfaliListe<UyeListeItem>(_getirici(), anahtar: (u) => u.id);

  /// İstatistik kartları ve filtre özeti yalnız ilk sayfayla gelir ve
  /// [SayfaliListe.ek] üzerinden okunur: getiricinin içinde `setState` ile
  /// yazılırsa nesil korumasının dışında kalıyor, yavaş bağlantıda eski
  /// aramanın sayıları yeni listenin üstünde kalıyordu.
  UyelerData? get _ilkSayfa => _liste.ek as UyelerData?;

  UyeFiltreleri _filtreler = UyeFiltreleri.bos;
  UyeSiralama _siralama = UyeSiralama.varsayilan;

  /// Sunucuya en son gönderilen arama; aynı metinle tekrar istek atılmaz.
  String _sonArama = '';
  Timer? _aramaZamanlayici;

  @override
  void initState() {
    super.initState();
    _liste.addListener(_degisti);
    widget.onAyarIstegi?.addListener(_disIstek);
    // Sekme ilk kez bir istekle açılıyorsa (Dashboard kartı) ilk yükleme
    // doğrudan o ön ayarla yapılır.
    final istek = widget.onAyarIstegi?.value;
    if (istek != null) {
      _filtreler = istek.onAyar.filtreler(bugunKulup());
      _siralama = istek.onAyar.siralama;
      _liste.yenile(getir: _getirici());
    } else {
      _liste.yenile();
    }
    _aramaController.addListener(_aramaDegisti);
  }

  @override
  void dispose() {
    widget.onAyarIstegi?.removeListener(_disIstek);
    _aramaZamanlayici?.cancel();
    _liste.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  void _degisti() {
    if (mounted) setState(() {});
  }

  /// Dashboard / menüden gelen ön ayar: arama da temizlenir, yoksa "borçlu"
  /// listesi eski aramayla daralmış açılırdı.
  void _disIstek() {
    final istek = widget.onAyarIstegi?.value;
    if (istek == null || !mounted) return;
    final aramaVardi = _sonArama.isNotEmpty;
    // Temizleme dinleyiciyi tetikler (temizle düğmesi kalkar); kurduğu
    // arama zamanlayıcısı aşağıdaki istekle karşılanır.
    _aramaController.clear();
    _aramaZamanlayici?.cancel();
    _sonArama = '';
    _uygula(
      istek.onAyar.filtreler(bugunKulup()),
      istek.onAyar.siralama,
      zorla: aramaVardi,
    );
  }

  SayfaGetirici<UyeListeItem> _getirici() {
    final arama = _aramaController.text.trim();
    final filtreler = _filtreler;
    final siralama = _siralama;
    return (sayfa) async {
      final sonuc = await YoneticiApiService.getUyeler(
        sayfa: sayfa,
        arama: arama,
        filtreler: filtreler,
        siralama: siralama,
      );
      final veri = sonuc.data;
      return SayfaSonucu(
        ogeler: veri?.uyeler ?? const [],
        toplamSayfa: veri?.toplamSayfa ?? 1,
        toplam: veri?.toplamUye ?? 0,
        // İstatistik ve özet yalnız ilk sayfada gelir (sonrakilerde sunucu
        // hesaplamaz); nesil koruması SayfaliListe'de.
        ek: sayfa == 1 ? veri : null,
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

  /// [zorla]: filtre aynı kalsa da yenile (dışarıdan gelen istek aramayı
  /// temizlediyse liste eski aramayla daralmış kalmasın).
  void _uygula(
    UyeFiltreleri filtreler,
    UyeSiralama siralama, {
    bool zorla = false,
  }) {
    if (!zorla && filtreler == _filtreler && siralama == _siralama) return;
    // Bekleyen arama zamanlayıcısı da bu istekle karşılanır; aynı istek
    // iki kez gitmesin.
    _aramaZamanlayici?.cancel();
    _sonArama = _aramaController.text.trim();
    setState(() {
      _filtreler = filtreler;
      _siralama = siralama;
    });
    _liste.yenile(getir: _getirici());
  }

  void _onAyarSec(UyeOnAyari onAyar) =>
      _uygula(onAyar.filtreler(bugunKulup()), onAyar.siralama);

  Future<void> _filtreAc() async {
    final arama = _aramaController.text.trim();
    final secilen = await UyeFiltreSheet.ac(
      context,
      baslangic: _filtreler,
      sayac: (f) =>
          YoneticiApiService.getUyeSayisi(arama: arama, filtreler: f),
    );
    if (secilen != null && mounted) _uygula(secilen, _siralama);
  }

  Future<void> _siralamaAc() async {
    final secilen = await UyeSiralamaSheet.ac(context, secili: _siralama);
    if (secilen != null && mounted) _uygula(_filtreler, secilen);
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
    final ilk = _ilkSayfa;
    return Scaffold(
      // Üst güvenli alanı SliverAppBar karşılar: renkli başlık durum
      // çubuğunun arkasına uzanır.
      body: SafeArea(
        top: false,
        bottom: false,
        child: UyelerGorunumu(
          istatistik: ilk?.istatistikler,
          filtreOzeti: ilk?.filtreOzeti,
          uyeler: _liste.ogeler,
          toplam: _liste.toplam,
          yukleniyor: _liste.ilkYukleniyor,
          hata: _liste.hata,
          dahaYukleniyor: _liste.dahaYukleniyor,
          dahaHatasi: _liste.dahaHatasi,
          onDahaFazla: _liste.dahaFazla,
          onDahaTekrarDene: _liste.dahaTekrarDene,
          filtreler: _filtreler,
          siralama: _siralama,
          seciliOnAyar: eslesenOnAyar(_filtreler, bugunKulup()),
          aramaDenetleyicisi: _aramaController,
          onOnAyar: _onAyarSec,
          onFiltrele: _filtreAc,
          onSirala: _siralamaAc,
          onFiltreDegistir: (f) => _uygula(f, _siralama),
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
