// lib/screens/8_ofis/ana_sayfa/ofis_ana_sayfa_page.dart
//
// Ofis kabuğunun ilk sekmesi: bugünün özeti + bekleyen işler (ders onayı,
// plan dışı / misafir kararı, katılım cevabı bekleyenler). Görünüm
// OfisAnaSayfaGorunumu'nda; burada API ve gezinme var. Bir işten dönülünce
// sayılar tazelenir.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/widgets/ofis_ana_sayfa_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/dersler/ofis_dersler_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/onay_bekleyen_gunler_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/plan_disi_kararlar_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';

class OfisAnaSayfaPage extends StatefulWidget {
  final VoidCallback? onMenuTap;

  /// Bugünün özetine dokununca Dersler sekmesine geçilir.
  final VoidCallback? onDerslerSekmesi;

  const OfisAnaSayfaPage({super.key, this.onMenuTap, this.onDerslerSekmesi});

  @override
  State<OfisAnaSayfaPage> createState() => OfisAnaSayfaPageState();
}

class OfisAnaSayfaPageState extends State<OfisAnaSayfaPage> {
  OfisBekleyenIsler? _veri;
  bool _yukleniyor = true;
  String? _hata;
  String _ofisAdi = '';
  bool _profilDegistir = false;

  @override
  void initState() {
    super.initState();
    _yukle();
    _profilBilgisi();
  }

  Future<void> _profilBilgisi() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    final coklu = await ProfilDegistirButonu.gosterilmeliMi();
    if (!mounted) return;
    setState(() {
      if (profil != null) _ofisAdi = hesapGorunenAdi(profil.user);
      _profilDegistir = coklu;
    });
  }

  Future<void> _yukle({bool iskelet = true}) async {
    setState(() {
      if (iskelet) _yukleniyor = true;
      _hata = null;
    });
    try {
      final veri = await OfisDersYonetimiService.bekleyenIsler();
      if (!mounted) return;
      setState(() {
        _veri = veri;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Sessiz tazelemede hata: eldeki sayılar kalır.
      if (!iskelet && _veri != null) {
        setState(() => _yukleniyor = false);
        return;
      }
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    }
  }

  /// Sekmeye dönünce / uygulama öne gelince: sayılar iskeletsiz tazelenir.
  void sessizYenile() => _yukle(iskelet: false);

  Future<void> _ac(Widget sayfa) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => sayfa));
    if (mounted) _yukle(iskelet: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfisAnaSayfaGorunumu(
        ofisAdi: _ofisAdi,
        profilDegistir: _profilDegistir,
        veri: _veri,
        yukleniyor: _yukleniyor,
        hata: _hata,
        onMenu: widget.onMenuTap,
        onYenile: () => _yukle(iskelet: false),
        onYenidenDene: _yukle,
        onOnay: () => _ac(const OnayBekleyenGunlerPage()),
        onPlanDisi: () => _ac(const PlanDisiKararlarPage()),
        // Cevap bekleyenin olduğu ilk gün açılır (bugün herkes cevapladıysa
        // yarın); sayı iki günün toplamı.
        onTeyit: () => _ac(OfisDerslerPage(
          baslangicTarihi: _veri?.ilkTeyitGunu ?? bugunKulup(),
          baslangicSuzgeci: DersSuzgeci.cevapsiz,
        )),
        onBugununDersleri: widget.onDerslerSekmesi ??
            () => _ac(OfisDerslerPage(baslangicTarihi: bugunKulup())),
      ),
    );
  }
}
