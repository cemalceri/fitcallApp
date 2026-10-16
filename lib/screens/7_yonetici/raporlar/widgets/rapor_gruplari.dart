// lib/screens/7_yonetici/raporlar/widgets/rapor_gruplari.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/donem_kutusu.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/antrenor_performans_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/ciro_raporu_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/doluluk_haritasi_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/doluluk_raporu_section.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_ozet_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/tahsilat_raporu_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Raporlar sayfasının üç bölümü (kullanıcı isteği 2026-10-16). API
// içermezler; sayfa ve taşma testi aynı widget'ları çizer.

/// 1. grup: kendi seçicisiyle özet kartlar + ciro + tahsilat.
class RaporDonemGrubu extends StatelessWidget {
  final DonemFiltresi donem;
  final ValueChanged<DonemFiltresi> onDonemChanged;
  final bool yukleniyor;
  final RaporlarData data;

  const RaporDonemGrubu({
    super.key,
    required this.donem,
    required this.onDonemChanged,
    required this.yukleniyor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return DonemKutusu(
      ikon: Icons.payments_rounded,
      baslik: 'Ciro ve tahsilat',
      seciliDonem: donem,
      onDonemChanged: onDonemChanged,
      yukleniyor: yukleniyor,
      iskeletYukseklikleri: const [100, 260, 260],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aktif üye (o anki sayı, dönemden bağımsız) panoda "Şu an" altında.
          RaporOzetKartlar(
            data: data.ozetKartlar.where((k) => !k.anlikMi).toList(),
          ),
          const SizedBox(height: 16),
          CiroRaporuSection(data: data.ciroRaporu),
          const SizedBox(height: 16),
          TahsilatRaporuSection(data: data.tahsilatRaporu),
        ],
      ),
    );
  }
}

/// 2. grup: kendi seçicisiyle kort doluluğu + antrenörler. Ciro grubundan
/// bağımsız dönem seçilir (ör. ciro "Bu Ay", kortlar "Bugün").
class RaporKortAntrenorGrubu extends StatelessWidget {
  final DonemFiltresi donem;
  final ValueChanged<DonemFiltresi> onDonemChanged;
  final bool yukleniyor;
  final RaporlarData data;

  const RaporKortAntrenorGrubu({
    super.key,
    required this.donem,
    required this.onDonemChanged,
    required this.yukleniyor,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return DonemKutusu(
      ikon: Icons.sports_tennis_rounded,
      baslik: 'Kort ve antrenör',
      seciliDonem: donem,
      onDonemChanged: onDonemChanged,
      yukleniyor: yukleniyor,
      iskeletYukseklikleri: const [260, 260],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DolulukRaporuSection(data: data.dolulukRaporu),
          const SizedBox(height: 16),
          AntrenorPerformansSection(data: data.antrenorPerformans),
        ],
      ),
    );
  }
}

/// En alt: bu haftanın ısı haritası. Izgara hep haftanın günleri olduğu için
/// dönem seçicisine bağlı değil; Pzt–Paz, planlı dersler dahil.
class RaporHaftalikYogunluk extends StatelessWidget {
  final DolulukHaritasi data;

  /// Kulüp saatine göre bugün; etiketteki hafta aralığı buradan.
  final DateTime bugun;

  const RaporHaftalikYogunluk({
    super.key,
    required this.data,
    required this.bugun,
  });

  /// "12 – 18 Eki", ay dönerse "29 Eyl – 5 Eki".
  static String haftaAraligi(DateTime bugun) {
    final pzt =
        DateTime(bugun.year, bugun.month, bugun.day - bugun.weekday + 1);
    final paz = DateTime(pzt.year, pzt.month, pzt.day + 6);
    final gunAy = DateFormat('d MMM', 'tr_TR');
    final bas = pzt.month == paz.month ? '${pzt.day}' : gunAy.format(pzt);
    return '$bas – ${gunAy.format(paz)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanoBolumEtiketi(
          ikon: Icons.grid_on_rounded,
          etiket: 'Bu hafta · ${haftaAraligi(bugun)}',
        ),
        DolulukHaritasiSection(data: data),
      ],
    );
  }
}
