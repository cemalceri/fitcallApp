import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/takvim_constants.dart';
import 'package:flutter/material.dart';

/* -------------------------------------------------------------------------- */
/*                          PAYLAŞILAN RENK SABİTLERİ                          */
/* -------------------------------------------------------------------------- */
class BildirimRenkleri {
  static const yaziAna = Color(0xFF1A1A1A);
  static const yaziIkincil = Color(0xFF6B7280);
  static const basariYesil = Color(0xFF10B981);
  static const hataKirmizi = Color(0xFFEF4444);
  static const arkaplanGri = Color(0xFFF9FAFB);
  static const anaMavi = Color(0xFF0095F6);
  static const uyariTuruncu = Color(0xFFFF9500);
  static const ayiriciCizgi = Color(0xFFDBDBDB);
}

/* -------------------------------------------------------------------------- */
/*                       İKON / RENK YARDIMCI FONKSİYONLARI                    */
/* -------------------------------------------------------------------------- */
class BildirimGorselYardimci {
  /// Bildirim tipine göre ikon döndürür.
  static IconData ikonGetir(String bildirimTipi) {
    switch (bildirimTipi) {
      case NotificationType.dersTeyidi:
        return Icons.event_available_rounded;
      case NotificationType.dersIptal:
        return Icons.event_busy_rounded;
      case NotificationType.gecikenOdeme:
        return Icons.payment_rounded;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
        return Icons.hourglass_bottom_rounded;
      case NotificationType.paketBitti:
        return Icons.inventory_2_outlined;
      case NotificationType.paketSatinAlma:
        return Icons.shopping_bag_rounded;
      case NotificationType.paketHakGuncelleme:
        return Icons.sync_rounded;
      case NotificationType.telafiKullanildi:
        return Icons.replay_rounded;
      case NotificationType.telafiIade:
        return Icons.undo_rounded;
      case NotificationType.uyelikTanimlandi:
        return Icons.card_membership_rounded;
      case NotificationType.antrenorDegisikligi:
      case NotificationType.antrenorDevirTeklifi:
      case NotificationType.antrenorDevirKabul:
      case NotificationType.antrenorDevirRed:
      case NotificationType.antrenorDevirGeriCekildi:
        return Icons.swap_horiz_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Bildirim tipine göre ana renk döndürür.
  static Color renkGetir(String bildirimTipi) {
    switch (bildirimTipi) {
      case NotificationType.dersTeyidi:
      case NotificationType.telafiIade:
      case NotificationType.paketSatinAlma:
      case NotificationType.antrenorDevirKabul:
        return BildirimRenkleri.basariYesil;
      case NotificationType.dersIptal:
      case NotificationType.gecikenOdeme:
      case NotificationType.antrenorDevirRed:
        return BildirimRenkleri.hataKirmizi;
      case NotificationType.paketBitiyor:
      case NotificationType.paketSuresiDoluyor:
      case NotificationType.antrenorDegisikligi:
      case NotificationType.antrenorDevirTeklifi:
      case NotificationType.antrenorDevirGeriCekildi:
        return BildirimRenkleri.uyariTuruncu;
      case NotificationType.paketHakGuncelleme:
      case NotificationType.uyelikTanimlandi:
        return BildirimRenkleri.anaMavi;
      default:
        return BildirimRenkleri.yaziIkincil;
    }
  }

  /// Bildirim tipine göre arka plan rengi.
  static Color arkaplanRengiGetir(String bildirimTipi) {
    return renkGetir(bildirimTipi).withValues(alpha: 0.15);
  }
}

/* -------------------------------------------------------------------------- */
/*                                  TOPBAR                                     */
/* -------------------------------------------------------------------------- */
class BildirimUstBarWidget extends StatelessWidget {
  final VoidCallback onClose;
  const BildirimUstBarWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: BildirimRenkleri.arkaplanGri,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: BildirimRenkleri.yaziAna),
            onPressed: onClose,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              STATUS VIEW                                    */
/* -------------------------------------------------------------------------- */
class BildirimDurumGorunumWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool showChangeHint;
  final VoidCallback onClose;

  const BildirimDurumGorunumWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.showChangeHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: BildirimRenkleri.yaziAna),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 15,
                  color: BildirimRenkleri.yaziIkincil,
                  height: 1.4),
              textAlign: TextAlign.center),
          if (showChangeHint) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: TakvimColors.primary),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Değiştirmek için kulüp ile iletişime geçin',
                      style: TextStyle(
                          fontSize: 13, color: BildirimRenkleri.yaziIkincil),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: BildirimRenkleri.yaziIkincil.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kapat',
                  style: TextStyle(
                      color: BildirimRenkleri.yaziAna,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              COMPACT HEADER                                 */
/* -------------------------------------------------------------------------- */
class BildirimKompaktBaslikWidget extends StatelessWidget {
  final Map<String, dynamic> displayData;
  const BildirimKompaktBaslikWidget({super.key, required this.displayData});

  @override
  Widget build(BuildContext context) {
    final tarih = displayData['tarih'] ?? '';
    final saat = displayData['saat'] ?? '';
    final kort = displayData['kort_adi'] ?? displayData['kort'] ?? '';
    final antrenor =
        displayData['antrenor_adi'] ?? displayData['antrenor'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TakvimColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_tennis_rounded,
                  color: TakvimColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tarih.toString(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BildirimRenkleri.yaziAna)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (saat.toString().isNotEmpty)
              BildirimBilgiCipiWidget(
                  icon: Icons.access_time_rounded, text: saat.toString()),
            if (kort.toString().isNotEmpty)
              BildirimBilgiCipiWidget(
                  icon: Icons.sports_tennis_rounded, text: kort.toString()),
            if (antrenor.toString().isNotEmpty)
              BildirimBilgiCipiWidget(
                  icon: Icons.person_rounded, text: antrenor.toString()),
          ],
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                INFO CHIP                                    */
/* -------------------------------------------------------------------------- */
class BildirimBilgiCipiWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  const BildirimBilgiCipiWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TakvimColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            MESSAGE BOX                                      */
/* -------------------------------------------------------------------------- */
class BildirimMesajKutusuWidget extends StatelessWidget {
  final String title;
  final String body;
  const BildirimMesajKutusuWidget({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BildirimRenkleri.yaziAna)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  color: BildirimRenkleri.yaziIkincil,
                  height: 1.5)),
        ],
      ),
    );
  }
}
