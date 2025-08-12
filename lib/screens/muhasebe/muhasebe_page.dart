import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/screens/muhasebe/widgets/muhasebe_table.dart';
import 'package:fitcall/screens/muhasebe/widgets/para_hareket_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MuhasebePage extends StatefulWidget {
  const MuhasebePage({super.key});

  @override
  State<MuhasebePage> createState() => _MuhasebePageState();
}

class _MuhasebePageState extends State<MuhasebePage> {
  bool _isLoading = true;
  List<MuhasebeOzetModel> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await MuhasebeService.fetch();
      _rows = res.data ?? [];
    } on ApiException catch (e) {
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        ShowMessage.error(context, 'Beklenmeyen bir hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Borç / Alacak Özeti')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final toplamFark = _rows.fold<double>(0, (p, e) => p + e.fark);

    return Scaffold(
      appBar: AppBar(title: const Text('Borç / Alacak Özeti')),
      body: Column(
        children: [
          Expanded(
            child: MuhasebeTable(
              rows: _rows,
              onRowTap: (row) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParaHareketPage(
                    yil: row.yil,
                    ay: row.ay,
                  ),
                ),
              ),
            ),
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
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
