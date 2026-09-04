// lib/screens/8_ofis/ofis_main_page.dart
//
// Ofis (ön büro) kabuğu.
//
// Mobildeki AKSİYONLARIN tamamı burada: ders açma/düzenleme/iptal/silme ve QR
// doğrulama. Yönetici kabuğu (lib/screens/7_yonetici/) raporlama ve genel
// görünüm tarafında kaldı — ciro, tahsilat, bakiye, borç ve hakediş oraya ait.
//
// Ofisin göremeyeceği bilgiler bu kabukta "gizlenmiş" değil: üye uçları
// (api/ofis/) o alanları hiç göndermiyor ve modelinde alan olarak da yok.
// Ofis çalışanına o bilgiler gerekiyorsa kendisine ayrıca yönetici profili
// tanımlanır; roller karıştırılmaz.

import 'package:fitcall/screens/1_common/1_notification/notification_page.dart';
import 'package:fitcall/screens/1_common/ders_listesi/dersler_page.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/8_ofis/program/ofis_program_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uyeler_page.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_bottom_bar.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_drawer.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';

class OfisMainPage extends StatefulWidget {
  const OfisMainPage({super.key});

  @override
  State<OfisMainPage> createState() => _OfisMainPageState();
}

class _OfisMainPageState extends State<OfisMainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  String _ofisAdi = '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OfisProgramPage(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
      const DerslerPage(),
      const OfisUyelerPage(),
      // Ofise düşen kararlar (plan dışı katılım vb.) bildirim olarak geliyor;
      // bu yüzden sekme, ayrı bir rota değil.
      const NotificationPage(gomulu: true),
    ];
    NotificationService.refreshUnreadCount();
    _adYukle();
  }

  Future<void> _adYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _ofisAdi = hesapGorunenAdi(profil.user));
  }

  void _goTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: OfisDrawer(
        ofisAdi: _ofisAdi,
        onTabSelected: _goTab,
        aktifSekme: _selectedIndex,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: OfisBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _goTab,
      ),
    );
  }
}
