import 'dart:convert';

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/1_common/uye_urun_model.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// API endpoint sabiti – mevcut `getKortveAntrenorList` tanımının yapıldığı
/// dosyayla aynı dosyaya eklediğinizden emin olun.

class UyeUrunListPage extends StatefulWidget {
  const UyeUrunListPage({super.key});

  @override
  State<UyeUrunListPage> createState() => _UyeUrunListPageState();
}

class _UyeUrunListPageState extends State<UyeUrunListPage> {
  late Future<List<UyeUrunModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUrunler();
  }

  Future<List<UyeUrunModel>> _fetchUrunler() async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getUyeUrunList),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}), // filtre yok
    );

    if (res.statusCode == 200) {
      return UyeUrunModel.fromJsonResponse(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('Liste alınamadı (${res.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dfDate = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Üyelik / Paket Bilgilerim')),
      body: FutureBuilder<List<UyeUrunModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          } else if (snap.data == null || snap.data!.isEmpty) {
            return const Center(child: Text('Kayıt bulunamadı'));
          }

          final list = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = list[i];
              final hakBilgi = (u.toplamHak != null)
                  ? 'Kalan: ${u.kalanHak}/${u.toplamHak}'
                  : 'Süre: ${dfDate.format(u.baslangic)}'
                      ' - ${u.bitis != null ? dfDate.format(u.bitis!) : "-"}';

              return ListTile(
                leading: Icon(
                  Icons.card_membership,
                  color: u.aktifMi ? Colors.green : Colors.grey,
                ),
                title: Text(u.urunAdi),
                subtitle: Text(hakBilgi),
                trailing: Chip(
                  label: Text(u.aktifMi ? 'Aktif' : 'Pasif'),
                  backgroundColor:
                      u.aktifMi ? Colors.green : Colors.grey.shade400,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
