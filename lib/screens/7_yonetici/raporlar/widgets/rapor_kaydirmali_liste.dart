// lib/screens/7_yonetici/raporlar/widgets/rapor_kaydirmali_liste.dart

import 'package:flutter/material.dart';

/// Rapor kartının içindeki satır listesi: kısa listede içerik kadar yer
/// kaplar, uzunsa [azamiYukseklik]'te durur ve kendi içinde kayar.
///
/// "Bu Ay"da ciro/tahsilat günleri, kortlar ve antrenörler sayfayı
/// uzatıp alttaki bölümleri ekranın çok altına itiyordu (kullanıcı isteği
/// 2026-10-16). Kaydırma çubuğu görünür: listenin devamı olduğu anlaşılsın.
class RaporKaydirmaliListe extends StatefulWidget {
  final List<Widget> satirlar;
  final double azamiYukseklik;

  const RaporKaydirmaliListe({
    super.key,
    required this.satirlar,
    // 280 px'te liste hâlâ uzun görünüyordu; üçte ikisi (kullanıcı isteği).
    this.azamiYukseklik = 186,
  });

  @override
  State<RaporKaydirmaliListe> createState() => _RaporKaydirmaliListeState();
}

class _RaporKaydirmaliListeState extends State<RaporKaydirmaliListe> {
  final _kaydirma = ScrollController();

  @override
  void dispose() {
    _kaydirma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.azamiYukseklik),
      child: Scrollbar(
        controller: _kaydirma,
        thumbVisibility: true,
        child: ListView(
          controller: _kaydirma,
          primary: false,
          shrinkWrap: true,
          padding: const EdgeInsets.only(right: 10),
          physics: const ClampingScrollPhysics(),
          children: widget.satirlar,
        ),
      ),
    );
  }
}
