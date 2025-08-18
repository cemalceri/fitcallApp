// lib/screens/muhasebe/widgets/para_hareket_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';

class ParaHareketTable extends StatelessWidget {
  final List<ParaHareketModel> rows;
  const ParaHareketTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    if (rows.isEmpty) {
      return const Center(child: Text('Kayıt bulunamadı'));
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final e = rows[i];
        final tutarStyle = TextStyle(
          color: e.hareketTuru == 'Odeme' ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  // Tarih
                  Text(DateFormat('dd.MM.yyyy').format(e.tarih),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Tutar
                  Text(df.format(e.tutar), style: tutarStyle),
                ],
              ),
              const SizedBox(height: 4),
              // Tür etiketi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.hareketTuru == 'Alacak' ? 'Borç' : e.hareketTuru,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12),
                ),
              ),
              if ((e.aciklama ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(e.aciklama!, style: const TextStyle(fontSize: 14)),
              ]
            ]),
          ),
        );
      },
    );
  }
}
