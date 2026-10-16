// lib/screens/8_ofis/ofis_main_page.dart
//
// Ofis (ön büro) kabuğu.
//
// Mobildeki AKSİYONLARIN tamamı burada: ders açma/düzenleme/iptal/silme, QR
// doğrulama ve (2026-10-12'den beri) web Ders Yönetimi'nin işleri — ders
// onayı, hakediş işareti, paket düşümü, katılım teyidi, plan dışı kararlar.
// Yönetici kabuğu (lib/screens/7_yonetici/) raporlama ve genel görünüm
// tarafında kaldı — ciro, tahsilat, bakiye ve hakediş tutarları oraya ait.
//
// Sekmeler: Ana Sayfa (bekleyen işler) · Program · Dersler · Üyeler.
// Bildirimler başlıktaki zilden ve menüden açılır.
//
// Ofisin göremeyeceği bilgiler bu kabukta "gizlenmiş" değil: üye uçları
// (api/ofis/) o alanları hiç göndermiyor ve modelinde alan olarak da yok.
// Ofis çalışanına o bilgiler gerekiyorsa kendisine ayrıca yönetici profili
// tanımlanır; roller karıştırılmaz.

import 'package:fitcall/screens/1_common/acilis_popup/acilis_popuplari.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/ofis_ana_sayfa_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/ofis_dersler_page.dart';
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

class _OfisMainPageState extends State<OfisMainPage>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sekmeler IndexedStack'te canlı kalıyor; Ana Sayfa sayıları ve Dersler'in
  // günü sekmeye dönünce / uygulama öne gelince tazelenir.
  final _anaSayfa = GlobalKey<OfisAnaSayfaPageState>();
  final _dersler = GlobalKey<OfisDerslerPageState>();

  int _selectedIndex = 0;
  String _ofisAdi = '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    void menu() => _scaffoldKey.currentState?.openDrawer();
    _pages = [
      OfisAnaSayfaPage(
        key: _anaSayfa,
        onMenuTap: menu,
        onDerslerSekmesi: () {
          _goTab(2);
          // Özetten gelindi: bugünün tüm dersleri.
          _dersler.currentState?.bugune();
        },
      ),
      OfisProgramPage(onMenuTap: menu),
      // Gün listesi + onay/hakediş/paket/teyit işlemleri (yönetici kabuğundaki
      // salt-okunur ortak DerslerPage'in yerine).
      OfisDerslerPage(key: _dersler),
      const OfisUyelerPage(),
    ];
    NotificationService.refreshUnreadCount();
    _adYukle();
    // Sürüm notu popup'ı ("Neler yeni?"). Duyuru popup'ı burada ÇIKMAZ: sıranın
    // rol filtresi onu üye ve antrenöre bırakıyor (bilinçli karar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AcilisPopuplari.calistir(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _aktifiTazele();
  }

  void _aktifiTazele() {
    switch (_selectedIndex) {
      case 0:
        _anaSayfa.currentState?.sessizYenile();
      case 2:
        _dersler.currentState?.sessizYenile();
    }
  }

  Future<void> _adYukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null || !mounted) return;
    setState(() => _ofisAdi = hesapGorunenAdi(profil.user));
  }

  void _goTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _aktifiTazele();
  }

  @override
  Widget build(BuildContext context) {
    // Alt sekmelerdeyken geri tuşu uygulamadan çıkmasın, Ana Sayfa'ya dönsün
    // (üye kabuğuyla aynı).
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTab(0);
      },
      child: Scaffold(
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
      ),
    );
  }
}
