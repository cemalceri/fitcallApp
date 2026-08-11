// lib/screens/2_uye/uye_kabuk.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/erisim_kisitli.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/2_uye/home/uye_home_page.dart';
import 'package:fitcall/screens/2_uye/profil/profil_page.dart';
import 'package:fitcall/screens/2_uye/takvim/uye_takvim_page.dart';
import 'package:fitcall/screens/6_muhasebe/muhasebe_page.dart';
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
class UyeKabuk extends StatefulWidget {
  /// Açılışta seçili sekme (bildirim yönlendirmeleri için).
  final int baslangicSekmesi;

  const UyeKabuk({super.key, this.baslangicSekmesi = 0});

  @override
  State<UyeKabuk> createState() => _UyeKabukState();
}

class _UyeKabukState extends State<UyeKabuk> {
  late int _aktif = widget.baslangicSekmesi;
  bool _anaHesap = true;

  /// Ağır sekmeler ilk açılışta kurulur; hiç girilmemiş sekme API çağırmasın
  /// diye `IndexedStack` çocukları tembel oluşturulur.
  final Set<int> _acilanlar = {};

  @override
  void initState() {
    super.initState();
    _acilanlar.add(_aktif);
    _anaHesapKontrol();
  }

  Future<void> _anaHesapKontrol() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (!mounted) return;
    setState(() => _anaHesap = profil?.anaHesap ?? false);
  }

  static const _anaHesapGerektiren = {2, 3}; // Hareketler, Hesabım

  Widget _sayfa(int indeks) {
    if (!_acilanlar.contains(indeks)) return const SizedBox.shrink();
    if (_anaHesapGerektiren.contains(indeks) && !_anaHesap) {
      return const ErisimKisitli(geriButonu: false);
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
        body: IndexedStack(
          index: _aktif,
          children: List.generate(4, _sayfa),
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
