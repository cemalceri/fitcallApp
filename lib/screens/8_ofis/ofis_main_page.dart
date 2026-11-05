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
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/8_ofis/ana_sayfa/ofis_ana_sayfa_page.dart';
import 'package:fitcall/screens/8_ofis/dersler/ofis_dersler_page.dart';
import 'package:fitcall/screens/8_ofis/program/ofis_program_page.dart';
import 'package:fitcall/screens/8_ofis/uyeler/ofis_uyeler_page.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_bottom_bar.dart';
import 'package:fitcall/screens/8_ofis/widgets/ofis_drawer.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';

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

  /// Sekmeler ilk açıldığında kurulur (üye/antrenör kabuğu gibi): açılışta
  /// hepsi kurulunca haftalık program (~350 KB) dahil 6 istek aynı anda
  /// gidiyordu.
  final Set<int> _acilanlar = {0};
  static const _sekmeSayisi = 4;

  void _menu() => _scaffoldKey.currentState?.openDrawer();

  Widget _sayfa(int indeks) {
    if (!_acilanlar.contains(indeks)) return const SizedBox.shrink();
    return switch (indeks) {
      0 => OfisAnaSayfaPage(
          key: _anaSayfa,
          onMenuTap: _menu,
          onDerslerSekmesi: () {
            // Sekme ilk kez açılıyorsa zaten bugün + tüm derslerle kurulur;
            // açıksa özetten gelindiği için bugüne döner.
            final acikti = _acilanlar.contains(2);
            _goTab(2);
            if (acikti) _dersler.currentState?.bugune();
          },
        ),
      1 => OfisProgramPage(onMenuTap: _menu),
      // Gün listesi + onay/hakediş/paket/teyit işlemleri (yönetici kabuğundaki
      // salt-okunur ortak DerslerPage'in yerine).
      2 => OfisDerslerPage(key: _dersler),
      _ => const OfisUyelerPage(),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    // İlk açılışta sayfa kendi initState'inde yükler; tazeleme yalnız
    // önceden kurulmuş sekmede.
    final acikti = _acilanlar.contains(index);
    setState(() {
      _selectedIndex = index;
      _acilanlar.add(index);
    });
    if (acikti) _aktifiTazele();
  }

  @override
  Widget build(BuildContext context) {
    // Alt sekmelerdeyken geri tuşu uygulamadan çıkmasın, Ana Sayfa'ya dönsün
    // (üye kabuğuyla aynı).
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        // Rehber açıkken geri tuşu yalnız rehberi kapatır.
        if (!didPop && !OgrenmeModu.ornek.acik) _goTab(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: OfisDrawer(
          ofisAdi: _ofisAdi,
          onTabSelected: _goTab,
          aktifSekme: _selectedIndex,
        ),
        // Menü her sekmenin başlığından açılır (KabukMenuButonu).
        body: KabukMenusu(
          menuyuAc: () => _scaffoldKey.currentState?.openDrawer(),
          aktifSekme: () => _selectedIndex,
          sekmeyeGec: _goTab,
          child: IndexedStack(
            index: _selectedIndex,
            children: List.generate(_sekmeSayisi, _sayfa),
          ),
        ),
        bottomNavigationBar: OgrenmeHedefi(
          id: Hedef.ofisAltBar,
          child: OfisBottomBar(
            selectedIndex: _selectedIndex,
            onTabSelected: _goTab,
          ),
        ),
      ),
    );
  }
}
