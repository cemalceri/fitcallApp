// lib/screens/1_common/hakedis/widgets/hakedis_stil.dart
//
// Hakediş ekranlarının ortak görsel dili: durum renkleri, ikonları ve
// yükleme/hata/boş gövdeleri. Üç sayfa da aynı sözlüğü kullansın diye tek
// yerde toplandı.

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:flutter/material.dart';

/// Durum kodunun rengi — yeşil hakediş, turuncu bekleyen, gri hakediş dışı.
Color hakedisRengi(BuildContext context, String durum) {
  final renk = Theme.of(context).colorScheme;
  switch (durum) {
    case HakedisDurumu.hakedis:
      return const Color(0xFF10B981);
    case HakedisDurumu.bekliyor:
      return const Color(0xFFF59E0B);
    default:
      return renk.onSurfaceVariant;
  }
}

IconData hakedisIkonu(String durum) {
  switch (durum) {
    case HakedisDurumu.hakedis:
      return Icons.check_circle_rounded;
    case HakedisDurumu.bekliyor:
      return Icons.schedule_rounded;
    default:
      return Icons.remove_circle_outline_rounded;
  }
}

IconData hakedisRolIkonu(String rol) => rol == HakedisRolu.yardimci
    ? Icons.group_rounded
    : Icons.person_rounded;

/// Katılım durumunun rengi — katıldı yeşil, katılmadı kırmızı, yoklama yoksa gri.
Color katilimRengi(BuildContext context, HakedisKatilimci katilimci) {
  final renk = Theme.of(context).colorScheme;
  if (katilimci.planDisiMi) return const Color(0xFF3B82F6);
  if (katilimci.katildi) return const Color(0xFF10B981);
  if (katilimci.katilmadi) return renk.error;
  return renk.onSurfaceVariant;
}

IconData katilimIkonu(HakedisKatilimci katilimci) {
  if (katilimci.planDisiMi) return Icons.person_add_alt_1_rounded;
  if (katilimci.katildi) return Icons.check_rounded;
  if (katilimci.katilmadi) return Icons.close_rounded;
  return Icons.remove_rounded;
}

/// Yükleme / hata / boş durumların ortak gövdesi.
///
/// Sayfalar bunu `Expanded` içinde kullanır; hata halinde [onTekrarDene] ile
/// yeniden yükleme sunar.
class HakedisDurumGovdesi extends StatelessWidget {
  final bool yukleniyor;
  final String? hata;
  final bool bosMu;
  final String bosMesaj;
  final IconData bosIkon;
  final VoidCallback? onTekrarDene;
  final WidgetBuilder icerik;

  const HakedisDurumGovdesi({
    super.key,
    required this.yukleniyor,
    required this.hata,
    required this.bosMu,
    required this.icerik,
    this.bosMesaj = 'Kayıt bulunamadı',
    this.bosIkon = Icons.inbox_rounded,
    this.onTekrarDene,
  });

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    if (yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hata != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 44, color: renk.error),
              const SizedBox(height: 14),
              Text(hata!, textAlign: TextAlign.center),
              if (onTekrarDene != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onTekrarDene,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (bosMu) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(bosIkon, size: 40, color: renk.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                bosMesaj,
                textAlign: TextAlign.center,
                style: TextStyle(color: renk.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return icerik(context);
  }
}
