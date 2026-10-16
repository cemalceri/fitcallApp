// lib/screens/7_yonetici/dashboard/widgets/period_filter_tabs.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';

/// Dönem seçimi (Bugün / Bu Hafta / Bu Ay). Raporlar'da başlık bandında,
/// panoda etkilediği kartlarla aynı kutuda ([yuzeyde]) durur.
class PeriodFilterTabs extends StatelessWidget {
  final DonemFiltresi seciliDonem;
  final ValueChanged<DonemFiltresi> onDonemChanged;
  final bool yuzeyde;

  const PeriodFilterTabs({
    super.key,
    required this.seciliDonem,
    required this.onDonemChanged,
    this.yuzeyde = false,
  });

  @override
  Widget build(BuildContext context) {
    return BaslikSecici<DonemFiltresi>(
      secenekler: [for (final d in DonemFiltresi.values) (d, d.label)],
      secili: seciliDonem,
      onSec: onDonemChanged,
      yuzeyde: yuzeyde,
    );
  }
}
