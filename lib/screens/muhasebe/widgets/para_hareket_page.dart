// lib/screens/muhasebe/para_hareket_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:fitcall/screens/muhasebe/widgets/para_hareket_table.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/common/api_urls.dart';

/* -------------------------------------------------------------------------- */
/*                       SERVICE – tek period para hareketi                   */
/* -------------------------------------------------------------------------- */
class ParaHareketService {
  static Future<List<ParaHareketModel>> fetchForPeriod(int yil, int ay) async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getParaHareketi),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'yil': yil, 'ay': ay}),
    );
    if (res.statusCode == 200) {
      return ParaHareketModel.listFromResponse(
        utf8.decode(res.bodyBytes),
      );
    }
    throw Exception('Bakiye hareketleri alınamadı');
  }
}

/* -------------------------------------------------------------------------- */
/*                              PAGE                                          */
/* -------------------------------------------------------------------------- */
class ParaHareketPage extends StatefulWidget {
  final int yil;
  final int ay;
  const ParaHareketPage({super.key, required this.yil, required this.ay});

  @override
  State<ParaHareketPage> createState() => _ParaHareketPageState();
}

class _ParaHareketPageState extends State<ParaHareketPage> {
  late Future<List<ParaHareketModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParaHareketService.fetchForPeriod(widget.yil, widget.ay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.ay.toString().padLeft(2, "0")}/${widget.yil} Bakiye Hareketleri'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<List<ParaHareketModel>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || (snap.data?.isEmpty ?? true)) {
              return Center(
                child: Text(
                  snap.hasError ? 'Veri alınamadı' : 'Kayıt bulunamadı',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            // ----  H A T A  D Ü Z E L T M E  ----
            // SingleChildScrollView + Expanded çakışması giderildi.
            return ParaHareketTable(rows: snap.data!);
          },
        ),
      ),
    );
  }
}
