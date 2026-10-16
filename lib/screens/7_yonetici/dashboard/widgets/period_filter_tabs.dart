// lib/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';

/// Dashboard ve Raporlar başlığındaki dönem seçimi (Bugün / Bu Hafta / Bu
/// Ay). Renkli başlık bandının tüm genişliğine yayılır; önceden sola yığılıp
/// bandın sağını boş bırakıyordu.
class PeriodFilterTabs extends StatelessWidget {
  final DonemFiltresi seciliDonem;
  final ValueChanged<DonemFiltresi> onDonemChanged;

  const PeriodFilterTabs({
    super.key,
    required this.seciliDonem,
    required this.onDonemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BaslikSecici<DonemFiltresi>(
      secenekler: [for (final d in DonemFiltresi.values) (d, d.label)],
      secili: seciliDonem,
      onSec: onDonemChanged,
    );
  }
}
