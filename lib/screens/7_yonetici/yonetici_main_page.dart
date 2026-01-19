// lib/screens/7_yonetici/yonetici_main_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/raporlar_page.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/antrenorler_page.dart';
import 'package:fitcall/screens/7_yonetici/dersler/dersler_page.dart';

class YoneticiMainPage extends StatefulWidget {
  const YoneticiMainPage({super.key});

  @override
  State<YoneticiMainPage> createState() => _YoneticiMainPageState();
}

class _YoneticiMainPageState extends State<YoneticiMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    YoneticiDashboardPage(),
    RaporlarPage(),
    UyelerPage(),
    AntrenorlerPage(),
    DerslerPage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Raporlar',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Üyeler',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_tennis_outlined),
      selectedIcon: Icon(Icons.sports_tennis),
      label: 'Antrenörler',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Dersler',
    ),
  ];

  void _onDestinationSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),
    );
  }
}
