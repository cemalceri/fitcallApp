// lib/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_card.dart';
import 'package:intl/intl.dart';

class StatCardsGrid extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onToplamAlacakTap;

  const StatCardsGrid({
    super.key,
    required this.data,
    this.onToplamAlacakTap,
  });

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // İkonlar ana renkte; yalnız durum bildirenler (iptal, alacak) her temada
    // aynı durum rengini alır. Eskiden altı kart altı ayrı renkteydi.
    final ana = context.cs.primary;
    // Kart yüksekliği genişlikten değil içerikten: sabit en-boy oranı (1.1)
    // 360 dp'de kartları gerçek fontla 5–13 px taşırıyordu. Sabit kısım
    // (dolgu + ikon + boşluklar) + yazı ölçeğiyle büyüyen üç satır yazı.
    final olcek = MediaQuery.textScalerOf(context).scale(1);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 88 + 80 * olcek,
      ),
      children: [
        // Ciro (ders bazlı getiri)
        StatCard(
          baslik: 'Ciro',
          deger: _formatCurrency(data.ciro.toplamCiro),
          altBaslik: '${data.ciro.dersSayisi} ders',
          ikon: Icons.trending_up,
          ikonRenk: ana,
          degisimYuzdesi: data.ciro.degisimYuzdesi,
        ),

        // Tahsilat (ödeme bazlı)
        StatCard(
          baslik: 'Tahsilat',
          deger: _formatCurrency(data.tahsilat.toplamTahsilat),
          altBaslik: '${data.tahsilat.islemSayisi} işlem',
          ikon: Icons.attach_money,
          ikonRenk: ana,
          degisimYuzdesi: data.tahsilat.degisimYuzdesi,
        ),

        // Günlük Ders
        StatCardDouble(
          baslik: 'Ders (Yapılan/Planlanan)',
          deger1: data.ders.tamamlananDers.toString(),
          deger2: data.ders.toplamDers.toString(),
          altBaslik: '%${data.ders.dolulukYuzdesi.toStringAsFixed(0)} doluluk',
          ikon: Icons.event_available,
          ikonRenk: ana,
        ),

        // İptal Edilen
        StatCard(
          baslik: 'İptal Edilen',
          deger: data.ders.iptalEdilenDers.toString(),
          altBaslik: 'Seçilen döneme göre',
          ikon: Icons.cancel_outlined,
          ikonRenk: context.renkler.hata,
          degisimYuzdesi: data.ders.iptalDegisimYuzdesi != null
              ? -data.ders.iptalDegisimYuzdesi!
              : null,
        ),

        // Aktif Üye
        StatCard(
          baslik: 'Aktif Üye',
          deger: data.uye.aktifUyeSayisi.toString(),
          ikon: Icons.people_outline,
          ikonRenk: ana,
          degisimYuzdesi: data.uye.degisimYuzdesi,
        ),

        // Toplam Alacak (tıklanınca borçlu üyeler / tahsilat ekranı)
        GestureDetector(
          onTap: onToplamAlacakTap,
          child: StatCard(
            baslik: 'Toplam Alacak',
            deger: _formatCurrency(data.toplamAlacak.toplamBorc),
            altBaslik: '${data.toplamAlacak.borcluUyeSayisi} üye',
            ikon: Icons.account_balance_wallet_outlined,
            ikonRenk: context.renkler.uyari,
            trailing: onToplamAlacakTap != null
                ? Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
