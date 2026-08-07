// lib/screens/3_antrenor/hakedis/antrenor_hakedis_page.dart
//
// Antrenörün kendi hakediş saatleri.
//
// Ekranın kendisi yöneticidekiyle aynı (screens/1_common/hakedis/); burada
// yalnız veri kaynağı sabitleniyor. AntrenorHakedisKaynagi antrenör id'si
// taşımaz — backend kimliği token'dan çözer, dolayısıyla bu sayfadan
// başkasının hakedişine ulaşmak mümkün değil.
//
// Yöneticideki antrenör seçim adımı burada yok; drawer'dan doğrudan ay
// panosuna girilir.

import 'package:fitcall/screens/1_common/hakedis/hakedis_ay_panosu_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:flutter/material.dart';

class AntrenorHakedisPage extends StatelessWidget {
  const AntrenorHakedisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HakedisAyPanosuPage(
      kaynak: AntrenorHakedisKaynagi(),
      baslik: 'Hakediş Saatlerim',
      altBaslik: 'Son 12 ay',
    );
  }
}
