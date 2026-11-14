// lib/screens/7_yonetici/yonetici_main_page.dart
//
// Yönetici kabuğu: raporlama ve genel görünüm.
//
// Ders açma/düzenleme/iptal/silme ve QR doğrulama burada YOK — hepsi ofis
// kabuğunda (lib/screens/8_ofis/). Yönetici gün gün ne olduğunu Dersler
// sekmesinden, doluluğu Raporlar'daki ısı haritasından görüyor; ızgaraya
// ihtiyaç kalmadı.

import 'package:material_ui/material_ui.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/yonetici_dashboard_page.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/raporlar_page.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/7_yonetici/uyeler/uyeler_page.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/antrenorler_page.dart';
import 'package:fitcall/screens/1_common/ders_listesi/dersler_page.dart';
import 'package:fitcall/screens/1_common/acilis_popup/acilis_popuplari.dart';
import 'package:fitcall/screens/1_common/widgets/hesap_adi.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/1_common/widgets/sekme_gecmisi.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_modu.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_bottom_bar.dart';
import 'package:fitcall/screens/7_yonetici/widgets/yonetici_drawer.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/common/routes.dart';

class YoneticiMainPage extends StatefulWidget {
  const YoneticiMainPage({super.key});

  @override
  State<YoneticiMainPage> createState() => _YoneticiMainPageState();
}

class _YoneticiMainPageState extends State<YoneticiMainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  String _yoneticiAdi = '';

  /// Geri tuşu bir önceki sekmeye döner; geçmiş yoksa uygulama kapanır.
  final _gecmis = SekmeGecmisi();

  /// Üyeler sekmesine dışarıdan ön ayar (Ana Sayfa kartı, menü).
  final _uyeOnAyari = ValueNotifier<UyeOnAyarIstegi?>(null);

  /// Sekmeler ilk açıldığında kurulur (üye/antrenör kabuğu gibi). Hepsi
  /// açılışta kurulunca ~10 istek aynı anda gidiyor, pano sunucuda bu
  /// kuyruğu bekliyordu.
  final Set<int> _acilanlar = {0};
  static const _sekmeSayisi = 5;

  Widget _sayfa(int indeks) {
    if (!_acilanlar.contains(indeks)) return const SizedBox.shrink();
    return switch (indeks) {
      0 => YoneticiDashboardPage(
          onTabChange: _goTab,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onBorcluUyeler: _borcluUyeler,
          onGelmeyenUyeler: _gelmeyenUyeler,
          onEkip: _ekip,
          onDekontlar: _dekontlar,
        ),
      1 => const RaporlarPage(),
      2 => UyelerPage(onAyarIstegi: _uyeOnAyari),
      3 => const AntrenorlerPage(),
      _ => const DerslerPage(),
    };
  }

  @override
  void initState() {
    super.initState();
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

  void _goTab(int index, {bool geri = false}) {
    if (!geri) _gecmis.kaydet(_selectedIndex, index);
    setState(() {
      _selectedIndex = index;
      _acilanlar.add(index);
    });
  }

  /// Ayrı Borçlu Üyeler sayfası yerine: Üyeler sekmesi, "borçlu + en borçlu
  /// önce" ön ayarı. Tek liste, tek filtre sistemi.
  void _borcluUyeler() {
    _uyeOnAyari.value = UyeOnAyarIstegi(UyeOnAyari.borclu);
    _goTab(2);
  }

  /// Ana Sayfa "Dikkat isteyenler": aktif olup [dersOnce]'den beri dersi
  /// olmayan üyeler (sunucunun saydığı kümeyle aynı süzgeç).
  void _gelmeyenUyeler(DateTime dersOnce) {
    _uyeOnAyari.value = UyeOnAyarIstegi.filtre(
      UyeFiltreleri(durum: UyeDurumFiltresi.aktif, dersOnce: dersOnce),
    );
    _goTab(2);
  }

  /// Ana Sayfa "Dikkat isteyenler": Ekip sayfası.
  void _ekip() {
    Navigator.pushNamed(context, routeEnums[SayfaAdi.yoneticiEkip]!);
  }

  /// Ana Sayfa "Dikkat isteyenler": bekleyen dekontlar (yalnız görüntüleme).
  void _dekontlar() {
    Navigator.pushNamed(context, routeEnums[SayfaAdi.yoneticiDekontlar]!);
  }

  @override
  Widget build(BuildContext context) {
    // Ana sayfadaki bir kart başka sekmeyi açtıysa geri tuşu oraya döner;
    // önceki sekme kalmayınca uygulama kapanır.
    return PopScope(
      canPop: _gecmis.kapatabilir(_selectedIndex),
      onPopInvokedWithResult: (didPop, _) {
        // Rehber açıkken geri tuşu yalnız rehberi kapatır.
        if (!didPop && !OgrenmeModu.ornek.acik) {
          _goTab(_gecmis.geriHedefi(), geri: true);
        }
      },
      child: Scaffold(
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
        aktifSekme: () => _selectedIndex,
        sekmeyeGec: _goTab,
        child: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_sekmeSayisi, _sayfa),
        ),
      ),
      bottomNavigationBar: YoneticiBottomBar(
        selectedIndex: _selectedIndex,
        onTabSelected: _goTab,
      ),
      ),
    );
  }
}
