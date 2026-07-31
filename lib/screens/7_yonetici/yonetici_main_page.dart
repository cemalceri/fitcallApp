// lib/screens/7_yonetici/yonetici_main_page.dart

import 'package:flutter/material.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/raporlar_page.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/antrenorler_page.dart';
import 'package:fitcall/screens/7_yonetici/dersler/dersler_page.dart';
import 'package:fitcall/screens/7_yonetici/program/yonetici_program_page.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_ad.dart';
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
      const YoneticiProgramPage(),
    ];
    _yoneticiAdiYukle();
  }

  Future<void> _yoneticiAdiYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _yoneticiAdi = yoneticiGorunenAd(profil.user));
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
