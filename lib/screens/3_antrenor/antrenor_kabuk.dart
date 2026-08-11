// lib/screens/3_antrenor/antrenor_kabuk.dart

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/kabuk_alt_bar.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_ogrenciler_page.dart';
import 'package:fitcall/screens/3_antrenor/antrenor_profil_page.dart';
import 'package:fitcall/screens/3_antrenor/home/antrenor_home_page.dart';
import 'package:fitcall/screens/3_antrenor/takvim/antrenor_takvim_page.dart';
import 'package:flutter/material.dart';

/// Antrenörün kalıcı sekme kabuğu — üye kabuğuyla aynı yapı (bkz. `UyeKabuk`).
///
/// Bara sığmayan sayfalar (Eksik Yoklamalar, Çalışma Saatleri, Hakediş)
/// sol menüde; ana sayfa kartlarından da açılıyorlar.
class AntrenorKabuk extends StatefulWidget {
  final int baslangicSekmesi;

  const AntrenorKabuk({super.key, this.baslangicSekmesi = 0});

  @override
  State<AntrenorKabuk> createState() => _AntrenorKabukState();
}

class _AntrenorKabukState extends State<AntrenorKabuk> {
  late int _aktif = widget.baslangicSekmesi;
  final Set<int> _acilanlar = {};

  @override
  void initState() {
    super.initState();
    _acilanlar.add(_aktif);
  }

  Widget _sayfa(int indeks) {
    if (!_acilanlar.contains(indeks)) return const SizedBox.shrink();
    return switch (indeks) {
      0 => const AntrenorHomePage(),
      1 => const AntrenorTakvimPage(),
      2 => const AntrenorOgrencilerPage(),
      _ => const AntrenorProfilPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
              ikon: Icons.groups_outlined,
              seciliIkon: Icons.groups_rounded,
              etiket: 'Öğrenciler',
            ),
            KabukSekmesi(
              ikon: Icons.person_outline_rounded,
              seciliIkon: Icons.person_rounded,
              etiket: 'Bilgilerim',
            ),
          ],
        ),
      ),
    );
  }
}
