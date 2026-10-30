// lib/screens/2_uye/uye_kabuk.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/acilis_popup/acilis_popuplari.dart';
import 'package:fitcall/screens/1_common/widgets/erisim_kisitli.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_menusu.dart';
import 'package:fitcall/screens/2_uye/home/uye_home_page.dart';
import 'package:fitcall/screens/2_uye/home/widgets/uye_drawer.dart';
import 'package:fitcall/screens/2_uye/profil/profil_page.dart';
import 'package:fitcall/screens/2_uye/takvim/uye_takvim_page.dart';
import 'package:fitcall/screens/6_muhasebe/muhasebe_page.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';

/// Üyenin kalıcı sekme kabuğu.
///
/// Sekmeler `IndexedStack` içinde yaşar: sekme değiştirince sayfa yeniden
/// kurulmaz, kaydırma konumu ve yüklenmiş veri korunur. Ana sayfa ilk sekme —
/// eski barda ana sayfaya dönüş yolu yoktu, geri okuyla çıkılıyordu.
///
/// Ana hesap zorunluluğu: rota guard'ı (`myRouteGenerator`) yalnız
/// `Navigator` üzerinden geçen açılışlarda çalışır; sekme geçişi Navigator
/// kullanmadığı için Hareketler/Hesabım sekmelerinin kontrolü burada yapılır.
///
/// Sol menü de kabukta: her sekmenin başlığından ([KabukMenuButonu]) ve
/// kenardan kaydırarak açılır; yalnız ana sayfaya bağlı değil.
class UyeKabuk extends StatefulWidget {
  /// Açılışta seçili sekme (bildirim yönlendirmeleri için).
  final int baslangicSekmesi;

  const UyeKabuk({super.key, this.baslangicSekmesi = 0});

  @override
  State<UyeKabuk> createState() => _UyeKabukState();
}

class _UyeKabukState extends State<UyeKabuk> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _aktif = widget.baslangicSekmesi;

  // Sol menünün bilgileri.
  String _uyeAdi = '';
  int? _userId;
  EventModel? _aktifEvent;

  /// Ana hesap mı — cihazdaki profilden asenkron okunuyor, bilinene kadar
  /// null. Varsayılan `true` olduğunda alt profil ilk karelerde Hareketler /
  /// Hesabım sayfasını kurup `initState`'teki API çağrılarını atıyordu;
  /// varsayılan kapalı tarafta olmalı.
  bool? _anaHesap;

  /// Ağır sekmeler ilk açılışta kurulur; hiç girilmemiş sekme API çağırmasın
  /// diye `IndexedStack` çocukları tembel oluşturulur.
  final Set<int> _acilanlar = {};

  @override
  void initState() {
    super.initState();
    _acilanlar.add(_aktif);
    _anaHesapKontrol();
    _menuBilgileriniYukle();
    // Doğum günü / popup duyurusu — açılış başına en fazla bir tane.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AcilisPopuplari.calistir(context);
    });
  }

  Future<void> _menuBilgileriniYukle() async {
    final uye = await StorageService.uyeBilgileriniGetir();
    if (uye != null && mounted) setState(() => _uyeAdi = uye.adi);
    await _aktifEventKontrol();
  }

  /// Menüdeki "Event / Davet" satırı. Menü her açıldığında tazelenir; event
  /// sayfasından dönünce de.
  Future<void> _aktifEventKontrol() async {
    try {
      final userId = _userId ?? await StorageService.getUserId();
      if (userId == null || userId <= 0) return;
      _userId = userId;
      final result = await QrCodeApiService.getirEventAktifApi(userId: userId);
      if (mounted) setState(() => _aktifEvent = result.data);
    } catch (_) {
      // Sessizce başarısız ol; satır görünmez.
    }
  }

  Future<void> _anaHesapKontrol() async {
    bool anaHesap;
    try {
      final profil = await StorageService.uyeProfilBilgileriniGetir();
      anaHesap = profil?.anaHesap ?? false;
    } catch (_) {
      // Güvenli depo okunamazsa (Android'de BAD_DECRYPT) ya da kayıt bozuksa
      // kapalı tarafta kal: aksi halde `_anaHesap` sonsuza kadar null kalır
      // ve sekme kalıcı iskelette donardı. Rota guard'ı da böyle davranıyor.
      anaHesap = false;
    }
    if (!mounted) return;
    setState(() => _anaHesap = anaHesap);
  }

  static const _anaHesapGerektiren = {2, 3}; // Hareketler, Hesabım

  Widget _sayfa(int indeks) {
    if (!_acilanlar.contains(indeks)) return const SizedBox.shrink();
    if (_anaHesapGerektiren.contains(indeks)) {
      // Bilinene kadar sayfa KURULMAZ: alt profilin görmemesi gereken
      // ekranın API çağrıları bir kare için de olsa gitmesin.
      if (_anaHesap == null) return const IskeletListe();
      if (!_anaHesap!) return const ErisimKisitli(geriButonu: false);
    }
    return switch (indeks) {
      0 => const UyeHomePage(),
      1 => const DersListesiPage(),
      2 => const MuhasebePage(),
      _ => const ProfilePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Alt sekmelerdeyken geri tuşu uygulamadan çıkmasın, ana sayfaya dönsün.
      canPop: _aktif == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _aktif = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: UyeDrawer(
          uyeAdi: _uyeAdi,
          aktifEvent: _aktifEvent,
          userId: _userId,
          onEventReturn: _aktifEventKontrol,
        ),
        onDrawerChanged: (acik) {
          if (acik) _aktifEventKontrol();
        },
        body: KabukMenusu(
          menuyuAc: () => _scaffoldKey.currentState?.openDrawer(),
          child: IndexedStack(
            index: _aktif,
            children: List.generate(4, _sayfa),
          ),
        ),
        bottomNavigationBar: KabukAltBar(
          aktifIndeks: _aktif,
          onSekme: (i) => setState(() {
            _aktif = i;
            _acilanlar.add(i);
          }),
          onMerkez: () =>
              Navigator.pushNamed(context, routeEnums[SayfaAdi.qrKodKayit]!),
          sekmeler: const [
            KabukSekmesi(
              ikon: Icons.home_outlined,
              seciliIkon: Icons.home_rounded,
              etiket: 'Ana Sayfa',
            ),
            KabukSekmesi(
              ikon: Icons.calendar_month_outlined,
              seciliIkon: Icons.calendar_month_rounded,
              etiket: 'Takvim',
            ),
            KabukSekmesi(
              ikon: Icons.account_balance_wallet_outlined,
              seciliIkon: Icons.account_balance_wallet_rounded,
              etiket: 'Hareketler',
            ),
            KabukSekmesi(
              ikon: Icons.person_outline_rounded,
              seciliIkon: Icons.person_rounded,
              etiket: 'Hesabım',
            ),
          ],
        ),
      ),
    );
  }
}
