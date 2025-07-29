import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/screens/muhasebe/widgets/muhasebe_table.dart';
import 'package:fitcall/screens/muhasebe/widgets/para_hareket_page.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MuhasebePage extends StatefulWidget {
  const MuhasebePage({super.key});

  @override
  State<MuhasebePage> createState() => _MuhasebePageState();
}

class _MuhasebePageState extends State<MuhasebePage> {
  late Future<List<MuhasebeOzetModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = MuhasebeService.fetch();
  }

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Scaffold(
      appBar: AppBar(title: const Text('Borç / Alacak Özeti')),
      body: FutureBuilder<List<MuhasebeOzetModel>>(
        future: _future,
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final toplamFark =
              snapshot.data!.fold<double>(0, (p, e) => p + e.fark);

          return Column(
            children: [
              Expanded(
                child: MuhasebeTable(
                    rows: snapshot.data!,
                    onRowTap: (row) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParaHareketPage(
                              yil: row.yil,
                              ay: row.ay,
                            ),
                          ),
                        )),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                alignment: Alignment.centerRight,
                child: Text(
                  toplamFark > 0
                      ? 'Fazla Ödeme: ${df.format(toplamFark)}'
                      : 'Kalan Borç: ${df.format(toplamFark.abs())}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
