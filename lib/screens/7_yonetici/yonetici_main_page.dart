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
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/antrenorler_page.dart';
import 'package:fitcall/screens/1_common/ders_listesi/dersler_page.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      YoneticiDashboardPage(
        onTabChange: _goTab,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const RaporlarPage(),
      const UyelerPage(),
      const AntrenorlerPage(),
      const DerslerPage(),
    ];
    _yoneticiAdiYukle();
  }

  Future<void> _yoneticiAdiYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _yoneticiAdi = hesapGorunenAdi(profil.user));
  }

  void _goTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: YoneticiDrawer(
        yoneticiAdi: _yoneticiAdi,
        onTabSelected: _goTab,
        aktifSekme: _selectedIndex,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: YoneticiBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _goTab,
      ),
    );
  }
}
