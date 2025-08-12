import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/services/urun/urun_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

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
    try {
      final res = await UyeUrunApiService.fetchList();
      return res.data ?? [];
    } on ApiException catch (e) {
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
      if (mounted) {
        ShowMessage.error(context, 'Ürün listesi alınamadı: $e');
      }
      return [];
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
