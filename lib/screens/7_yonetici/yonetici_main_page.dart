// lib/screens/7_yonetici/yonetici_main_page.dart
//
// Yönetici kabuğu: raporlama ve genel görünüm.
//
// Ders açma/düzenleme/iptal/silme ve QR doğrulama burada YOK — hepsi ofis
// kabuğunda (lib/screens/8_ofis/). Yönetici gün gün ne olduğunu Dersler
// sekmesinden, doluluğu Raporlar'daki ısı haritasından görüyor; ızgaraya
// ihtiyaç kalmadı.

import 'package:flutter/material.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/raporlar_page.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/antrenorler_page.dart';
import 'package:fitcall/screens/1_common/ders_listesi/dersler_page.dart';
import 'package:fitcall/screens/1_common/acilis_popup/acilis_popuplari.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_bottom_bar.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_drawer.dart';
import 'package:fitcall/services/core/storage_service.dart';

class YoneticiMainPage extends StatefulWidget {
  const YoneticiMainPage({super.key});

  @override
  State<YoneticiMainPage> createState() => _YoneticiMainPageState();
}

class _YoneticiMainPageState extends State<YoneticiMainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  String _yoneticiAdi = '';

  /// Üyeler sekmesine dışarıdan ön ayar (Ana Sayfa kartı, menü).
  final _uyeOnAyari = ValueNotifier<UyeOnAyarIstegi?>(null);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      YoneticiDashboardPage(
        onTabChange: _goTab,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onBorcluUyeler: _borcluUyeler,
      ),
      const RaporlarPage(),
      UyelerPage(onAyarIstegi: _uyeOnAyari),
      const AntrenorlerPage(),
      const DerslerPage(),
    ];
    _yoneticiAdiYukle();
    // Sürüm notu popup'ı ("Neler yeni?"). Duyuru popup'ı burada ÇIKMAZ: sıranın
    // rol filtresi onu üye ve antrenöre bırakıyor (bilinçli karar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AcilisPopuplari.calistir(context);
    });
  }

  Future<void> _yoneticiAdiYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _yoneticiAdi = hesapGorunenAdi(profil.user));
  }

  @override
  void dispose() {
    _uyeOnAyari.dispose();
    super.dispose();
  }

  void _goTab(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Ayrı Borçlu Üyeler sayfası yerine: Üyeler sekmesi, "borçlu + en borçlu
  /// önce" ön ayarı. Tek liste, tek filtre sistemi.
  void _borcluUyeler() {
    _uyeOnAyari.value = UyeOnAyarIstegi(UyeOnAyari.borclu);
    _goTab(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: YoneticiDrawer(
        yoneticiAdi: _yoneticiAdi,
        onTabSelected: _goTab,
        onBorcluUyeler: _borcluUyeler,
        aktifSekme: _selectedIndex,
      ),
      // Menü her sekmenin başlığından açılır (KabukMenuButonu).
      body: KabukMenusu(
        menuyuAc: () => _scaffoldKey.currentState?.openDrawer(),
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: YoneticiBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _goTab,
      ),
    );
  }
}
