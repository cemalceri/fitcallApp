// lib/screens/7_yonetici/dashboard/widgets/stat_cards_grid.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/screens/7_yonetici/dashboard/widgets/stat_card.dart';
import 'package:intl/intl.dart';

class StatCardsGrid extends StatelessWidget {
  final DashboardData data;

  const StatCardsGrid({super.key, required this.data});

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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        // Bugünkü Ciro
        StatCard(
          baslik: 'Ciro',
          deger: _formatCurrency(data.ciro.toplamCiro),
          altBaslik: 'Seçilen döneme göre',
          ikon: Icons.attach_money,
          ikonRenk: Colors.green,
        ),

        // Aylık Ciro
        StatCard(
          baslik: 'Aylık Ciro',
          deger: _formatCurrency(data.aylikCiro.toplamCiro),
          ikon: Icons.description_outlined,
          ikonRenk: Colors.blue,
          degisimYuzdesi: data.aylikCiro.degisimYuzdesi,
        ),

        // Günlük Ders
        StatCardDouble(
          baslik: 'Ders (Yapılan/Planlanan)',
          deger1: data.ders.tamamlananDers.toString(),
          deger2: data.ders.toplamDers.toString(),
          altBaslik: '%${data.ders.dolulukYuzdesi.toStringAsFixed(0)} doluluk',
          ikon: Icons.event_available,
          ikonRenk: Colors.blue,
        ),

        // İptal Edilen
        StatCard(
          baslik: 'İptal Edilen',
          deger: data.ders.iptalEdilenDers.toString(),
          altBaslik: 'Seçilen döneme göre',
          ikon: Icons.cancel_outlined,
          ikonRenk: Colors.red,
          degisimYuzdesi: data.ders.iptalDegisimYuzdesi != null
              ? -data.ders.iptalDegisimYuzdesi!
              : null,
        ),

        // Aktif Üye
        StatCard(
          baslik: 'Aktif Üye',
          deger: data.uye.aktifUyeSayisi.toString(),
          ikon: Icons.people_outline,
          ikonRenk: Colors.green,
          degisimYuzdesi: data.uye.degisimYuzdesi,
        ),

        // Vadesi Geçmiş
        StatCard(
          baslik: 'Vadesi Geçmiş Borçlar',
          deger: _formatCurrency(data.vadesiGecmis.toplamBorc),
          altBaslik: '${data.vadesiGecmis.borcluUyeSayisi} üye',
          ikon: Icons.warning_amber_rounded,
          ikonRenk: Colors.red,
          degisimYuzdesi: data.vadesiGecmis.degisimYuzdesi,
        ),
      ],
    );
  }
}
