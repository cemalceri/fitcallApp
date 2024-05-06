import 'package:fitcall/models/muhasebe_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OdemeBorcListesiWidget extends StatelessWidget {
  final String baslik;
  final List<OdemeBorcModel?> odemeBorcModelList;

  const OdemeBorcListesiWidget({
    super.key,
    required this.baslik,
    required this.odemeBorcModelList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            baslik,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: odemeBorcModelList.length,
            itemBuilder: (context, index) {
              final item = odemeBorcModelList[index];
              return OdemeBorcSatiriWidget(
                label: item!.ucretTuru,
                date: item.tarih,
                value: ' ${item.tutar} TL',
              );
            },
          ),
        ),
      ],
    );
  }
}

class OdemeBorcSatiriWidget extends StatelessWidget {
  final String label;
  final String value;
  final DateTime date;

  const OdemeBorcSatiriWidget({
    super.key,
    required this.label,
    required this.value,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(DateFormat('dd.MM.yyyy').format(date)),
          Text(value),
        ],
      ),
    );
  }
}

class KalanBakiyeWidget extends StatelessWidget {
  final double kalanBakiye;

  const KalanBakiyeWidget({
    super.key,
    required this.kalanBakiye,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        kalanBakiye < 0
            ? 'Fazla Ödeme: ${kalanBakiye.toStringAsFixed(2)} TL'
            : 'Kalan Borç: ${kalanBakiye.toStringAsFixed(2)} TL',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }
}
