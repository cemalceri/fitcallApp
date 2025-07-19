import 'package:data_table_2/data_table_2.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParaHareketTable extends StatelessWidget {
  final List<ParaHareketModel> rows;

  const ParaHareketTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return DataTable2(
      columnSpacing: 8,
      columns: const [
        DataColumn2(label: Text('Tarih'), size: ColumnSize.S),
        DataColumn2(label: Text('Tür')),
        DataColumn2(label: Text('Tutar'), numeric: true),
        DataColumn2(label: Text('Açıklama')),
      ],
      rows: rows
          .map(
            (e) => DataRow(cells: [
              DataCell(Text(DateFormat('dd.MM.yyyy').format(e.tarih))),
              DataCell(Text(e.hareketTuru)),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    df.format(e.tutar),
                    style: TextStyle(
                        color: e.hareketTuru == 'Odeme'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              DataCell(Text(e.aciklama ?? '')),
            ]),
          )
          .toList(),
    );
  }
}
