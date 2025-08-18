import 'package:data_table_2/data_table_2.dart';
import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MuhasebeTable extends StatelessWidget {
  final List<MuhasebeOzetModel> rows;
  final void Function(MuhasebeOzetModel) onRowTap;

  const MuhasebeTable({
    super.key,
    required this.rows,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return DataTable2(
      columnSpacing: 12,
      headingRowColor:
          WidgetStateColor.resolveWith((_) => Colors.grey.shade200),
      columns: const [
        DataColumn2(label: Text('Ay'), size: ColumnSize.S),
        DataColumn2(label: Text('Borç'), numeric: true),
        DataColumn2(label: Text('Ödeme'), numeric: true),
        DataColumn2(label: Text('Fark'), numeric: true),
      ],
      rows: rows
          .map(
            (e) => DataRow(
              onSelectChanged: (_) => onRowTap(e),
              cells: [
                DataCell(Text('${e.ay.toString().padLeft(2, '0')}/${e.yil}')),
                DataCell(Text(df.format(e.borc))),
                DataCell(Text(df.format(e.odeme))),
                DataCell(Text(df.format(e.fark))),
              ],
            ),
          )
          .toList(),
    );
  }
}
